#!/bin/bash
if [ $# -lt 1 ]; then
	echo "Usage: $0 /dev/diskname [product=nexo] [--force]"
	exit -1 ;
fi

if ! hash udisks 2> /dev/null; then
	if ! hash udisksctl 2> /dev/null; then
		echo "This script requires udisks or udisks2 to be installed"
		exit -1
	else
		mount="udisksctl mount -b";
		mountpoint="/media/$USER";
	fi
else
	mount="udisks --mount";
	mountpoint="/media";
fi

force='';
if [ $# -ge 2 ]; then
   product=$2;
   if [ $# -ge 3 ]; then
      if [ "x--force" == "x$3" ]; then
         force=yes;
      fi
   fi
else
   product=nexo;
fi

echo "---------build SD card for product $product";

if ! [ -d out/target/product/$product/data ]; then
   echo "Missing out/target/product/$product";
   exit 1;
fi

removable_disks() {
	for f in `ls /dev/disk/by-path/* | grep -v part` ; do
		diskname=$(basename `readlink $f`);
		type=`cat /sys/class/block/$diskname/device/type` ;
		size=`cat /sys/class/block/$diskname/size` ;
		issd=0 ;
		if [ $size -ge 3906250 ]; then
			if [ $size -lt 62500000 ]; then
				issd=1 ;
			fi
		fi
		if [ "$issd" -eq "1" ]; then
			echo -n "/dev/$diskname ";
		fi
	done
	echo;
}
diskname=$1
removables=`removable_disks`

for disk in $removables ; do
   echo "removable disk $disk" ;
   if [ "$diskname" = "$disk" ]; then
      matched=1 ;
      break ;
   fi
done

if [ -z "$matched" -a -z "$force" ]; then
   echo "Invalid disk $diskname" ;
   exit -1;
fi

prefix='';

if [[ "$diskname" =~ "mmcblk" ]]; then
   prefix=p
fi

echo "reasonable disk $diskname, partitions ${diskname}${prefix}1..." ;
umount ${diskname}${prefix}*

# overwrite first 20MB with a test pattern
#sudo badblocks -t 0x44 -b 1024 -c 1 -w ${diskname} 20480

# destroy the partition table
# dd if=/dev/zero of=${diskname} count=1 bs=1024

sudo parted -a minimal \
-s ${diskname} \
unit MiB \
mklabel msdos \
mkpart primary ext4 20 41 \
mkpart primary ext4 41 62 \
mkpart extended 62 100% \
mkpart logical ext4 1625 100% \
mkpart logical ext4 63 1087 \
mkpart logical ext4 1088 1600 \
mkpart logical ext4 1601 1611 \
mkpart logical ext4 1612 1622 \
mkpart logical ext4 1623 1625 \
print

# 1      20,0MiB  40,0MiB  20,0MiB  primary   ext4         lba
# 2      41,0MiB  61,0MiB  20,0MiB  primary   ext4         lba
# 3      62,0MiB  3724MiB  3662MiB  extended               lba
# 6      63,0MiB  1087MiB  1024MiB  logical   ext4         lba
# 7      1088MiB  1600MiB  512MiB   logical   ext4         lba
# 8      1601MiB  1611MiB  10,0MiB  logical   ext4         lba
# 9      1612MiB  1622MiB  10,0MiB  logical   ext4         lba
#10      1623MiB  1625MiB  2,00MiB  logical   ext4         lba
# 5      1625MiB  3724MiB  2099MiB  logical   ext4         lba

PART_boot=1
PART_recovery=2
PART_extended=3
PART_data=5
PART_system=6
PART_cache=7
PART_vendor=8
PART_misc=9
PART_crypt=10

sudo partprobe && sleep 1

for n in ${PART_boot} ${PART_recovery} ${PART_data} ${PART_system} ${PART_cache} ${PART_vendor} ${PART_misc} ${PART_crypt} ; do
   if ! [ -e ${diskname}${prefix}$n ] ; then
      echo "--------------missing ${diskname}${prefix}$n" ;
      exit 1;
   fi
   sync
done

echo "all partitions present and accounted for!";

echo "------------------making boot partition"
mkfs.ext4 -F -L boot ${diskname}${prefix}${PART_boot}
sync && sleep 1
echo "------------------making recovery partition"
mkfs.ext4 -F -L recovery ${diskname}${prefix}${PART_recovery}
sync && sleep 1
echo "------------------making data partition"
mkfs.ext4 -F -L data ${diskname}${prefix}${PART_data}
sync && sleep 1
echo "------------------making system partition"
mkfs.ext4 -F -L system ${diskname}${prefix}${PART_system}
sync && sleep 1
echo "------------------making cache partition"
mkfs.ext4 -F -L cache ${diskname}${prefix}${PART_cache}
sync && sleep 1
echo "------------------making vendor partition"
mkfs.ext4 -F -L vendor ${diskname}${prefix}${PART_vendor}
sync && sleep 1
echo "------------------making misc partition"
mkfs.ext4 -F -L misc ${diskname}${prefix}${PART_misc}
sync && sleep 1
echo "------------------making crypt partition"
mkfs.ext4 -F -L crypt ${diskname}${prefix}${PART_crypt}
sync && sleep 1


echo "------------------mounting boot, recovery, data, vendor partitions"
sync && sudo partprobe && sleep 5

for n in ${PART_boot} ${PART_recovery} ${PART_data} ${PART_vendor} ; do
   echo "--- mounting ${diskname}${prefix}${n}";
   ${mount} ${diskname}${prefix}${n}
done


sudo cp -rfv out/target/product/$product/boot/* ${mountpoint}/boot/
sudo cp -rfv out/target/product/$product/boot/* ${mountpoint}/recovery/
sudo cp -rfv out/target/product/$product/uramdisk-recovery.img ${mountpoint}/recovery/uramdisk.img
sudo cp -rfv out/target/product/$product/data/* ${mountpoint}/data/
sudo cp -rfv out/target/product/$product/vendor/* ${mountpoint}/vendor/

if [ -e ${diskname}${prefix}5 ]; then
   # Check whether system image is sparse or not
   system_img=out/target/product/$product/system.img
   file $system_img | grep sparse > /dev/null
   if [ $? -eq 0 ] ; then
      sudo ./out/host/linux-x86/bin/simg2img $system_img ${diskname}${prefix}${PART_system}
   else
      sudo dd if=$system_img of=${diskname}${prefix}${PART_system} bs=1M
   fi
   sync && sleep 1
   sudo e2fsck -f ${diskname}${prefix}${PART_system}
else
   echo "-----------missing ${diskname}${prefix}${PART_system}";
fi

ubootimage=out/target/product/$product/boot/u-boot.nexo
if [ -e ${ubootimage} ]; then
   sudo dd if=${ubootimage} of=${diskname} bs=512 seek=2 conv=fsync
else
   echo "-----------missing ${ubootimage} - rebuild AOSP, and then try again (or dd uboot manually to 0x200 offset)"
fi

sync && sudo umount ${diskname}${prefix}*

