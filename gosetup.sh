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

function detect_host_platform {
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
        echo "curl"
    elif command -v wget &>/dev/null; then
        echo "wget"
    else
        return 1
    fi
}

function install_go {
    local downloader=
    local ver=

    if downloader=$(get_downloader); then
        if ver=$(go version); then
            echo -e "${CYAN_COLOR}Info:${RESET} existing go installation found with $ver"
            if [[ "$ver" == *"go$1"* ]]; then
                echo -e "${CYAN_COLOR}Ok:${RESET}${GREEN_COLOR} go installation already statisfied with version $1.${RESET}"
                exit 0
            fi
        fi

        echo -e "${CYAN_COLOR}Info:${RESET} downloading go version $1 at $3"
        if [[ $downloader == "curl" ]]; then
            echo -e "${CYAN_COLOR}Info:${RESET} Downloading with curl"
            local curl_out="go${1}.${2}.tar.gz"

            if ! curl -fSL --progress-bar "go.dev/dl/$curl_out" -o "$3/$curl_out"; then
                echo -e "${RED_COLOR}Error:(curl)${RESET} download failed, exit code $?." >&2
                exit 1
            fi
        else
            echo -e "${CYAN_COLOR}Info:${RESET} Downloading with wget"
            if ! wget -qcP "$3/" "go.dev/dl/go${1}.${2}.tar.gz"; then
                echo -e "${RED_COLOR}Error:(wget)${RESET} download failed, exit code $?." >&2
                exit 1
            fi
        fi
    else
        echo -e "${RED_COLOR}Error:${RESET} Neither 'curl' nor 'wget' is installed in you system, please install one of them." >&2
        exit 1
    fi
}

function check_version_string {
    local re="^[0-9]+\.[0-9]+(\.[0-9]+)?$"

    if [[ $1 =~ $re ]]; then
        echo "$1"
    else
        return 1
    fi
}

function installer {
    local ver=

    if ver=$(check_version_string "$1"); then
        :
    else
        echo -e "${RED_COLOR}Error:${RESET} Incorrect version format." >&2
        exit 1
    fi
}

function upgrade {
    :
}

function get_source {
    :
}

function help {
    echo -e "${CYAN_COLOR}Usage:${RESET} $(basename "$0") [command] [option]"
    echo -e ""
    echo -e "${CYAN_COLOR}Commands:${RESET}"
    echo -e "   ${GREEN_COLOR}install [version] [dir]${RESET}            Install Go binary for the host architecture inside 'dir' (default is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}install -a <arch> [version] [dir]${RESET}  Install Go binary for a specific architecture inside 'dir' (default is ~/.local/go-<arch>)"
    echo -e "   ${GREEN_COLOR}src [dir]${RESET}                          Get the Go source code inside 'dir' (default is ~/.local/go-src)"
    echo -e "   ${GREEN_COLOR}upgrade [dir]${RESET}                      Upgrade current Go binary inside 'dir' (default search location is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}help, --help, -h${RESET}                   Print this help message"
    echo -e ""
    echo -e "${CYAN_COLOR}Options:${RESET}"
    echo -e "   ${GREEN_COLOR}-a, --architecture${RESET}                 Specify architecture (e.g., amd64 or arm64)"
    echo -e ""
    echo -e "${CYAN_COLOR}Examples:${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install 1.21${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install -a i386 1.19 ~/.my_softwares/mygo_x86${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") src${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") upgrade ~/.my_softwares/mygo${RESET}"
    echo -e ""
    echo -e "${CYAN_COLOR}Note:${RESET}"
    echo -e "   ${GREEN_COLOR}gosetup automatically sets up the GOROOT env variable pointing towards the installation directory${RESET}"
}

function main {
    local cmd=
    local arch=
    local version=
    local dir=

    if (( $# == 0 )); then
        help
        exit 0
    fi

    cmd="$1"
    shift

    case "$cmd" in
        "install")
            while (( $# > 0 )); do
                case $1 in
                    "-a" | "--architecture")
                        if [[ -n "$2" ]]; then
                            arch="$2"
                            shift 2
                        else
                            echo -e "${RED_COLOR}Error:${RESET} '--architecture' requires an argument." >&2
                            exit 1
                        fi
                        ;;
                    *)
                        if [[ -z "$version" ]]; then
                            version="$1"
                        elif [[ -z "$dir" ]]; then
                            dir="$1"
                        else
                            echo -e "${RED_COLOR}Error:${RESET} Too many arguments." >&2
                            exit 1
                        fi
                        shift
                        ;;
                esac
            done
            installer "$version" "$arch" "$dir"
            ;;
        "upgrade")
            upgrade "$@"
            ;;
        "src")
            get_source "$@"
            ;;
        "help" | "-h" | "--help")
            help
            ;;
        *)
            echo -e "${RED_COLOR}Error:${RESET} Unknown command '$cmd'" >&2
            echo -e ""
            help
            exit 1
            ;;
    esac
}

main "$@"
