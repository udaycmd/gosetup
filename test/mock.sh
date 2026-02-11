#!/usr/bin/env bash

go version
mkdir -p "$HOME"/.local/ # create if not present
./gosetup.sh install 1.18 # installs at $HOME/.local/go
# shellcheck source=/dev/null
source "$HOME"/.bashrc
./gosetup.sh install 1.21.0
echo "$GOROOT"
# shellcheck source=/dev/null
source "$HOME"/.bashrc
go version
./gosetup.sh upgrade -f
./gosetup.sh remove
echo $?
./gosetup.sh # prints message help into the console
