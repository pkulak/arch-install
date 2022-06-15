#!/bin/bash

set -o allexport; source /root/tmp/install/config; set +o allexport

pacman --noconfirm -Sy archlinux-keyring

# Install all my goodies
su $USER_NAME -c "yay --noconfirm -S sway swayidle alacritty \
  waybar xorg-server-xwayland wl-clipboard fish pipewire pipewire-pulse \
  xdg-desktop-portal-wlr otf-font-awesome noto-fonts noto-fonts-cjk \
  noto-fonts-emoji noto-fonts-extra playerctl pavucontrol mesa \
  rsync zathura zathura-pdf-mupdf imv mpv firefox libnotify \
  ttf-ubuntu-font-family element-desktop qt5-wayland mako grim slurp \
  papirus-icon-theme python-cssselect python-requests python-lxml python-pip \
  fuse htop wf-recorder mlocate ulauncher \
  redshift-wayland-git ant-dracula-gtk-theme lf dragon-drag-and-drop \
  neovim-symlinks autotiling-git"

# AMD graphics (replace this for other graphics cards)
pacman --noconfirm -S libva-mesa-driver xf86-video-amdgpu vulkan-radeon

# Dotfiles!

su $USER_NAME << EOF
cd
git clone https://github.com/pkulak/dotfiles
mkdir -p .config tmp

rm .bashrc
ln -s ~/dotfiles/.bashrc .
ln -s ~/dotfiles/.ideavimrc .

ln -s ~/dotfiles/.config/lf .config/
ln -s ~/dotfiles/.config/nvim .config/
ln -s ~/dotfiles/.config/alacritty .config/
ln -s ~/dotfiles/.config/sway .config/
ln -s ~/dotfiles/.config/fish .config/
ln -s ~/dotfiles/.config/waybar .config/

# Neovim

curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > tmp/install_dein.sh
sh ./tmp/install_dein.sh ~/.local/share/dein
EOF
