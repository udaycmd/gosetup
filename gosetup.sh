#!/usr/bin/env bash

# ------------------------------ LICENSE ---------------------------------------
#
# MIT License
#
# Copyright (c) 2026 Uday Tiwari
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail

function show_version {
    echo "0.1.0"
}

function detect_platform {
    local os
    local arch

    os=$(uname -s)
    arch=$(uname -m)

    case $os in
        "Linux")
            os="linux"
            case $arch in
                "x86_64")
                    arch="amd64"
                    ;;
                "i386")
                    arch="386"
                    ;;
                "aarch64" | "armv8")
                    arch="arm64"
                    ;;
                "armv6")
                    arch="armv6l"
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac

    echo "$os-$arch"
}

function get_shell_profile {
    case "$SHELL" in
        *zsh)
            echo "zshrc"
            ;;
        *bash)
            echo "bashrc"
            ;;
        *)
            return 1
            ;;
    esac
}

function get_downloader {
    if command -v curl &>/dev/null; then
        echo "curl -fsSL"
    elif command -v wget &>/dev/null; then
        echo "wget -qO-"
    else
        return 1
    fi
}

get_downloader
