#!/bin/bash

# run in main archlinux iso installed shell

if [ ! -f install/config ]; then
    echo "Please copy one sample file from config/* to install/config"
    exit 1
fi

set -o allexport; source install/config; set +o allexport

#######################################
# Partition
#######################################

# part1 EFI boot
# part2 LUKS
parted -s $DISK \
mklabel gpt \
mkpart ESP fat32 1MiB 513MiB \
mkpart LUKS ext4 513MiB 100% \
set 1 esp on \
set 1 boot on \
align-check optimal 1

#######################################
# Disk Encryption
#######################################
LUKS_SSD_OPTION=""
if [ "$DISK_TYPE" = "ssd" ]; then
    LUKS_SSD_OPTION="--align-payload 8192"
fi

echo -n "${LUKS_PASSWORD}" | cryptsetup ${LUKS_SSD_OPTION} --type luks1 --cipher aes-xts-plain64 --hash sha256 luksFormat ${LUKS_PARTITION} -
echo -n "${LUKS_PASSWORD}" | cryptsetup luksOpen ${LUKS_PARTITION} ${LUKS_NAME} -

#######################################
# Filesystem
#######################################

# Format disk
mkfs.vfat -F32 -n BOOT $BOOT_PARTITION
mkfs.btrfs /dev/mapper/$LUKS_NAME

# Mount BTRFS partition
BTRFS_SSD_OPTION=""
if [ "$DISK_TYPE" = "ssd" ]; then
    BTRFS_SSD_OPTION="ssd,"
fi

opts_btrfs="${BTRFS_SSD_OPTION}defaults,noatime,nodiratime,compress-force=zstd,autodefrag"
mount -o $opts_btrfs /dev/mapper/$LUKS_NAME /mnt

# Create BTRFS partitions
cd /mnt

# Create subvol
btrfs subvolume create @hometop
btrfs subvolume create @roottop
btrfs subvolume create @vlogtop
btrfs subvolume create @vcchtop

mkdir @hometop/live
mkdir @roottop/live

btrfs su cr @hometop/live/snapshot
btrfs su cr @roottop/live/snapshot

# Disable copy-on-write for logs and cache
chattr +C @vlogtop
chattr +C @vcchtop

# umount all paritions
cd $OLDPWD
umount -R /mnt

# Mount vols
mount -o $opts_btrfs,subvol=@roottop/live/snapshot /dev/mapper/$LUKS_NAME /mnt
mkdir -p /mnt/{boot,home,var/log,var/cache,.snapshots}
mount -o $opts_btrfs,subvol=@hometop/live/snapshot /dev/mapper/$LUKS_NAME /mnt/home
mount -o $opts_btrfs,subvol=@roottop /dev/mapper/$LUKS_NAME /mnt/.snapshots
mkdir -p /mnt/home/.snapshots
mount -o $opts_btrfs,subvol=@hometop /dev/mapper/$LUKS_NAME /mnt/home/.snapshots
mount -o $opts_btrfs,subvol=@vlogtop /dev/mapper/$LUKS_NAME /mnt/var/log
mount -o $opts_btrfs,subvol=@vcchtop /dev/mapper/$LUKS_NAME /mnt/var/cache
mount $BOOT_PARTITION /mnt/boot

# Make a swapfile
cd /mnt/var/cache
truncate -s 0 swapfile
chattr +C swapfile
btrfs property set swapfile compression none
dd if=/dev/zero of=swapfile bs=1M count=2048 status=progress
chmod 600 swapfile
mkswap swapfile
swapon swapfile
cd $OLDPWD

#######################################
# System installation
#######################################

# Minimal installation
pacstrap /mnt base base-devel git

# Generate fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Mount sensitive data in memory
mkdir -p /root/tmp
mount ramfs /root/tmp -t ramfs

mv install /root/tmp/

mkdir -p /mnt/root/tmp
mount --bind /root/tmp /mnt/root/tmp

#######################################
# System installation
#######################################

arch-chroot /mnt /root/tmp/install/configure-user.sh
arch-chroot /mnt /root/tmp/install/prepare-boot.sh
arch-chroot /mnt /root/tmp/install/custom-setup.sh
