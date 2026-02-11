## GoSetup: A Golang Installer for Linux and MacOS

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Language: Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)

### Installation

Get up and running in seconds. Just download the script and make it executable.

#### 1. Download

```bash
# Using curl
curl -sL https://raw.githubusercontent.com/udaycmd/gosetup/main/gosetup.sh -o gosetup

# Using wget
wget -qO gosetup https://raw.githubusercontent.com/udaycmd/gosetup/main/gosetup.sh
```

#### 2. Permissions

```bash
chmod +x gosetup
```

#### 3. Usage

You can run it directly:

```bash
./gosetup
```

_(Optional) Move to your path for global access:_

```bash
sudo mv gosetup /usr/local/bin/
```

### Usage

Using GoSetup is intuitive. Here is everything you can do:

#### 1. Install Go

Install the latest version or a specific one.

```bash
# Install the latest stable version (default to ~/.local/go)
./gosetup install

# Install a specific version
./gosetup install 1.21.5

# Install to a custom directory
./gosetup install 1.21.5 ~/my-go-versions
```

#### 2. Get Source Code

**You can get the Go source directly with `src` command.**

_Note: You can use `src` or `install` commands interchangeably for installing source code if you specify the type._

```bash
# Download latest source code
./gosetup src

# Download specific version source
./gosetup src 1.20.4
```

#### 3. Upgrade

Keep your Go version up to date with a single command.

```bash
# Upgrade to the latest version (interactive)
./gosetup upgrade

# Upgrade without confirmation
./gosetup upgrade --force
```

#### 4. Remove

Clean up your system by removing the Go installation. This will remove the `GOROOT` and clean up your shell profile.

```bash
# Remove Go
./gosetup remove
```

#### 5. Help

See all available commands and options.

```bash
./gosetup help
```

### Requirements

- `curl` or `wget` (GoSetup checks for these automatically)
- `tar`
- `bash` or `zsh`

### Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
