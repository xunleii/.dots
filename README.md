> [!WARNING]
> This repo is intended to be used for myself... Use at your own risk

# .dots

**macOS only.** `chezmoi init` and `chezmoi apply` both hard-fail on any other
OS — this is a deliberate, single-platform setup, not a portable one (see
[AGENTS.md](AGENTS.md#macos-only)).

## TLDR;

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install and configure chezmoi
brew install chezmoi
chezmoi init --apply https://github.com/xunleii/.dots
```

Then the manual steps that have no CLI (see
[docs/APPLICATIONS.md](docs/APPLICATIONS.md)): open Secretive once to generate
a Secure Enclave key, then re-run `chezmoi init` so `signingkey` picks it up.

## How to use this repository

To be honest, I recommend NOT using this repository, but building your own fork
with your own settings. I created this repository to store my own configuration
and settings for my computers; even if it works for me, I don't guarantee it
will for you.

Tested on macOS (Sequoia 15.6+) only.

## Machine layout

Everything that isn't config lives on two external volumes:
`/Volumes/Runtimes` (toolchains and caches) and `/Volumes/Spaces` (all working
copies, grouped into `Lab` / `Work` / `OSS` / `Personal`). Both are declared
once in `chezmoi/.chezmoidata.yaml`.

See [docs/SPACES.md](docs/SPACES.md) for the convention, the `clone` helper and
how to add a Space.

## Application management

Where each thing is installed from — and therefore where to add a new one:

| Method | Source of truth | For |
| --- | --- | --- |
| Homebrew | `chezmoi/dot_Brewfile.tmpl` | almost everything, formulae and casks |
| chezmoi externals | `chezmoi/.chezmoiexternal.toml.tmpl` + `.chezmoidata.yaml` | GitHub-release binaries brew doesn't carry (mise, usage, ocx) |
| mise | `chezmoi/dot_config/private_mise/config.toml.tmpl` | language runtimes, and CLIs only published to npm/pipx |
| `uv tool` | `chezmoi/.chezmoiscripts/run_onchange_after_uv-*.sh.tmpl` | Python tools that must live on the internal disk (headroom, serena) |

`brew bundle cleanup` runs on every apply, so anything **not** in the Brewfile
gets uninstalled. Installing or uninstalling by hand still works: the `brew`
wrapper in `conf.d/45-brew.fish.tmpl` writes the change back into the source
Brewfile for you.

[docs/APPLICATIONS.md](docs/APPLICATIONS.md) covers only the apps that need a
manual, GUI-only setup step after install.

## Core Dependencies

### [chezmoi](https://www.chezmoi.io) - _dot files_ manager

> [!Note]
> `chezmoi` is automatically installed on bootstrap... by `chezmoi` itself

`chezmoi` is a fantastic _dot files_ manager that I use to bootstrap and
maintain all of my settings. It manages configuration files, external binaries,
and templates. See [docs/CHEZMOI.md](docs/CHEZMOI.md) for the cheat sheet used
when editing this repo.

### [fish](https://fishshell.com) shell - a smart and user-friendly command line shell

`fish` is my primary shell, installed via Homebrew. The configuration includes:

- **Starship** prompt - fast, customizable prompt
- **Atuin** - shell history with sync, owns `Ctrl+R`
- **Zoxide** - `z` / `zi`, frecency-based directory jumping
- Custom functions and abbreviations (`clawd`, `clone`, `bwssh`, `nono-profile`)

### [mise](https://mise.jdx.dev) - runtime versions manager

> [!NOTE]
> `mise` is automatically installed on bootstrap, using `chezmoi` externals

`mise` manages language runtimes (Go, Node, Python, Rust) and the few CLIs that
only ship via npm/pipx. Its `[env]` block redirects every toolchain cache onto
`/Volumes/Runtimes`. Per-project overrides go in the project's own `.mise.toml`.

## LICENSE

![WTFLP logo](https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/WTFPL_logo.svg/langfr-150px-WTFPL_logo.svg.png)
