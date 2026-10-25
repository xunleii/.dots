> [!WARNING]
> This repo is intended to be used for myself... Use at your own risk

# .dots

## Requirements

### macOS

**This repo targets macOS only.** Cross-platform is not a goal: `*.macos.toml`
files hold the macOS casks and dotfiles, and `check-volumes` fails when the
Runtimes/Spaces volumes are missing on macOS. Nothing is portable beyond that,
so on Linux fork it and adapt (see [AGENTS.md](AGENTS.md#macos-only)).

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
  the `[vars]` table of `config.toml` (`runtimes_root`, `spaces_root`).
- `mise bootstrap` fails in its `check-volumes` hook (`config.macos.toml`) when a volume is missing, so
  nothing is installed or written until both are mounted.

## Install

This repo is `~/.config/mise`: `mise bootstrap --adopt` clones it there
([docs](https://mise.jdx.dev/bootstrap/from-repository.html)) and every later
mise command reads it as the global config. Needs `git` (and network). On a
blank Mac:

```bash
# 1. mise
curl https://mise.run | sh

# 2. Everything. `home` is the default profile; -E replaces it (radiofrance, comma list allowed)
mise bootstrap --adopt https://github.com/xunleii/.dots.git               # home
mise -E radiofrance bootstrap --adopt https://github.com/xunleii/.dots.git  # other profile
```

Caveats:

- **`$MISE_CONFIG_DIR` (default `~/.config/mise`) must be empty or absent.**
  Empty an existing one first. In containers where
  `MISE_CONFIG_DIR=MISE_DATA_DIR=/mise`, set `MISE_CONFIG_DIR=$HOME/.config/mise`.
  `?ref=<branch>` on the URL may select a branch (unverified).
- **`home` is the default profile** (`env = ["home"]` in `miserc.toml`); a
  home machine needs neither `-E` nor a local file. `-E` and
  `miserc.local.toml` replace that list, they do not add to it.
- **`-E` is persisted automatically.** The `persist-profile` task (first
  post-packages command) writes `env = ["radiofrance"]` to
  `~/.config/mise/miserc.local.toml` (gitignored) if absent, never overwriting
  it; later `mise bootstrap` / `mise dot ...` need no `-E`. To change the profile,
  edit that file. If bootstrap failed before the post-packages hook, nothing is
  written: rerun with `-E` or create the file by hand, else a bare `mise bootstrap`
  falls back to `home` (home packages added, the
  radiofrance packages not installed).
- **Homebrew must already exist**: brew packages need it, mise does not install it.
- **Trust**: every `conf.d/<module>/mise*.toml` must be trusted
  (`mise trust`). Unverified whether `--adopt` handles this on its own.

No token or prompt is needed: the git identity is plain `[vars]` in the repo (`git_name` in `config.toml`, `git_email` in `conf.d/git`, overridden in the `radiofrance` machine file).
Details: [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md).

Then the manual steps that have no CLI (see
[docs/APPLICATIONS.md](docs/APPLICATIONS.md)): open Secretive once to generate
a Secure Enclave key, put the public key in `git_signingkey` (in the machine's
`conf.d/machines/mise.<name>.toml`), then re-run `mise bootstrap`.

Day to day, from anywhere: `mise dot diff` to preview, `mise dot apply` for
dotfiles only, `mise bootstrap` for everything. Update with
`git -C ~/.config/mise pull` then `mise bootstrap`.

## How to use this repository

To be honest, I recommend NOT using this repository, but building your own fork
with your own settings. I created this repository to store my own configuration
and settings for my computers; even if it works for me, I don't guarantee it
will for you.

Tested on macOS (Sequoia 15.6+) only.

## Modules

`config.toml` + `config.macos.toml` at the root are the base: volume vars,
general packages (GNU userland and general casks on macOS), the
mise shell activation and the retired-target `absent` entries. Everything else
is a module, a folder `conf.d/<name>/`
([mise modules](https://mise.jdx.dev/bootstrap/modules.html)). Modules are
always loaded; machine files carry the differences.

`miserc.toml` at the repo root sets `auto_env = true`: the platform
environments (`macos`, `linux`) load automatically. So each module
has `mise.toml` (every OS) and `mise.macos.toml` / `mise.linux.toml` (that OS only: casks, OS-only
dotfiles), plus its own `home/` tree of dotfile sources.

| Module | Holds |
| --- | --- |
| `fish` | shell, prompt, atuin, fisher, completions; macOS: GNU userland PATH |
| `git` | gitconfig, signing, lazygit, `czg` |
| `ssh` | ssh files, `bw*` functions, `ssh-import-key`; macOS: Secretive, Bitwarden |
| `claude` | `~/.claude`, nono, `clawd` / `nono-profile` functions; macOS: sleep hooks |
| `dev` | ghostty, zed, orbstack, kubectl completion, dev CLIs (`jqp`, `crane`, `doggo`, `rage`), cmake, neovim |
| `home`, `radiofrance` | machine files in `conf.d/machines/mise.<name>.toml`: extra packages, `[vars]` |

`home` loads by default (`miserc.toml`); `-E`, `MISE_ENV` or `miserc.local.toml` replace it.
`config.toml` loads after the `conf.d` fragments and overrides them, so
per-machine vars have no base default (`git_signingkey`; `git_email` defaults in
`conf.d/git`, which loads before the machine files). Modules
are loaded globally, so their `[tools]` and `[env]` apply everywhere.
`mise bootstrap unapply <module>` removes a module. To add one: create
`conf.d/<name>/mise.toml` (+ per-OS files, `home/`) and `mise trust` it.

## Machine layout

Working copies are laid out as
`/Volumes/Spaces/<Space>/<host>/<user>/<repo>`, with `Lab` / `Work` / `OSS` /
`Personal` as Spaces. See [docs/SPACES.md](docs/SPACES.md) for the convention,
the `clone` helper and how to add a Space.

## Application management

Where each thing is installed from — and therefore where to add a new one:

| Method | Source of truth | For |
| --- | --- | --- |
| Homebrew | `[bootstrap.packages]` in `config.toml` / `config.macos.toml` (base) or the module / machine file that needs it (`conf.d/...`) | almost everything, formulae and casks |
| mise | `[tools]` of `conf.d/<module>/mise.toml`; base `config.toml` | language runtimes and `uv` (base), CLIs only published to npm/pipx (git, claude), GitHub-release binaries brew doesn't carry (`usage`, plannotator) |

Bootstrap never uninstalls anything. Packages **not** declared in `[bootstrap.packages]` of an active file
are removed by `mise bootstrap packages prune` (manual; preview with `--dry-run`).
Installing by hand is therefore drift: add the line to the right `config.toml` / `conf.d/...` file and
bootstrap, rather than running `brew install`.

[docs/APPLICATIONS.md](docs/APPLICATIONS.md) covers only the apps that need a
manual, GUI-only setup step after install.

## Core Dependencies

### [mise](https://mise.jdx.dev) - bootstrap, dotfiles and runtimes

`mise` is the single tool behind this repo: `mise bootstrap` installs packages
and runs the setup hooks, `mise dot` symlinks the files under each module's `home/` into
`$HOME` (only `*.tera` files are rendered and copied), and it manages language runtimes (Go, Node, Python, Rust)
and the few CLIs that only ship via npm/pipx. The base `[env]` block
(`config.toml`) redirects every toolchain cache onto `/Volumes/Runtimes`. Per-project overrides
go in the project's own `mise.toml`. See [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md)
for the cheat sheet used when editing this repo.

### [fish](https://fishshell.com) shell - a smart and user-friendly command line shell

`fish` is my primary shell, installed via Homebrew. The configuration includes:

- **Starship** prompt - fast, customizable prompt
- **Atuin** - shell history with sync, owns `Ctrl+R`
- **Zoxide** - `z` / `zi`, frecency-based directory jumping
- Custom functions and abbreviations (`clawd`, `clone`, `bwssh`, `nono-profile`)

## LICENSE

![WTFLP logo](https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/WTFPL_logo.svg/langfr-150px-WTFPL_logo.svg.png)
