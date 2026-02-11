#!/usr/bin/env bash

./gosetup remove
source "$HOME"/.bashrc
./gosetup install 1.21.0 .
source "$HOME"/.bashrc
./gosetup upgrade -f
./gosetup remove
./gosetup
