#!/bin/sh

argu1=$1
numArgu=$#


if [ $numArgu -gt 2 ]
then
	echo "Too much argument !! Please try again"
	exit 1
fi

# function 
deleteFunc()
{
	echo -n "Name device sdcard [ex: sda/sdb/sdc] > "
	read nameSdCard
	echo -n " Do you want delete sd card [y][n] :"
	read res
	if [ $res = "y" ]
	then 
		sd1="${nameSdCard}1"
		sudo umount $sd1
		sd2="${nameSdCard}2"
		sudo umount $sd2
cat << EOF | sudo fdisk $nameSdCard
	d
	1
	d
	2
	w
EOF
		sync
		echo "delete compele !!"
	elif [ $res = "n" ]
	then
		echo "NO"
	else
		echo "Default"
	fi
}

patitionSd()
{
	echo -n "DOM SD card setup \n"
        echo -n "Name device sdcard [example: sda/sdb/sdc] > "
        read nameSdCard

        # make sure umount sd card
        sudo umount /dev/sdb
        res=$?
        if [ $res -eq -1 ];
        then
                echo "success"
        else
                echo "fail"
        fi

	
# parition 
# n : create new parition
# p : per
# t :
# 1
# c
# w
cat << EOF | sudo fdisk /dev/sdb
	n
	p
	1
	2048
	104447
	n
	p
	2
	104448
	2152448

	t
	1
	c
	w
EOF
	


}

set_sdcard()
{
	sudo mkfs.vfat -v -c -F 32 /dev/sdb1
	sudo mkfs.ext4 /dev/sdb2

}

test()
{
    # SFDISK_CMD = "fdisk"
    # DEV = "/dev/sdb"
    echo -e "\n=== Creating 2 partitions ===\n"
	{
		echo w
	} | fdisk /dev/sdb
}

# MAIN
case "$argu1" in
	"-d") echo "Delete sd card"
		deleteFunc
		exit 1
		;;
	"-p") echo "partition sd card"
		patitionSd
		exit 1
		;;
	"-h")
        echo "Usage: $(basename $0) [-y] [-z]"
        echo "  -d         Delete all memory sd card"
        echo "  -p         Partition sd card"
        echo "  -t         Test sd card"
        exit 1
        ;;
	"-s")   echo "Set sd card"
		set_sdcard
		;;
    "-t")   echo "Test sd card"
        test
        ;;
	*)	echo "Wrong argument."
        echo "Please use help command :"
        echo "    ./$(basename $0) -h"
        exit 1;;
esac

