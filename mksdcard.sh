#!/bin/bash
POSITIONAL=()

_force=''
_noformat=''
_noimages=''
_product="nexo"

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -f|--force)
    _force=yes
    shift
    ;;
  -n|--noformat)
    _noformat=yes
    shift
    ;;
  -i|--noimages)
    _noimages=yes
    shift
    ;;
  -p | --product)
    _product="$2"
    shift
    shift
    ;;
  *) # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift              # past argument
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

_out=out/target/product/${_product}
_ubootimage=${_out}/boot/u-boot.nexo

if [ $# -lt 1 ]; then
  echo "Usage: $0 BLOCK_DEVICE [-p|--product PRODUCT] [-f|--force] [-n|--noformat]"
  echo "    [-p|--product PRODUCT]  out/target/product/PRODUCT to use"
  echo "    [-f|--force]            force using given BLOCK_DEVICE"
  echo "    [-n|--noformat]         do not format, only sync files"
  echo "    [-i|--noimages]         do not dd .img files -- only rsync couple of partitions"
  exit -1
fi

if ! hash udisks 2>/dev/null; then
  if ! hash udisksctl 2>/dev/null; then
    echo "This script requires udisks or udisks2 to be installed"
    exit -1
  else
    mount="udisksctl mount -b"
    mountpoint="/media/$USER"
  fi
else
  mount="udisks --mount"
  mountpoint="/media"
fi

if ! [ -d ${_out}/data ]; then
  echo "Missing ${_out}/data - have you build AOSP?"
  exit 1
fi

if ! [ -f ${_ubootimage} ]; then
  echo "Missing ${_ubootimage} - have you build AOSP?"
  exit 1
fi

removable_disks() {
  for f in $(ls /dev/disk/by-path/* | grep -v part); do
    diskname=$(basename $(readlink $f))
    type=$(cat /sys/class/block/$diskname/device/type 2>/dev/null)
    size=$(cat /sys/class/block/$diskname/size)
    issd=0
    if [ $size -ge 3906250 ]; then
      if [ $size -lt 62500000 ]; then
        issd=1
      fi
    fi
    if [[ $type == "SD" ]]; then
      issd=1
    fi
    if [ "$issd" -eq "1" ]; then
      echo -n "/dev/$diskname "
    fi
  done
  echo
}
diskname=$1
removables=$(removable_disks)

for disk in $removables; do
  echo ">>> System has removable disk '$disk'"
  if [ "$diskname" = "$disk" ]; then
    matched=1
    break
  fi
done

if [ -z "$matched" -a -z "$_force" ]; then
  echo ">>> Invalid disk $diskname"
  exit -1
fi

prefix=''
if [[ "$diskname" =~ "mmcblk" ]]; then
  prefix=p
fi

echo ">>> Build SD card ${diskname}${prefix}* for $_product"

if [[ -z $_noformat ]]; then
  echo ">>> SD card formatting: yes"
else
  echo ">>> SD card formatting: no"
fi

if [[ -z $_noimages ]]; then
  echo ">>> SD card dd of .img: yes"
else
  echo ">>> SD card dd of .img: no"
fi

echo ">>> Unmount SD card"
umount -q ${diskname}${prefix}*

if [[ -z $_noformat ]]; then
  echo ">>> Create GPT on SD card"

  # overwrite first 20MB with a test pattern
  #sudo badblocks -t 0x44 -b 1024 -c 1 -w ${diskname} 20480

  # destroy the partition table
  # sudo dd if=/dev/zero of=${diskname} count=5 bs=1024

  sudo parted -a minimal \
    -s ${diskname} \
    unit MiB \
    mklabel msdos \
    mkpart primary ext4 20 41 \
    mkpart primary ext4 42 63 \
    mkpart extended 64 100% \
    mkpart logical ext4 1636 100% \
    mkpart logical ext4 65 1089 \
    mkpart logical ext4 1090 1602 \
    mkpart logical ext4 1603 1613 \
    mkpart logical ext4 1614 1624 \
    mkpart logical ext4 1625 1635 \
    print

  #Number  Start    End       Size      Type      File system  Flags
  # 1      20,0MiB  41,0MiB   21,0MiB   primary   ext4         lba
  # 2      42,0MiB  63,0MiB   21,0MiB   primary   ext4         lba
  # 3      64,0MiB  14784MiB  14720MiB  extended               lba
  # 6      65,0MiB  1089MiB   1024MiB   logical   ext4         lba
  # 7      1090MiB  1602MiB   512MiB    logical   ext4         lba
  # 8      1603MiB  1613MiB   10,0MiB   logical   ext4         lba
  # 9      1614MiB  1624MiB   10,0MiB   logical   ext4         lba
  #10      1625MiB  1627MiB   2,00MiB   logical   ext4         lba
  # 5      1628MiB  14784MiB  13156MiB  logical   ext4         lba

fi

PART_boot=1
PART_recovery=2
PART_extended=3
PART_system=6
PART_cache=7
PART_vendor=8
PART_misc=9
PART_crypt=10
PART_data=5

declare -A PART_names
PART_names[${PART_boot}]='boot'
PART_names[${PART_recovery}]='recovery'
PART_names[${PART_data}]='data'
PART_names[${PART_system}]='system'
PART_names[${PART_cache}]='cache'
PART_names[${PART_vendor}]='vendor'
PART_names[${PART_misc}]='misc'
PART_names[${PART_crypt}]='crypt'

declare -A PART_options
PART_options[${PART_boot}]='^metadata_csum'
PART_options[${PART_recovery}]='^metadata_csum'
PART_options[${PART_data}]='^metadata_csum'
PART_options[${PART_system}]='^metadata_csum'
PART_options[${PART_cache}]='^metadata_csum'
PART_options[${PART_vendor}]='^metadata_csum'
PART_options[${PART_misc}]='^metadata_csum'
PART_options[${PART_crypt}]='^metadata_csum'

declare -A PART_images
PART_images[${PART_boot}]='boot.img'
PART_images[${PART_recovery}]='recovery.img'
PART_images[${PART_data}]='userdata.img'
PART_images[${PART_system}]='system.img'
PART_images[${PART_cache}]='cache.img'
PART_images[${PART_vendor}]='vendor.img'
PART_images[${PART_misc}]='foooo.img'
PART_images[${PART_crypt}]='foooo.img'

echo ">>> Remount SD card, verify if all partitions are present"
sudo partprobe && sleep 1
for partid in "${!PART_names[@]}"; do
  if ! [ -e ${diskname}${prefix}${partid} ]; then
    echo ">>> Missing ${diskname}${prefix}${partid} partition (${PART_names[$partid]}). Bailing out!"
    exit 1
  else
    echo ">>> Found ${diskname}${prefix}${partid} partition. Will use it as '${PART_names[$partid]}' partition"
  fi
done
echo ">>> All partitions present and accounted for!"

if [[ -z $_noformat ]]; then
  echo ">>> Create filesystems..."

  for partid in "${!PART_names[@]}"; do
    options=${PART_options[$partid]}
    label=${PART_names[$partid]}
    device=${diskname}${prefix}${partid}
    echo ">>> Create filesysytem at ${device} with '${options}' features as '${label}'"
    sudo mkfs.ext4 -q -F -O ${options} -L ${label} ${device}
    sudo sync && sleep 1
  done
  echo ">>> Filesystems created"
fi

for partid in ${PART_boot} ${PART_recovery} ${PART_data} ${PART_vendor}; do
  label=${PART_names[$partid]}
  device=${diskname}${prefix}${partid}
  device_mnt=${mountpoint}/${label}
  ${mount} ${device}
  sleep 1
  echo ">>> Prepare '${label}' partition using 'rsync/cp' from '${_out}/${label}/' to '${device_mnt}'..."
  #sudo rsync --inplace --checksum -vaHAX  ${_out}/${label}/ ${device_mnt}
  sudo cp -rf ${_out}/${label}/* ${device_mnt}

  sudo sync && sleep 1
done

# apparently ramdisk image comes from a non-standar location
#sudo rsync --inplace --checksum -vaHAX  ${_out}/uramdisk-recovery.img ${mountpoint}/${PART_names[$PART_recovery]}/uramdisk.img
sudo cp -rf ${_out}/uramdisk-recovery.img ${mountpoint}/${PART_names[$PART_recovery]}/uramdisk.img

sudo sync && sleep 1

if [[ -z $_noimages ]]; then
  # TODO consider doing this for other paritions as well
  for partid in ${PART_system}; do
    label=${PART_names[$partid]}
    device=${diskname}${prefix}${partid}
    img=${_out}/${PART_images[$partid]}

    echo ">>> Prepare '${label}' partition using 'dd' from '${img}' to '${device}'..."
    echo "(this can take few minutes...)"

    # Check whether image is sparse or not
    file $img | grep sparse >/dev/null
    if [ $? -eq 0 ]; then
      ./out/host/linux-x86/bin/simg2img ${img} ${device}
    else
      sudo dd if=${img} of=${device} bs=1M status=progress
    fi

    sudo sync && sleep 1
  done
fi

echo ">>> Prepare 'u-boot' image using 'dd' from '${_ubootimage}' to '${diskname}'..."
sudo dd if=${_ubootimage} of=${diskname} bs=512 seek=2 conv=fsync status=none

sudo sync && sleep 1

echo ">>> Unmount all"
sudo umount ${diskname}${prefix}* &>/dev/null

echo ">>> Check filesystems last time..."
for partid in "${!PART_names[@]}"; do
  device=${diskname}${prefix}${partid}
  sudo e2fsck -f ${device}
done

echo ">>> All done!"
