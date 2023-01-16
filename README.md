# HDD and SSD secure wipe
This pair of scripts is written to assist with securely wiping hard drives and SSDs (SATA, **NVMe is not currently supported**).

The HDD script is utilizing the methodology from [The Arch Linux wiki](https://wiki.archlinux.org/title/Securely_wipe_disk/Tips_and_tricks#dd_-_advanced_example).
The SSD script is utilizing secure erasure as guided by [code.mendhak.com](https://code.mendhak.com/securely-wipe-ssd/).

Both scripts ask for the disk to wipe and perform a check to ensure the disk is safe to wipe (aka: not currently mounted)

## hdd-wipe.sh versus ssd-wipe.sh
Technically, you can use hdd-wipe.sh against SSDs. However, it's going to cause unnecessary thrashing against the disk which will consume the limited write cycles of the NAND flash cells.

The two scripts could be combined to ask you if the disk is an HDD or an SSD and perform the separate tasks appropriately, but I wanted to provide them separately in case you only need/want one and to make it easier to read/understand.

## hdd-wipe.sh
The script will ask for the device name (`sda`, `sdb`, etc.), how many wipes you wish to perform, if you would like to zero out the disk at the end, and what the block size used should be. Once entered the script will begin wiping the disk and optionally zeroing it out.

### device name
The script is hard coded to work against `/dev` so all you need to do is enter the device name itself.

### wipe count
The script will loop through writing randomized data the number of times you enter here. Generally speaking 4 is a good count, but a lower number will be faster, and a higher number will be more secure.

### zeroing out
If select, the last thing the script will do is write zeroes to the disk until it runs out of space. This is not required but generally suggested.

### block size
Depending on the disk to be wiped, and potentially the computer performing the wipe, different block sizes can result in higher or lower time to complete speeds of the wipes. You can refer [here](https://superuser.com/questions/234199/good-block-size-for-disk-cloning-with-diskdump-dd) for some suggestions on how to find the best block size.

However, generally, 1M (aka: 1MB) is generally a good balance and will result in acceptable time to complete times.

### How does it actually work?
The script will generate a 128 byte encryption key from /dev/urandom, and then runs that key thru OpenSSL to generate AES ciphertext, which is then streamed to the disk via `dd`. When you are running more than 1 wipe, each wipe will use a freshly generated encryption key which will generate fresh ciphertext for each wipe cycle. Zeroing out the disk is not necessary but provides a further wipe cycle that is performed much faster and obfuscates the ciphertext that was there.

## ssd-wipe.sh
The script will ask for the device name (`sda`, `sdb`, etc.), ask if you'd like to zero out the disk, ask you to confirm if the drive is frozen or not, set a temporary password to use during the encryption process, and whether you'd like to perform a secure erase or an enhanced secure erase. Once selected the script will begin securely erasing the disk and when complete will also zero out the disk if selected. While not strictly necessary it is a slightly more paranoid way of ensuring the disk truly wiped.

### device name
The script is hard coded to work against `/dev` so all you need to do is enter the device name itself.

### zeroing out
If select, the last thing the script will do is write zeroes to the disk until it runs out of space. This is not required but generally suggested.

### frozen state
Sometimes a disk will show as frozen, which will block the secure erase process from continuing. However, putting the computer to sleep and waking it back up will almost always unfreeze the disk.

### temporary password
The SSD Secure Erase spec requires a password be set as part of it's proceedings. Any password will do, and it will be erased as part of the process. It's not a bad idea to select a decently secure password but there's no need to go above and beyond with it.

**FOR YOUR SECURITY, DO NO USE A PRE-EXISTING PASSWORD.** The script will write out the password you're using in case there is some failure you'll have a reference.

### secure erase or enhanced secure erase
Most SSDs support secure erase, and many newer SSDs will also support enhanced secure erase. Generally speaking, if you disk support enhanced secure erase you want to use it.

Secure erase rotates the disk's internal encryption key, which makes any data on the disk meaningless.
Enhanced secure erase does the above while also writing a pattern to the disk set by the manufacturer.

### How does it actually work?
The script is only utilizing the SSD secure erase function, but attempting to guide you through it to make it easier to perform. It finishes by zeroing out the disk. While not strictly necessary, different manufacturers support the secure erase function of SSDs in various ways, and it's been shown that some are not as good as others. Zeroing the disk is just an added safety precaution and thus I suggest it, however, again, it's not strictly required.