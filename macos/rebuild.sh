#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# claude-code-nix is not updated automatically; because I don't trust the flake.
# The currently locked version is code-reviewed to be clean.
# To update it, run: `nix flake update claude-code-nix` and review.
nix flake update nixpkgs nix-darwin --flake "$SCRIPT_DIR"
sudo darwin-rebuild switch --flake "$SCRIPT_DIR"
