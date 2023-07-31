#!/bin/sh

sudo nixos-rebuild switch --flake path:/home/kon/nixos_configs/poi --update-input nixpkgs --commit-lock-file
