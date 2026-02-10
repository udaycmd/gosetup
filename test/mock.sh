#!/usr/bin/env bash

# install a very old go version
../gosetup.sh remove # fails with exit code 1
echo $?
../gosetup.sh install 1.18 # installs at $HOME/.local/go
../gosetup.sh install 1.18 # fails with exit code 1
echo $?
../gosetup.sh upgrade -f
../gosetup.sh remove # removes the current installation
../gosetup.sh # prints message help into the console
