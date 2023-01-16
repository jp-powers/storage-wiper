#!/bin/bash

# Script should be run as sudo as we're writing to /root
if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit
fi

# ask for drive
echo "What disk do you want to wipe?"
echo "enter just the drive, so if you want to wipe /dev/sde, enter sde"
read -p "My disk: " DISK

# concept for checking if mounted taken from Arch Wiki but I changed the search method a bit to be a bit easier to understand.
# lists all block devices by Name and Mountpoint, searches for the disk we're wiping, then searches if it's mounted.
NOT_safe="$(lsblk -o "NAME,MOUNTPOINT" | grep -e $DISK[0-9] | grep -e / )";

if [ -z "$NOT_safe" ]; then
    echo "How many wipes do you want to do against the disk?"
    read -p "Wipe count: " WIPECOUNT

    echo "Do you want to zero out the disk at the end?"
    echo "Enter 1 to zero out the disk"
    echo "Enter 0 to not zero out the disk"
    read -p "1 For Yes or 0 for No: " ZEROOUT
    case $ZEROOUT in
        1) echo "Disk will be zeroed out" ;;
        0) echo "Disk will not be zeroed out" ;;
        *) echo "You didn't enter a proper selection, try again please." ;;
    esac

    echo "What will our blocksize be? Suggestion is 1M"
    read -p "Blocksize: " BLOCKSIZE

    WIPEITTER=0 # start an itterator at 0 to run thru

    while [ $WIPEITTER -lt $WIPECOUNT ]; do
        ((WIPEITTER++ ))
        echo "/dev/$DISK wipe number $WIPEITTER"
        # create a 128 byte encryption key seeded from /dev/urandom
        PASS=$(tr -cd '[:alnum:]' < /dev/urandom | head -c128) 
        # AES-256 in CTR mode is used to encrypt /dev/zero's output with the urandom key.
        # Utilizing the cipher instead of a pseudorandom source results in very high write speeds and the result is a device filled with AES ciphertext.
        openssl enc -aes-256-ctr -pbkdf2 -pass pass:"$PASS" -nosalt </dev/zero | dd obs=$BLOCKSIZE ibs=4K of=/dev/$DISK oflag=direct status=progress
    done

    if [ $ZEROOUT = "1" ]; then
        echo "/dev/$DISK zeroing out"
        dd if=/dev/zero of=/dev/$DISK bs=$BLOCKSIZE status=progress
    else
        echo "/dev/$DISK is NOT being zeroed out"
    fi
else
    echo 'Not allowed to destroy if any of the partitions are mounted: '"$NOT_safe"
fi