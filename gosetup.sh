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

function detect_host_platform {
    local os=
    local arch=

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
        "Darwin")
            os="darwin"
            case $arch in
                "x86_64")
                    arch="amd64"
                    ;;
                "arm64")
                    arch="arm64"
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
        echo "curl -sL"
    elif command -v wget &>/dev/null; then
        echo "wget -q"
    else
        echo -e "${RED_COLOR}Error:${RESET} Neither 'curl' nor 'wget' is installed in you system, please install one of them." >&2
        exit 1
    fi
}

function get_latest_go_version {
    local downloader=
    local go_version_re="go$GO_VERSION_REGEX"

    downloader=$(get_downloader)
    if [[ $downloader == *"wget"* ]]; then
        downloader="$downloader -O-"
    fi

    $downloader "https://go.dev/dl/" | grep -oE "$go_version_re" | grep -v "rc" | head -n 1
}

function download_it {
    local downloader=

    downloader=$(get_downloader)

     if [[ $downloader == *"curl"* ]]; then
         echo -e "${CYAN_COLOR}Info:${RESET} Downloading with curl"

         if ! $downloader -fS "https://go.dev/dl/$1" -o "$2/$1"; then
             return 1
         fi
     else
         echo -e "${CYAN_COLOR}Info:${RESET} Downloading with wget"

         if ! $downloader -cP "$2/" "https://go.dev/dl/$1"; then
             return 1
         fi
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

function check_installation {
    if [ $? -ne 0 ]; then
        echo -e "${RED_COLOR}Error:${RESET} Installation failed." >&2
        exit 1
    fi

    echo -e "${CYAN_COLOR}Ok:${RESET}${GREEN_COLOR} Go installation is successfull!${RESET}"
    echo -e "${CYAN_COLOR}Info:${RESET} Open a new terminal or re-login into current one."
}

function get_installed_go_version {
    if go version &>/dev/null; then
        go version | grep -oE "go$GO_VERSION_REGEX"
    else
        return 1
    fi
}

function get_go_source {
    local ver="$1"
    local dir=$2
    local file=

    if [[ $ver == *"latest"* ]]; then
        ver=$(get_latest_go_version)

        if [[ -z "$ver" ]]; then
            echo -e "${RED_COLOR}Error:${RESET} Unable to get latest go version" >&2
            return 1
        fi
    fi

    file="${ver}.src.tar.gz"

    echo -e "${CYAN_COLOR}Info:${RESET} Downloading Go Source for ${ver} at ${dir}"

    if ! download_it "$file" "$dir"; then
        echo -e "${RED_COLOR}Error:${RESET} Download failed." >&2
        exit 1
    fi

    echo -e "${CYAN_COLOR}Info:${RESET} Extracting binary archive at ${dir}"

    if ! tar -xzf "$dir/$file"; then
        echo -e "${RED_COLOR}Error:${RESET} Unable to extract the archive" >&2
        return 1
    fi

    rm -v "$dir/$file"

    echo -e "${CYAN_COLOR}Ok:${RESET}${GREEN_COLOR} Go source is downloaded!${RESET}"
    exit 0
}

function install_go {
    local installed_go_ver=
    local go_ver=
    local dir=
    local platform=
    local file=
    local shell_profile=

    if installed_go_ver=$(get_installed_go_version); then
        echo -e "${CYAN_COLOR}Info:${RESET} Existing Go installation found with $installed_go_ver"
    fi

    if [[ $installed_go_ver == "go$1" ]]; then
        echo -e "${CYAN_COLOR}Ok:${RESET}${GREEN_COLOR} Go is already installed with version: $1.${RESET}"
        exit 0
    else
        go_ver="$1"
    fi

    platform=$2
    dir=$3
    file="${go_ver}.${platform}.tar.gz"

    echo -e "${CYAN_COLOR}Info:${RESET} Downloading ${go_ver} for ${platform} at ${dir}"

    if ! download_it "$file" "$dir"; then
        echo -e "${RED_COLOR}Error:${RESET} Download failed." >&2
        exit 1
    fi

    echo -e "${CYAN_COLOR}Info:${RESET} Extracting binary archive at ${dir}"

    if ! tar -xzf "$dir/$file"; then
        echo -e "${RED_COLOR}Error:${RESET} Unable to extract the archive" >&2
        return 1
    fi

    rm -v "$dir/$file"

    local GOROOT="$dir/go"
    [ -z "${GOPATH:-}" ] && GOPATH="$HOME/.go"

    mkdir -p "$GOPATH/bin"

    if ! shell_profile=$(get_shell_profile); then
        echo -e "${RED_COLOR}Error:${RESET} Cannot detect current shell profile." >&2
        return 1
    fi

    touch "$HOME/.${shell_profile}"
    {
      echo '# gosetup'
      echo "export GOROOT=$GOROOT"
      echo "export GOPATH=$GOPATH"
      # shellcheck disable=SC2016
      echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin'
      echo ""
    } >>"$HOME/.${shell_profile}"
}

function installer {
    local ver=
    local platform=
    local dir=

    if [[ -z $1 || $1 == "latest" ]]; then
        ver=$(get_latest_go_version)

        if [[ -z "$ver" ]]; then
            echo -e "${RED_COLOR}Error:${RESET} Unable to get latest go version" >&2
            return 1
        fi
    else
        if ! ver="go$(check_version_string "$1")"; then
            echo -e "${RED_COLOR}Error:${RESET} Incorrect version format." >&2
            exit 1
        fi
    fi

    if ! platform=$(detect_host_platform); then
        echo -e "${RED_COLOR}Error:${RESET} Unsupported host platform." >&2
        exit 1
    fi

    if [[ -z $2 ]]; then
        dir="$HOME/.local/"
    else
        dir="$(cd "$2" && pwd)"
    fi

    if ! [[ -d $dir ]]; then
        echo -e "${RED_COLOR}Error:${RESET} $dir is not a directory." >&2
        exit 1
    fi

    if $3; then
        install_go "$ver" "$platform" "$dir"
        check_installation
    else
        get_go_source "$ver" "$dir"
    fi
}

function help {
    echo -e "${CYAN_COLOR}Usage:${RESET} $(basename "$0") [command] [option]"
    echo -e ""
    echo -e "${CYAN_COLOR}Commands:${RESET}"
    echo -e "   ${GREEN_COLOR}install [Version] [Directory]${RESET}      Install the latest Go binary for the host architecture inside 'dir' (default is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}src [Directory]${RESET}                    Get the Go source code inside 'dir' (default is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}upgrade [Directory]${RESET}                Upgrade current Go binary inside 'dir' (default search location is ~/.local/go)"
    echo -e "   ${GREEN_COLOR}help, --help, -h${RESET}                   Print this help message"
    echo -e ""
    echo -e "${CYAN_COLOR}Examples:${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install 1.21${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") install or install latest${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") src ~/.my_softwares/${RESET}"
    echo -e "   ${GREEN_COLOR}$(basename "$0") upgrade ~/.my_softwares/mygopher${RESET}"
    echo -e ""
    echo -e "${CYAN_COLOR}Note:${RESET}"
    echo -e "   ${GREEN_COLOR}Gosetup automatically set the GOROOT env variable pointing towards the installation directory.${RESET}"
    echo -e "   ${GREEN_COLOR}Gosetup will set the GOPATH to \$HOME/.go if not set.${RESET}"
    echo -e "   ${GREEN_COLOR}The 'Version' should be formated as <Major>.<Minor>.<Patch>${RESET}"
    echo -e "   ${GREEN_COLOR}The given installation 'Directory' must exist.${RESET}"
    echo -e ""
    echo -e "${CYAN_COLOR}Version:${RESET} ${GREEN_COLOR}1.1.0${RESET}"
}

function main {
    local cmd=
    local version=
    local dir=

    if (( $# == 0 )); then
        help
        exit 0
    fi

    cmd="$1"
    shift

    case "$cmd" in
        "install" | "src")
            while (( $# > 0 )); do
                case $1 in
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

            if [[ $cmd == "src" ]]; then
                installer "$version" "$dir" false
            else
                installer "$version" "$dir" true
            fi
            ;;
        "upgrade")
            upgrade "$@"
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
