#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
nix flake update nixpkgs nixpkgs-unstable nix-darwin --flake "$SCRIPT_DIR"
sudo darwin-rebuild switch --flake "$SCRIPT_DIR"
