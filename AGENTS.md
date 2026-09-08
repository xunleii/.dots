# AGENTS.md

## What this repo is

This is a [chezmoi](https://www.chezmoi.io) source repo: it manages dotfiles
and config for the user's Macs. The source root is `chezmoi/` (see
`.chezmoiroot`), not the repo root — file names under it use chezmoi's naming
convention (`dot_`, `private_`, `executable_`, `create_`, `run_onchange_`,
`.tmpl`, etc.) and map to real paths under `$HOME` when applied.

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

## macOS only

This repo is **single-platform on purpose**. Do not add portability: no
Linux/WSL/Windows branches, no per-distro package abstraction, no CI images for
other OSes.

Two guards enforce it, keep both working:

- `chezmoi/.chezmoi.yaml.tmpl` — a `{{ fail }}` at the top, so
  `chezmoi init` refuses before any prompt or any file is written.
- `chezmoi/.chezmoiscripts/run_before_00-macos-only.sh.tmpl` — the same
  `fail`, covering every later `chezmoi apply`. `run_before_` with no
  `_once_`/`_onchange_` infix, so it really does run every time.

Concretely, when editing a template here:

- **Don't** write `{{ if eq .chezmoi.os "darwin" }}` — it's always true. Write
  the macOS code directly.
- **Do** still branch on `.chezmoi.arch` where a real difference exists
  (Intel vs Apple Silicon release assets — see `.chezmoiexternal.toml.tmpl`).
- **Do** still branch on machine identity: `.work` (prompted once by
  `chezmoi init`) and `.chezmoi.hostname` gate machine-specific entries in
  `dot_Brewfile.tmpl`. Those are not OS branches.

## Machine layout: Runtimes and Spaces

Two dedicated volumes — an external drive on desktop Macs, a dedicated APFS
volume on the internal disk on laptops — declared once in
`chezmoi/.chezmoidata.yaml` as `runtimes_root`, `spaces_root` and `spaces`.
Read them from there; never hardcode `/Volumes/...` in a template, a fish
function or a script. Neither is guaranteed to be mounted.

- `/Volumes/Runtimes` — every toolchain, cache and package dir (mise's `[env]`
  block redirects them all there).
- `/Volumes/Spaces/<Space>/<host>/<user>/<repo>` — all working copies. Spaces
  are `Lab`, `Work`, `OSS`, `Personal`.

Adding a Space is one edit to `spaces:` plus `chezmoi apply`. Full convention,
including the `clone` helper: [docs/SPACES.md](docs/SPACES.md).

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

`brew bundle cleanup --global --force` also runs there, so anything **not**
listed in the Brewfile gets uninstalled on the next apply. The `brew` wrapper
in `conf.d/45-brew.fish.tmpl` exists for that reason: a manual
`brew install`/`uninstall` is written back into the source Brewfile.

## Where a new tool goes

Pick the narrowest one that works, in this order: Homebrew
(`dot_Brewfile.tmpl`) → chezmoi external (`.chezmoiexternal.toml.tmpl`, for
GitHub-release binaries brew doesn't carry) → mise (`private_mise/config.toml.tmpl`,
for language runtimes and npm/pipx-only CLIs) → `uv tool` (a
`.chezmoiscripts/run_onchange_after_uv-*.sh.tmpl`, only when the venv must sit
on the internal disk — see the headroom/launchd TCC note there).

Never add a `curl` fetch to a shell startup file: that's what a chezmoi
external is for (see the kubectl completions entry).

## Commit messages

See `CLAUDE.md` / `docs/COMMITS.md`: symbol-based `type[scope]: Subject`
convention, not gitmoji shortcodes.
