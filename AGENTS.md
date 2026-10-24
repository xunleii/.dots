# AGENTS.md

## What this repo is

This repo manages dotfiles and config for the user's Macs with
[mise](https://mise.jdx.dev) (`mise bootstrap` + `mise dotfiles`). The base
config is `mise.toml` + `mise.macos.toml` at the repo root; `.miserc.toml` sets
`auto_env = true`, so the platform envs (`unix`, `macos`, `macos-arm64`) load
automatically: `mise.toml` is always loaded, `mise.macos.toml` on macOS only.
It is extended by modules, folders `mise/conf.d/<name>/` (`fish`, `git`, `ssh`,
`claude`, `dev`), each with the same `mise.toml` / `mise.macos.toml` pair.
Modules are always loaded (not optional); machine files
`mise/conf.d/machines/mise.{personal,radiofrance}.toml` carry the differences and
load only via `-E` (`mise -E radiofrance bootstrap`, comma list allowed), `MISE_ENV` or
`~/.config/mise/miserc.local.toml`. The root `mise.toml` loads after the
`conf.d` fragments and overrides them, so per-machine vars have no base default
(templates use `| default(value="")`). Each module has its own `home/` tree
(mirrors `$HOME`, resolved relative to the module folder; files are symlinked
into the repo, only `*.tera` files are rendered templates, copied); the root
`home/` only holds the mise base config template. Base task bodies live in
`scripts/`, module task bodies in `mise/conf.d/<name>/scripts/`. A fresh Mac:
install mise, then `mise -E <profile> bootstrap --from <repo url>`. See
[docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) for the full cheat sheet (layout,
modules, hook order, identity, Tera gotchas).

## The one rule that matters here

**Never edit files on the live machine to fix something — edit the source in
this repo instead**, then apply. If you're asked to change `~/.config/foo` or
similar, find its entry in `[dotfiles]` (in `mise.toml` / `mise.macos.toml` or the owning `mise/conf.d/<name>/mise[.macos].toml`)
and edit the `source` it points to (usually `mise/conf.d/<name>/home/.config/foo`). Dotfiles are
symlinks, so for those the edit is live; templates need an apply. A fix made only on disk is clobbered
by the next apply.

Apply with `mise bootstrap` (the full run), or `mise dotfiles apply` for
dotfiles only. Preview with `mise dotfiles diff` / `mise dotfiles status`.

## macOS only

This repo is **single-platform on purpose**. Do not add portability: no
Linux/WSL/Windows branches, no per-distro package abstraction, no CI images for
other OSes.

The `check-volumes` task (`scripts/check-volumes.sh`) is the `pre-packages`
bootstrap hook, defined in `mise.macos.toml` (so macOS only), and runs on every
`mise bootstrap` before anything is installed. It fails hard when the
Runtimes/Spaces volumes are not mounted. macOS-only content goes in
`mise.macos.toml`. Keep it working.

Concretely, when editing a template here:

- **Don't** branch on the OS — it's always macOS. Write the macOS code
  directly (in `mise.macos.toml` where a module has cross-OS content too; use
  `os() == "macos"` in a template only when one file serves both).
- **Do** still branch where a real difference exists (e.g. Intel vs Apple
  Silicon release assets).
- **Do** still vary by machine, with the machine files (`mise/conf.d/machines/mise.{personal,radiofrance}.toml`): extra packages and `[vars]` overrides
  (`git_email`, `git_signingkey`) live there, and templates read the vars.
  Those are not OS branches.

## Machine layout: Runtimes and Spaces

Two dedicated volumes — an external drive on desktop Macs, a dedicated APFS
volume on the internal disk on laptops — declared once in the `[vars]` table of
`mise.toml` (base) as `runtimes_root`, `spaces_root` and `spaces`, and exported to
scripts and templates via `[env]` (`MISE_VAR_*`). Read them from there; never
hardcode `/Volumes/...` in a template, a fish function or a script. Neither is
guaranteed to be mounted (`check-volumes` refuses to run without them).

- `/Volumes/Runtimes` — every toolchain, cache and package dir (`MISE_DATA_DIR` in `home/.config/mise/config.toml.tera` and the
  per-module `~/.config/mise/conf.d/<m>/mise.toml` fragments, e.g. dev's toolchain env, redirect them all there).
- `/Volumes/Spaces/<Space>/<host>/<user>/<repo>` — all working copies. Spaces
  are `Lab`, `Work`, `OSS`, `Personal`.

Adding a Space is one edit to `spaces` (space-separated, `[vars]` only takes
scalars) plus an apply. Full convention, including the `clone` helper:
[docs/SPACES.md](docs/SPACES.md).

## Package changes: GUI-only apps need a manual follow-up step

Adding a `brew`/`brew-cask` line to `[bootstrap.packages]` (in `mise.toml` / `mise.macos.toml` for
everywhere, else in the `mise/conf.d/` module or machine file that needs it; casks go in `mise.macos.toml`) is enough to get it *installed* on the next `mise bootstrap`. But installing
the app is not the same as configuring it — anything that only has a GUI setup
flow (e.g. Secretive: open the app once and generate a Secure Enclave key
yourself, there's no CLI for that) needs a manual step afterwards, and any
config value that depends on it has to be updated by hand, then re-applied.
For the signing key, that value is the `git_signingkey` var in the
machine file (e.g. `mise/conf.d/machines/mise.personal.toml`; empty means no signing); update it, then
re-run `mise bootstrap`. There are no secrets in this setup: `git_name` is a plain
`[vars]` entry in `mise.toml`; `git_email` lives in the machine files.

The post-packages hook runs `mise bootstrap packages prune --yes`, so anything
**not** declared in `[bootstrap.packages]` gets uninstalled on the next
bootstrap, across the active files. The list is hand-curated: never suggest a
bare `brew install`, it gets reverted. Edit the right `mise.toml` / `mise.macos.toml` instead.

## Where a new tool goes

Pick the narrowest one that works, in this order: `[bootstrap.packages]` in
`mise.toml` / `mise.macos.toml` or a module (`brew`, `brew-cask`) → mise
`[tools]` in the owning module's global fragment
(`mise/conf.d/<m>/home/.config/mise/conf.d/<m>/mise.toml`, deployed to
`~/.config/mise/conf.d/<m>/mise.toml`; runtimes in `dev`, `czg` in `git`,
claude-swap / ccstatusline / plannotator in `claude`). A `[tools]` in the
repo's own module files would only apply inside the repo, hence the global
fragments. The base `~/.config/mise/config.toml` only holds settings,
`MISE_DATA_DIR`, the `~/.local/bin` PATH and `usage`.

Never add a `curl` fetch to a shell startup file: vendor the file as a dotfile
instead (e.g. `kubectl.fish` in the `dev` module).

## Commit messages

See `CLAUDE.md` / `docs/COMMITS.md`: symbol-based `type[scope]: Subject`
convention, not gitmoji shortcodes.
