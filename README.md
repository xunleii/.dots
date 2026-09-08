> [!WARNING]
> This repo is intended to be used for myself... Use at your own risk

# .dots

## Requirements

### macOS

**This repo is macOS-only.** Not "mostly tested on macOS" — it refuses to
install anywhere else. `chezmoi init` and `chezmoi apply` both abort with an
error on any other OS, before writing a single file. It is a deliberate
single-platform setup, not a portable one, so there is nothing to disable if
you are on Linux: fork it and strip the guards (see
[AGENTS.md](AGENTS.md#macos-only)).

### Two volumes

Nothing but config lives in `$HOME`. Toolchains and working copies each get
their own volume, so that wiping either never touches the system volume and
never touches this repo:

| Volume | Holds |
| --- | --- |
| `/Volumes/Runtimes` | every language toolchain, cache and package dir (mise, npm, Go, Cargo, pip/uv) |
| `/Volumes/Spaces` | every working copy, grouped by Space — see [docs/SPACES.md](docs/SPACES.md) |

Where they physically live depends on the machine. Only the **mount paths**
matter to this repo, so either option below works, and you can mix them.

#### On a desktop (Mac Mini, Mac Studio): an external drive

Preferred when the machine is not going anywhere. Format the drive as
**APFS (Case-sensitive)** and name the volumes `Runtimes` and `Spaces`.

Use **Disk Utility** for this (`Erase`, then `+` to add the second volume):
formatting a drive from the CLI means `diskutil eraseDisk`, which destroys
everything on the target disk if you name the wrong one. Not worth it here.

#### On a laptop (MacBook): a dedicated volume on the internal disk

Add them to the APFS container that already holds the boot volume. They then
share that container's free space: nothing is pre-allocated, no partition to
resize, each grows on demand, and deleting one hands the space straight back.

```bash
# 1. Find the APFS container holding the boot volume (e.g. disk3)
container=$(diskutil info / | awk -F': +' '/APFS Container:/{print $2; exit}')
echo "$container"

# 2. Add both volumes. APFSX = case-sensitive APFS
diskutil apfs addVolume "$container" APFSX Runtimes
diskutil apfs addVolume "$container" APFSX Spaces
```

This is additive — it does not erase or repartition anything. Prefix with
`sudo` if `diskutil` refuses.

#### Either way

Then create the Spaces you want:

```bash
mkdir -p /Volumes/Spaces/{Lab,Work,OSS,Personal}
```

- Both mount themselves at `/Volumes/<Name>` at every boot. Nothing to add to
  `/etc/fstab`.
- `APFSX` (case-sensitive) is deliberate: it's what a checkout of a repo
  developed on Linux expects. Swap it for `APFS` for the macOS default.
- Different names or paths are fine — they're configurable in
  `chezmoi/.chezmoidata.yaml` (`runtimes_root`, `spaces_root`).
- `chezmoi apply` only *warns* when a volume is missing, it does not fail — so
  an unplugged external drive degrades gracefully instead of blocking the apply.

## Install

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install and configure chezmoi
brew install chezmoi
chezmoi init --apply https://github.com/xunleii/.dots
```

`chezmoi init` asks for your git name, email, whether this is a work machine
(it gates a few Brewfile entries) and your commit signing key. No secret is
ever prompted for or stored.

Then the manual steps that have no CLI (see
[docs/APPLICATIONS.md](docs/APPLICATIONS.md)): open Secretive once to generate
a Secure Enclave key, then re-run `chezmoi init` so `signingkey` picks it up —
the prompt is pre-filled from the running ssh-agent, so it is just Enter.

## How to use this repository

To be honest, I recommend NOT using this repository, but building your own fork
with your own settings. I created this repository to store my own configuration
and settings for my computers; even if it works for me, I don't guarantee it
will for you.

Tested on macOS (Sequoia 15.6+) only.

## Machine layout

Working copies are laid out as
`/Volumes/Spaces/<Space>/<host>/<user>/<repo>`, with `Lab` / `Work` / `OSS` /
`Personal` as Spaces. See [docs/SPACES.md](docs/SPACES.md) for the convention,
the `clone` helper and how to add a Space.

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
