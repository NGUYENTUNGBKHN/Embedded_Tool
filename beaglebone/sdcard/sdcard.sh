#!/bin/bash
# This version using sfdisk


# version app
function ver()
{
	printf "%03d%03d%03d" $(echo "$1" | tr '.' ' ')
}

# new versions of sfdisk don't use rotating disk params
sfdisk_ver=`sfdisk --version | awk '{ print $4 }'`

if [ $(ver $sfdisk_ver) -lt $(ver 2.26.2) ]; then
    	CYLINDERS=`echo $SIZE/255/63/512 | bc`
    	echo "CYLINDERS – $CYLINDERS"
    	SFDISK_CMD="sfdisk --force -D -uS -H255 -S63 -C ${CYLINDERS}"
else
    	SFDISK_CMD="sfdisk"
fi



function deleteSdCard()
{
	if [ "$1" = "" ]
	then
		echo -n "Please enter device sd card [sda/sdb/sdc] : "
		read device
		DEV=/dev/$device
	else
		DEV=/dev/$1
	fi
	
	echo -n " Do you want delete sd card [y][n] :"
	read res
	if [ $res = "y" ] || [ $res = "Y" ];
	then
		# make sure umount 
		sd1="${DEV}1"
		sudo umount $sd1
		sd2="${DEV}2"
		sudo umount $sd2
		sudo $SFDISK_CMD $DEV --delete
	else
		echo $res
		echo "Cancel delete sd card"
	fi
	# sync
	sync
}

function partitionSdCard()
{
	# chek $1 empty
	if [ "$1" = "" ]
	then
		echo -n "Please enter device sd card [sda/sdb/sdc] : "
		read device
		DEV=/dev/$device
	else
		# set variable
    	DEV=/dev/$1
		device=$1
	fi

    # check disk
    mount | grep '^/' | grep -q $device
    #
    if [ $? -ne 1 ]; then
        echo "Looks like partitions on device dev/$device are mounted"
        echo "Not going to work on a device that is currently in use"
        echo "$(basename $0) -d or $(basename $0) -h"
        # mount | grep '^/' | grep ${1}
        exit 1
    fi

    echo -e "\nWorking on $DEV\n"
	# check size
    SIZE=`fdisk -l $DEV | grep "$DEV" | cut -d' ' -f5 | grep -o -E '[0-9]+'`

    echo DISK SIZE – $SIZE bytes
	# check size sd card more than 2G
    if [ "$SIZE" -lt 1800000000 ]; then
        echo "Require an SD card of at least 2GB"
        exit 1
    fi

	echo -e "\nOkay, here we go ...\n"

	echo -e "=== Zeroing the MBR ===\n"
	dd if=/dev/zero of=$DEV bs=1024 count=1024

	# Minimum required 2 partitions
	# Sectors are 512 bytes
	# 0     : 64KB, no partition, MBR then empty
	# 128   : 64 MB, FAT partition, bootloader
	# 131200: 2GB+, linux partition, root filesystem

	echo -e "\n=== Creating 2 partitions ===\n"
	{
		echo 128,131072,0x0C,*
		echo 131200,+,0x83,-
	} | sudo $SFDISK_CMD $DEV

	sleep 1

	device="${DEV}1"
	sudo mkfs.vfat -v -c -F 32 $device
	device="${DEV}2"
	sudo mkfs.ext4 $device
	#sync
	sync

	echo -e "\n=== Done! ===\n"
}

function setPartition()
{
	sudo mkfs.vfat -v -c -F 32 /dev/sdb1
	sudo mkfs.ext4 /dev/sdb2
}

# get argument 1 and number of argument
argu1=$1
numArgu=$#

if [ $numArgu -gt 2 ]
then
	echo "Too much argument !! Please try again"
	exit 1
fi

# *********** MAIN **************** #
case "$argu1" in
	"-d") echo "Delete sd card"
		deleteSdCard $2
		exit 1
		;;
	"-p") echo "partition sd card"
		partitionSdCard $2
		exit 1
		;;
	"-h")
        echo "Usage: $(basename $0) [-y] [-z]"
        echo "  -d         Delete all memory sd card"
        echo "  -p         partition sd card"
        exit 1
        ;;
	"-s")   echo "Set sd card"
		;;
	*)	echo "Wrong argument. Please use help command :"
                echo "sh $(basename $0) -h"
                exit 1;;
esac
# *********** END MAIN **************** #
