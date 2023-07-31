#!/bin/sh

nix profile install nixpkgs#nodejs
for DIR in $HOME/.vscode-server/bin/*; do
    cd $DIR
    rm -f node
    ln -s $(which node)
done
