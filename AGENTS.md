# AGENTS.md

## What this repo is

This is a [chezmoi](https://www.chezmoi.io) source repo: it manages dotfiles
and config for the user's machines (macOS primary, Ubuntu/WSL secondary). The
source root is `chezmoi/` (see `.chezmoiroot`), not the repo root — file names
under it use chezmoi's naming convention (`dot_`, `private_`, `executable_`,
`run_onchange_`, `.tmpl`, etc.) and map to real paths under `$HOME` when
applied.

## The one rule that matters here

**Never edit files on the live machine to fix something — edit the source in
this repo instead**, then apply with `chezmoi apply` (or `chezmoi diff` first
to preview). If you're asked to change `~/.config/foo` or similar, find its
source counterpart under `chezmoi/` (e.g. `~/.config/foo` →
`chezmoi/dot_config/foo`) and edit that. A fix made only on disk is lost on
the next `chezmoi apply` from someone else's machine, or gets clobbered.

To find the source path for a target path: `chezmoi source-path <target>`
run from the machine where it's applied. To go the other way, strip the
chezmoi attribute prefixes (`dot_`, `private_`, `executable_`, `symlink_`,
`.tmpl` suffix, etc.). See [docs/CHEZMOI.md](docs/CHEZMOI.md) for the full
cheat sheet (naming attributes, scripts, special files, template data,
commands) — check there before re-deriving it from upstream docs.

## OS / platform differences

Never hardcode a fix for "my machine" — this repo targets multiple OSes.
Follow the pattern already used here: a single template branches on
`.chezmoi.os` / `.chezmoi.arch` rather than shipping separate per-OS files.
See existing examples before adding a new one:
- `chezmoi/dot_config/private_fish/conf.d/00-base.fish.tmpl`,
  `40-environment.fish.tmpl`, `80-secretive-ssh.fish.tmpl`
- `chezmoi/dot_gitconfig.tmpl`
- `chezmoi/run_onchange_after_launchagents.sh.tmpl`
- `chezmoi/.chezmoiexternal.toml.tmpl` (branches on `os/arch` for external
  binary downloads)

Pattern: `{{ if eq .chezmoi.os "darwin" }} ... {{ end }}` inside a `.tmpl`
file, not a separate file per OS. Only reach for chezmoi's file-name OS/arch
attributes (`.chezmoi.os`/`.chezmoi.arch` in `.chezmoiignore` patterns, or
per-file `#darwin`-style suffixes) if a whole file must not exist at all on
one platform — otherwise keep it one file, one template.

Supported systems today (see README.md): macOS (primary), Ubuntu/WSL
(secondary, being CI-tested). Fedora is dropped — don't add Fedora-specific
branches.

## Brewfile changes need a manual follow-up step for GUI-only apps

Adding a `brew`/`cask` line to `dot_Brewfile.tmpl` is enough to get it
*installed*: `run_onchange_after_brew.sh.tmpl` re-runs `brew bundle --global`
whenever the rendered Brewfile's content changes, so the next `chezmoi apply`
picks it up automatically. But installing the app is not the same as
configuring it — anything that only has a GUI setup flow (e.g. Secretive:
open the app once and generate a Secure Enclave key yourself, there's no CLI
for that) needs a manual step after `chezmoi apply`, and any config value
that depends on it (e.g. `signingkey` in `~/.config/chezmoi/chezmoi.yaml`,
sourced from the `promptStringOnce` in `.chezmoi.yaml.tmpl`) has to be
updated by hand afterwards, then re-applied.

## Commit messages

See `CLAUDE.md` / `docs/COMMITS.md`: symbol-based `type[scope]: Subject`
convention, not gitmoji shortcodes.
