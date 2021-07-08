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
	echo "=== Delete Partition sd card ===\n"
	if [ "$1" = "" ]
	then
		echo -n "Name device sdcard [ex: sda/sdb/sdc] > "
		read nameSdCard
		DEV=/dev/$nameSdCard
	else
		DEV=/dev/$1
	fi

	
	echo -n " Do you want delete sd card [y][n] :"
	read res
	if [ $res = "y" ]
	then 
		sd1="${DEV}1"
		sudo umount $sd1
		sd2="${DEV}2"
		sudo umount $sd2
		# cat << EOF | sudo fdisk $nameSdCard
		# 	d
		# 	1
		# 	d
		# 	2
		# 	w
		# EOF
		echo -e "\n=== Delete partitions ===\n"
		{
			echo "d"
			echo "1"
			echo "d"
			echo "2"
			echo "w"
		} | sudo fdisk $DEV
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
	echo "=== Create Partition sd card ===\n"
	if [ "$1" = "" ]
	then
		
        echo -n "Name device sdcard [example: sda/sdb/sdc] > "
        read nameSdCard
		DEV=/dev/$nameSdCard
	else
		DEV=/dev/$1
	fi 
	

        # make sure umount sd card
		sd="${DEV}"
        sudo umount $sd
		sd1="${DEV}1"
        sudo umount $sd1
        sd2="${DEV}2"
        sudo umount $sd2

	
	# # parition 
	# # n : create new parition
	# # p : per
	# # t :
	# # 1
	# # c
	# # w
		echo -e "=== Creating 2 partitions ===\n"
		{
			echo "n"  ## parititon 1 : 50MB
			echo "p"
			echo "1"
			echo "2048"
			echo "104447"
			echo "n"		## parititon 1 : 1G
			echo "p"
			echo "2"
			echo "104448"
			echo "2152448"
			echo "t"		
			echo "1"
			echo "c"
			echo "w"		# sync
		} | sudo fdisk $DEV 
		sync
	# Set partittiton
	sd1="${DEV}1"
	sudo mkfs.vfat -v -c -F 32 $sd1
	sd2="${DEV}2"
	sudo mkfs.ext4 $sd2
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
		deleteFunc $2
		exit 1
		;;
	"-p") echo "partition sd card"
		patitionSd $2
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

