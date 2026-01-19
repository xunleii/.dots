> [!WARNING]  
> This repo is intended to be used for myself... Use at your own risk

# .dots

## TLDR;

### On macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install and configure chezmoi
brew install chezmoi
chezmoi init --apply https://github.com/xunleii/.dots
```

See [docs/APPLICATIONS.md](docs/APPLICATIONS.md) for the complete list of installed applications with individual installation commands.

### On Debian-based systems _(like Ubuntu)_

```bash
export PATH=$HOME/.local/bin:$PATH
mkdir -p $HOME/.local/bin

# Install fish
sudo apt-add-repository ppa:fish-shell/release-3
sudo apt upgrade
sudo apt update
sudo apt install build-essential fish git gzip keychain neovim unzip wslu

# Install and configure chezmoi
BINDIR=$HOME/.local/bin sh -c "$(curl -fsLS https://raw.githubusercontent.com/twpayne/chezmoi/master/assets/scripts/install.sh)" -- init --apply https://github.com/xunleii/.dots

# Configure fish as default shell
chsh -s $(which fish)
```

## How to use this repository

To be honest, I recommend NOT using this repository, but building your own fork with your own settings. 
I created this repository to store my own configuration and settings for my computers; even if it works for me, I don't guarantee it will for you.

Currently, it has been tested for these systems:
- **macOS** (Sequoia 15.6+) - Primary system
- ~~**Fedora 37 Workstation**~~ _(no more maintained)_
- **WSL Ubuntu 23.04** on **Windows 11** _(to be tested on CI)_

## Troubleshoot and FAQ

### How to load my SSH key to the keychain automatically on WSL?

```fish
keychain_add <path_to_your_ssh_key>
```

## Application Management (on macOS)

This repository uses multiple package managers and installation methods:

- **Homebrew** - Primary package manager for macOS (formulas and casks)
- **Mac App Store** - Via `mas` CLI for App Store apps
- **chezmoi externals** - For specific CLI tools (direnv, lazygit, mise, usage, zoxide, bws)
- **mise** - Polyglot runtime manager for development tools
- **Manual downloads** - For apps not available in package managers

See [docs/APPLICATIONS.md](docs/APPLICATIONS.md) for the complete inventory with installation commands for each application.

## Core Dependencies

### [chezmoi](https://www.chezmoi.io) - _dot files_ manager

> [!Note]
> `chezmoi` is automatically installed on bootstrap... by `chezmoi` itself

`chezmoi` is a fantastic _dot files_ manager that I use to bootstrap and maintain all of my settings. It manages configuration files, external binaries, and templates across multiple machines.

### [fish](https://fishshell.com) shell - a smart and user-friendly command line shell

I use `fish` as my primary shell. It's installed via Homebrew on macOS or via the official PPA on Ubuntu.

The fish configuration includes:
- **Starship** prompt - Fast, customizable prompt
- **Atuin** - Magical shell history with sync
- **Zoxide** - Smarter cd command with fuzzy directory jumping
- Custom functions and abbreviations

### [mise](https://mise.jdx.dev) (formerly rtx) - runtime versions manager

> [!NOTE]
> `mise` is automatically installed on bootstrap, using `chezmoi` externals

To manage development tools and runtimes _(`terraform`, `kubectl`, `python`, `node`, `golang`)_, I use `mise` (the modern successor to `asdf`). `mise` is a fast, polyglot runtime manager which can manage several versions on a single computer.

Versions are managed in `~/.config/mise/config.toml` and allow each project to have different tool versions via `.mise.toml` or `.tool-versions` files.

Current mise-managed tools include:
- Runtime environments (Go, Node, Python)
- Cloud CLIs (AWS, Azure, GCloud, Scaleway)
- Kubernetes tools (kubectl, helm, k9s, argocd)
- Development tools (just, sops, vault)
- CLI utilities (bat, eza, fzf, gh, starship)

### [direnv](https://direnv.net) - unclutter your .profile

> [!NOTE]
> `direnv` is automatically installed on bootstrap, using `chezmoi` externals

Manages environment variables and project layouts per directory. Automatically loads/unloads environment variables when entering/leaving directories, making it perfect for project-specific configurations.

## LICENSE

![WTFLP logo](https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/WTFPL_logo.svg/langfr-150px-WTFPL_logo.svg.png)
