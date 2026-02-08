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

set -eu

RED_COLOR="\e[31m"
GREEN_COLOR="\e[32m"
CYAN_COLOR="\e[36m"
RESET="\e[0m"
GO_VERSION_REGEX="[0-9]+\.[0-9]+(\.[0-9]+)?"

function check_arch_string {
    case $1 in
        "x86_64" | "amd64")
            echo "amd64"
            ;;
        "i386")
            echo "386"
            ;;
        "aarch64" | "armv8" | "arm64")
            echo "arm64"
            ;;
        "armv6")
            echo "armv6l"
            ;;
        *)
            return 1
            ;;
    esac
}

function detect_host_os {
    local os=

    os=$(uname -s)

    if [[ "$os" == "Linux" ]]; then
        echo "linux"
    else
        return 1
    fi
}

function detect_host_platform {
    local os=
    local arch=

    arch=$(uname -m)

    if ! os=$(detect_host_os); then
        return 1
    fi

    if ! arch=$(check_arch_string "$arch"); then
        return 1
    fi

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
        echo "curl -sL"
    elif command -v wget &>/dev/null; then
        echo "wget -q"
    else
        return 1
    fi
}

function get_installed_go_version {
    local str=

    if str=$(go version); then
        echo "$str" | grep -oE "go$GO_VERSION_REGEX"
    else
        return 1
    fi
}

function get_latest_go_version {
    local downloader=
    local go_version_re="go$GO_VERSION_REGEX"

    downloader=$(get_downloader) # already checked before comming here
    $downloader "https://go.dev/dl/" | grep -oE "$go_version_re" | grep -v "rc" | head -n 1
}

function extract_tar {
    tar -xzf "$1"
}

function install_go {
    local downloader=
    local installed_go_ver=
    local latest_ver=
    local go_ver=
    local dir=
    local platform=

    if ! downloader=$(get_downloader); then
        echo -e "${RED_COLOR}Error:${RESET} Neither 'curl' nor 'wget' is installed in you system, please install one of them." >&2
        exit 1
    fi

    if installed_go_ver=$(get_installed_go_version); then
        echo -e "${CYAN_COLOR}Info:${RESET} existing go installation found with $installed_go_ver"
    fi

    if [[ $installed_go_ver == "go$1" ]]; then
        echo -e "${CYAN_COLOR}Ok:${RESET}${GREEN_COLOR} go installation already statisfied with version go$1.${RESET}"
        exit 0
    else
        go_ver="go$1"
    fi

    if [[ $1 == "latest" ]]; then
        latest_ver=$(get_latest_go_version)

        if [[ -z "$latest_ver" ]]; then
            echo -e "${RED_COLOR}Error:${RESET} Unable to get latest go version" >&2
            exit 1
        fi
    fi

    if [[ $installed_go_ver == "$latest_ver" ]]; then
        echo -e "${CYAN_COLOR}Ok:${RESET}${GREEN_COLOR} go installation already statisfied with version $1.${RESET}"
        exit 0
    else
        if [[ -n $latest_ver ]]; then  # can be "" == ""
            go_ver=$latest_ver
        fi
    fi

    platform=$2
    dir=$3

    echo -e "${CYAN_COLOR}Info:${RESET} Downloading ${go_ver} for ${platform} at ${dir}"

    if [[ $downloader == *"curl"* ]]; then
        echo -e "${CYAN_COLOR}Info:${RESET} Downloading with curl"

        if ! $downloader -fSL "https://go.dev/dl/${go_ver}.${platform}.tar.gz" -o "$dir/${go_ver}.${platform}.tar.gz"; then
            echo -e "${RED_COLOR}Error:(curl)${RESET} Download failed." >&2
            exit 1
        fi
    else
        echo -e "${CYAN_COLOR}Info:${RESET} Downloading with wget"

        if ! $downloader -cP "$dir/" "https://go.dev/dl/${go_ver}.${platform}.tar.gz"; then
            echo -e "${RED_COLOR}Error:(wget)${RESET} Download failed." >&2
            exit 1
        fi
    fi

    echo -e "${CYAN_COLOR}Info:${RESET} Extracting binary archive at ${dir}"

    if ! extract_tar "${dir}/${go_ver}.${platform}.tar.gz"; then
        echo -e "${RED_COLOR}Error:(wget)${RESET} Unable to extract the archive" >&2
        exit 1
    fi
}

function check_version_string {
    local re="^$GO_VERSION_REGEX$"

    if [[ $1 =~ $re ]]; then
        echo "$1"
    else
        return 1
    fi
}

function installer {
    local ver=
    local platform=
    local dir=

    if [[ -z $1 || $1 == "latest" ]]; then
        ver="latest"
    else
        if ! ver=$(check_version_string "$1"); then
            echo -e "${RED_COLOR}Error:${RESET} Incorrect version format." >&2
            exit 1
        fi
    fi

    if [[ -z $2 ]]; then
        if ! platform=$(detect_host_platform); then
            echo -e "${RED_COLOR}Error:${RESET} Unsupported host platform." >&2
            exit 1
        fi
    else
        if ! platform=$(check_arch_string "$2"); then
            echo -e "${RED_COLOR}Error:${RESET} Unsupported CPU architecture." >&2
            exit 1
        fi

        local os=
        if ! os=$(detect_host_os); then
            echo -e "${RED_COLOR}Error:${RESET} Unsupported OS." >&2
            exit 1
        fi

        platform="$os-$platform"
    fi

    if [[ -z $3 ]]; then
        dir="$HOME/.local/go"
    else
        dir="$3"
    fi

    if ! [[ -d $dir ]]; then
        echo -e "${RED_COLOR}Error:${RESET} $dir is not a directory." >&2
        exit 1
    fi

    install_go "$ver" "$platform" "$dir"
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
    echo -e "   ${GREEN_COLOR}install [Version] [Directory]${RESET}            Install the latest Go binary for the host architecture inside 'dir' (default is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}install -a <Arch> [Version] [Directory]${RESET}  Install Go binary for a specific architecture inside 'dir' (default is ~/.local/go-<arch>)"
    echo -e "   ${GREEN_COLOR}src [Dir]${RESET}                                Get the Go source code inside 'dir' (default is ~/.local/go-src)"
    echo -e "   ${GREEN_COLOR}upgrade [Dir]${RESET}                            Upgrade current Go binary inside 'dir' (default search location is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}help, --help, -h${RESET}                         Print this help message"
    echo -e ""
    echo -e "${CYAN_COLOR}Options:${RESET}"
    echo -e "   ${GREEN_COLOR}-a, --architecture${RESET}                       Specify architecture (e.g., amd64 or arm64)"
    echo -e ""
    echo -e "${CYAN_COLOR}Examples:${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install 1.21${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install or install latest${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install -a i386 1.19 ~/.my_softwares/mygo_x86${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") src${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") upgrade ~/.my_softwares/mygo${RESET}"
    echo -e ""
    echo -e "${CYAN_COLOR}Note:${RESET}"
    echo -e "   ${GREEN_COLOR}Gosetup automatically sets up the GOROOT env variable pointing towards the installation directory.${RESET}"
    echo -e "   ${GREEN_COLOR}The 'Version' should be formated as <Major>.<Minor>.<Patch>${RESET}"
    echo -e "   ${GREEN_COLOR}If the given 'Directory' does not exist it will create one.${RESET}"
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
