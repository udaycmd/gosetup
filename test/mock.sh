#!/usr/bin/env bash

set -x
./gosetup.sh remove
echo $?
mkdir -p "$HOME"/.local/ # create if not present

./gosetup.sh install 1.18 # installs at $HOME/.local/go
./gosetup.sh install 1.18 # fails with exit code 1
echo $?
./gosetup.sh upgrade -f
./gosetup.sh remove # removes the current installation
echo $?
./gosetup.sh # prints message help into the console
