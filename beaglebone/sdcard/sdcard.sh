#!/bin/bash

# version app
function ver()
{
	printf "%03d%03d%03d" $(echo "$1" | tr '.' ' ')
}

mount | grep '^/' | grep -q ${1}

if [ $? -ne 1 ]; then
    echo "Looks like partitions on device /dev/${1} are mounted"
    echo "Not going to work on a device that is currently in use"
    mount | grep '^/' | grep ${1}
    exit 1
fi

echo -e "\nWorking on $DEV\n"

SIZE=`fdisk -l $DEV | grep "$DEV" | cut -d' ' -f5 | grep -o -E '[0-9]+'`

echo DISK SIZE – $SIZE bytes

if [ "$SIZE" -lt 1800000000 ]; then
	echo "Require an SD card of at least 2GB"
	exit 1
fi

function setPartition()
{
	# new versions of sfdisk don't use rotating disk params
	sfdisk_ver=`sfdisk --version | awk '{ print $4 }'`

	if [ $(ver $sfdisk_ver) -lt $(ver 2.26.2) ]; then
        	CYLINDERS=`echo $SIZE/255/63/512 | bc`
        	echo "CYLINDERS – $CYLINDERS"
        	SFDISK_CMD="sfdisk --force -D -uS -H255 -S63 -C ${CYLINDERS}"
	else
        	SFDISK_CMD="sfdisk"
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
	} | $SFDISK_CMD $DEV

	sleep 1

	echo -e "\n=== Done! ===\n"
}
# get argument 1 and number of argument
argu1=$1
numArgu=$#

# MAIN
case "$argu1" in
	"-d") echo "Delete sd card"
		exit 1
		;;
	"-p") echo "partition sd card"
		setPartition
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