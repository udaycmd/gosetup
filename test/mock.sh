#!/usr/bin/env bash

mkdir -p "$HOME/.local"
./gosetup remove
./gosetup install 1.21.0
export PATH="$HOME/.local/go/bin:$PATH"
./gosetup upgrade -f
./gosetup remove
./gosetup
