#!/usr/bin/env bash

mkdir -p "$HOME/.local"
./gosetup remove
./gosetup install 1.21.0

GOBIN="$HOME/.local/bin"
echo "$GOBIN" >> $GITHUB_PATH
export PATH="$GOBIN:$PATH"

./gosetup upgrade -f
./gosetup remove
./gosetup
