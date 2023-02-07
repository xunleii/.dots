# github.com/xunleii dot files

## TLDR;

```
BINDIR=$HOME/.local/bin sh -c "$(curl -fsLS git.io/chezmoi)" -- init --apply https://github.com/xunleii/.dots
```

## Prerequirements

```bash
sudo add-apt-repository ppa:aos1/diff-so-fancy
sudo apt install curl git zsh diff-so-fancy
```

## Used software 

### System

- [`kitty`](https://sw.kovidgoyal.net/kitty/) *(alternative to terminator)*: GPU powered terminal with many features
  - *NOTE: `sudo update-alternatives --config x-terminal-emulator` to update default terminal*

### Shell tools

- [`direnv`](https://direnv.net/): A feature that can load and unload environment variables depending on the current directory.
- [`fasd`](https://github.com/clvv/fasd): Command-line productivity booster
- [`fzf`](https://github.com/junegunn/fzf): General-purpose command-line fuzzy finder
  - *TLDR;*
    ```
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
    ```

### Themes
- `breeze-cursor-theme`
