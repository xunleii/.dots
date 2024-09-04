> [!WARNING]  
> This repo is intended to be used for myself... Use at your own risk

# .dots

## TLDR;

```bash
sudo apt-add-repository ppa:fish-shell/release-3
sudo apt upgrade
sudo apt update
sudo apt install fish gzip keychain neovim unzip

BINDIR=$HOME/.local/bin sh -c "$(curl -fsLS https://raw.githubusercontent.com/twpayne/chezmoi/master/assets/scripts/install.sh)" -- init --apply https://github.com/xunleii/.dots
```

## How to use this repository

To be honest, I recommend NOT using this repository, but building your own fork with your own settings. 
I created this repository to store my own configuration and settings for my computers; even if it works for me, I don't guarantee it will for you.

Currently, it has been tested for these systems:
- ~~**Fedora 37 Workstation**~~ _(no more maintained)_
- **WSL Ubuntu 23.04** on **Windows 11** _(to be tested on CI)_

## Packages requirements

> [!Note]
> Since all my _dots_ files are intended to be run in _WSL_, I removed all configurations for all GUI applications _(like Terminator or Kitty)_. So no dependency on the Windows manager is necessary.


### [chezmoi](https://www.chezmoi.io) - _dot files_ manager

> [!Note]
> `chezmoi` is automatically installed on bootstrap... by `chezmoi` itself

`chezmoi` is a fantastic _dot files_ manager that I use to bootstrap and maintain all of my settings.


### [fish](https://fishshell.com) shell - a smart and user-friendly command line shell

I use `fish` a lot on a daily basis, so it's mandatory to install it.
However, I recommend that you use the latest stable version in order to be totally in line with my settings. For example, on Ubuntu, the fish package is too old for my configuration and you need to install the official PPA (https://launchpad.net/~fish-shell/+archive/ubuntu/release-3).

Everything is explained in their documentation (https://fishshell.com).

### [asdf](https://asdf-vm.com) - runtime versions manager

> [!NOTE]
> `asdf` is automatically installed on bootstrap, using `chezmoi` externals

To manage certain packages _(`terraform`, `kubectl`, but also `python` or `golang`)_, I use `asdf`. `asdf` is a kind of easily configurable "package manager" which can manage several versions on a single computer. What's more, these versions are automatically managed in a file called `.tool-versions`, which allows each project to have different package versions without any problem _(for example, I use it to manage several versions of `python` depending on the project)_.

### [direnv](https://direnv.net) - unclutter your .profile

> [!NOTE]
> `direnv` is automatically installed on bootstrap, using `chezmoi` externals

Like `asdf` but for environment variables and "project layout" _(sort of preconfigured environment for languages like `python` or `golang`)_. It's very practical because I can configure an environment according to where I am.

## LICENSE

![WTFLP logo](https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/WTFPL_logo.svg/langfr-150px-WTFPL_logo.svg.png)
