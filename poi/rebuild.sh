#!/bin/sh

sudo nixos-rebuild switch --flake path:/home/kon/nixos_configs --update-input nixpkgs --update-input nixos-hardware --commit-lock-file
