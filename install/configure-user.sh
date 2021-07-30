#!/bin/bash

# run in chrooted
set -o allexport; source /root/tmp/install/config; set +o allexport

# User
useradd $USER_NAME --create-home --user-group -G wheel
echo "$USER_NAME:$USER_PASSWORD" | chpasswd
echo "root:$USER_PASSWORD" | chpasswd

# Allow passwordless sudo (needed by this installer)
echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

