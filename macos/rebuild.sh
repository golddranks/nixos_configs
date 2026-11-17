#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sudo darwin-rebuild switch --flake "$SCRIPT_DIR"
