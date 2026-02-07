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

RED_COLOR="\e[31m"
GREEN_COLOR="\e[32m"
CYAN_COLOR="\e[36m"
RESET="\e[0m"

function show_gosetup_version {
    :
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

function current_go_version {
    go version
}

function get_downloader {
    if command -v curl &>/dev/null; then
        echo "curl"
    elif command -v wget &>/dev/null; then
        echo "wget"
    else
        return 1
    fi
}

function download_go {
    local downloader

    if downloader=$(get_downloader); then
        echo "$downloader"
    else
        echo -e "${RED_COLOR}Error:${RESET} Neither 'curl' nor 'wget' is installed in you system, please install one of them." >&2
        exit 1
    fi
}

function help {
    echo -e "${CYAN_COLOR}Usage:${RESET} $(basename "$0") [command] [option]"
    echo -e ""
    echo -e "${CYAN_COLOR}Commands:${RESET}"
    echo -e "   ${GREEN_COLOR}install <dir>${RESET}            Install Go binary for the host architecture in 'dir' (default is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}install -a <arch> <dir>${RESET}  Install Go binary for a specific architecture in 'dir' (default is ~/.local/go-<arch>)"
    echo -e "   ${GREEN_COLOR}source <dir>${RESET}             Get the Go source code in 'dir' (default is ~/.local/go-src)"
    echo -e "   ${GREEN_COLOR}upgrade <dir>${RESET}            Upgrade current Go binary in 'dir' (default search location is ~/.local/)"
    echo -e "   ${GREEN_COLOR}help${RESET}                     Print this help message"
    echo -e ""
    echo -e "${CYAN_COLOR}Options:${RESET}"
    echo -e "   ${GREEN_COLOR}-a, --architecture${RESET}       Specify architecture (e.g., amd64 or arm64)"
    echo -e ""
    echo -e "${CYAN_COLOR}Examples:${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install -a i386 ~/.my_softwares/mygo_x86${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") source${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") upgrade ~/.my_softwares/mygo${RESET}"
}

function main {
    help
}

main "$@"
