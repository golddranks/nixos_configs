#!/bin/sh

# Update the root OS channel
sudo nix-channel --update

# Update the current user
nix-channel --update

# Because /boot partition gets full quickly
sudo rm -rf /boot/old
sudo nix-collect-garbage -d

# On Raspberry Pi, if this doesn't work, check if the raspberry_boot dir is old and maybe rebase it
sudo nixos-rebuild switch

echo "Perhaps you should do 'sudo reboot now'"