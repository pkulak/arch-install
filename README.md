# Arch Install
My Arch install script. After this runs, you'll have an encrypted, btrfs+snapper,
bare Arch Linux install. The `custom-setup.sh` script is where I put the really
personal stuff. Feel free to blow away that bit, or replace it with your own
dotfiles.

# Run

From booted archlinux live cd ([use ventoy](https://github.com/ventoy/Ventoy))

```
# configure wireless
iwctl device list
iwctl station <device> scan
iwctl station <device> get-networks
iwctl station <device> connect <SSID>

# Clone
pacman -Sy git
git clone https://github.com/pkulak/arch-install.git
cd arch-install

# Set installation configuration
vim install/config
./install/install.sh
```

## Thanks
Thanks to badele for the original fork! I've pretty much destroyed it by now, but it
was a perfect jumping-off point.
