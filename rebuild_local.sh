#!/bin/sh

# Deploys this checkout as it is, uncommitted changes included - unlike
# upgrade.sh, which applies GitHub main. The next hourly upgrade switches the
# host back to main; to test for longer, first run
# `sudo systemctl stop nixos-upgrade.timer` (lasts until the next reboot).

dir=$(cd "$(dirname "$0")" && pwd)

# The Mac has its own flake. Without a #host, both darwin-rebuild and
# nixos-rebuild pick the configuration named after this host.
if [ "$(uname)" = Darwin ]; then
  exec sudo darwin-rebuild switch --flake "$dir/macos"
fi

# bead: the pinned model leaves no room for evaluating the system, as in
# nixos-upgrade. Stopping it is only safe with a guaranteed restart: the EXIT
# trap covers a failed build, and the signal traps turn Ctrl-C or a dropped
# session into a normal exit so the EXIT trap runs for those too.
if systemctl is-active --quiet llama-cpp.service; then
  trap 'sudo systemctl start llama-cpp.service' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  trap 'exit 129' HUP
  sudo systemctl stop llama-cpp.service
fi

sudo nixos-rebuild switch --flake "path:$dir"
