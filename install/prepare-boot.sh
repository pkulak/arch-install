#!/bin/bash

# run in chrooted
set -o allexport; source /root/tmp/install/config; set +o allexport

# Define locale
cat << EOF > /etc/locale.gen
en_US.UTF-8 UTF-8
EOF

# Generate and assign default locale
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Install Yay
cd /tmp
su $USER_NAME -c "git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -sri --noconfirm"

# Install packages
su $USER_NAME -c "yay --noconfirm -Syu ${CPU_TYPE}-ucode linux linux-headers linux-firmware mkinitcpio efibootmgr grub os-prober mtools dosfstools iwd pacman-contrib snapper snap-pac"

# Host
echo "$HOSTNAME" > /etc/hostname
cat << EOF > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${HOSTNAME}.local ${HOSTNAME}
EOF

# Networking
systemctl enable systemd-resolved

mkdir -p /etc/iwd
cat << EOF > /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true

[Network]
EnableIPv6=true
NameResolvingService=systemd
EOF

systemctl enable iwd

timedatectl set-ntp on

systemctl enable paccache.timer

if [ "$DISK_TYPE" = "ssd" ]; then
    systemctl enable fstrim.timer
fi

# Snapper

cat << EOF > /etc/snapper/configs/root
SUBVOLUME="/"
FSTYPE="btrfs"
QGROUP=""
SPACE_LIMIT="0.5"
FREE_LIMIT="0.2"
ALLOW_USERS=""
ALLOW_GROUPS="wheel"
SYNC_ACL="no"
BACKGROUND_COMPARISON="yes"
NUMBER_CLEANUP="yes"
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="50"
NUMBER_LIMIT_IMPORTANT="10"
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="1800"
EOF

cp /etc/snapper/configs/root /etc/snapper/configs/home
sed -i "1s/.*/SUBVOLUME=\"\/home\"/" /etc/snapper/configs/home

echo "SNAPPER_CONFIGS=\"root home\"" > /etc/conf.d/snapper

systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

# Kernel
echo "HOOKS=(base udev autodetect keyboard modconf block encrypt filesystems fsck)" >> /etc/mkinitcpio.conf

mkinitcpio -p linux

LUKS_UUID=$(blkid $LUKS_PARTITION -o value | head -n1)
cat << EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="${GRUB_BOOT_NAME}"
GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=$LUKS_PARTITION:$LUKS_NAME:allow-discards root=/dev/mapper/$LUKS_NAME"
GRUB_CMDLINE_LINUX=""
GRUB_TIMEOUT_STYLE=menu
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
GRUB_ENABLE_CRYPTODISK=y
EOF

# Install UEFI boot files
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
# Configure Grub
grub-mkconfig -o /boot/grub/grub.cfg

# Clean unused files
pacman -Scc --noconfirm
