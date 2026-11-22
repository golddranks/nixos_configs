#!/bin/sh

# Applies GitHub main now - unlike rebuild_local.sh, which deploys this checkout.

if [ "$(uname)" = Darwin ]; then
  # The Mac has no upgrade timer; this is how its flake.lock updates get applied.
  exec sudo darwin-rebuild switch --refresh \
    --flake "github:golddranks/nixos_configs/main?dir=macos"
fi

# NixOS: the same way the hourly timer does. A run is skipped when main hasn't
# moved since the last upgrade, so the log tail shows which it was.
sudo systemctl start nixos-upgrade.service
journalctl -u nixos-upgrade.service -n 5 --no-pager -o cat
