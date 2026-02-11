#!/usr/bin/env bash

./gosetup remove
./gosetup install 1.21.0 .
echo "$GOROOT"/bin >> $GITHUB_PATH
./gosetup upgrade -f
echo "$GOROOT"/bin >> $GITHUB_PATH
./gosetup remove
./gosetup
