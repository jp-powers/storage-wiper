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
    echo "Do you want to zero out when secure erase completes? This is not necessary but adds a level of paranoia based security and generally is preformed quickly on SSDs."
    echo "Enter 1 to zero out the disk"
    echo "Enter 0 to not zero out the disk"
    read -p "1 For Yes or 0 for No: " ZEROOUT
    case $ZEROOUT in
        1) echo "Disk will be zeroed out" ;;
        0) echo "Disk will not be zeroed out" ;;
        *) echo "You didn't enter a proper selection, try again please." ;;
    esac

    # write out disk data
    sudo hdparm -I /dev/$DISK | tail -10

    # ask user to confirm drive not frozen
    echo "Above, does the drive list as not frozen or frozen?"
    echo "1 = not   frozen"
    echo "2 = frozen"
    read -p "My Frozen Status: " FROZENSTATUS
    case $FROZENSTATUS in
        1) echo "Good, we can proceed" ;;
        2) echo "Put the PC to sleep and try again" ;;
        *) echo "You didn't enter a proper selection, try again please." ;;
    esac

    if [ "$FROZENSTATUS" = "2" ]; then
        echo "after your PC wakes back up run the script again, confirm it's now showing not frozen, and select appropriately."
        exit
    fi

    if [ "$FROZENSTATUS" = "1" ]; then
        echo "We need to set a password for secure erase. This is temporary and used for the encryption process."
        echo "DO NOT USE AN EXISTING PASSWORD. Just enter some random text here."
        read -p "My password: " USERPASS
        echo "Using $USERPASS to encrypt the drive." # printing out in case user rubs their hand along the keyboard randomly and there's some sort of failure it's available for reference
        sudo hdparm --user-master u --security-set-pass $USERPASS /dev/$DISK
        sudo hdparm -I /dev/$DISK | tail -11
        echo "Above, you should see under Master password revision code that it is supported and enabled, and that security level high is listed as well above an estimated time. Do you see this?"
        echo "1 = yes"
        echo "2 = no"
        read -p "Security Status: " SECURESTATE
        case $SECURESTATE in
            1) echo "Good, we can proceed" ;;
            2) echo "Something has gone wrong." ;;
            *) echo "You didn't enter a proper selection, try again please." ;;
        esac
        if [ "$SECURESTATE" = "2" ]; then
            echo "Refer to https://code.mendhak.com/securely-wipe-ssd/ and perform sequence manually."
            break
        fi
        if [ "$SECURESTATE" = "1" ]; then
            echo "Would you like to do a secure erase or enhanced secure erase?"
            echo "Note, if you don't see supported: enhanced erase in the Security: sections above, you can't do it."
            echo "regular will delete the encryption key, leaving effectively random data on the disk."
            echo "enhanced will do that and also write manufacturer specified random data to the disk."
            echo "1 = Regular"
            echo "2 = Enhanced"
            read -p "Secure Erase Type: " SECERASESEL
            case $SECERASESEL in
                1) echo "We will proceed with a regular secure erase" ;;
                2) echo "We will proceed with an enhanced secure erase" ;;
                *) echo "You didn't enter a proper selection, try again please." ;;
            esac
            if [ "$SECERASESEL" = "1" ]; then
                sudo hdparm --user-master u --security-erase $USERPASS /dev/$DISK
                sudo hdparm -I /dev/$DISK | tail -10
                echo "Above the drive should now show that Master password is supported but not enabled."
                echo "If it does, your drive has been securely erased."
                echo "If it does not, CTRL+C to cancel out of the script. Refer to https://code.mendhak.com/securely-wipe-ssd/ and perform sequence manually."
                echo "sleeping 10 seconds to allow this if needed."
                sleep 10
                if [ $ZEROOUT = "1" ]; then
                    echo "Now we will zero the drive."
                    sudo dd if=/dev/zero of=/dev/$DISK bs=1M status=progress
                    echo "If dd errored out that there was no space left on the drive, you are complete. Your SSD has been secure erased and zero'd out."
                else
                    echo "/dev/$DISK is NOT being zeroed out"
                fi
            fi
            if [ "$SECERASESEL" = "2" ]; then
                sudo hdparm --user-master u --security-erase-enhanced $USERPASS /dev/$DISK
                sudo hdparm -I /dev/$DISK | tail -10
                echo "Above the drive should now show that Master password is supported but not enabled."
                echo "If it does, your drive has been securely erased."
                echo "If it does not, CTRL+C to cancel out of the script. Refer to https://code.mendhak.com/securely-wipe-ssd/ and perform sequence manually."
                echo "sleeping 10 seconds to allow this if needed."
                sleep 10
                if [ $ZEROOUT = "1" ]; then
                    echo "Now we will zero the drive."
                    sudo dd if=/dev/zero of=/dev/$DISK bs=1M status=progress
                    echo "If dd errored out that there was no space left on the drive, you are complete. Your SSD has been secure erased and zero'd out."
                else
                    echo "/dev/$DISK is NOT being zeroed out"
                fi
            fi
        fi
    fi
else
    echo 'Not allowed to destroy if any of the partitions are mounted: '"$NOT_safe"
fi