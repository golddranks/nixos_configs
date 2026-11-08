#!/bin/sh

# The pinned model leaves no room for evaluating the system, as in nixos-upgrade.
# Stopping it is only safe with a guaranteed restart: the EXIT trap covers a
# failed build, and the signal traps turn Ctrl-C or a dropped session into a
# normal exit so the EXIT trap runs for those too.
trap 'sudo systemctl start llama-cpp.service' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

sudo systemctl stop llama-cpp.service
sudo nixos-rebuild switch --flake path:/home/kon/nixos_configs#bead
