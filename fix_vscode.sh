#!/bin/sh

nix-env -iA nixos.nodejs-12_x
for DIR in $HOME/.vscode-server/bin/*; do
    cd $DIR
    rm -f node
    ln -s $(which node)
done