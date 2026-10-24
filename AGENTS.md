# AGENTS.md

## What this repo is

This repo IS `~/.config/mise`: it is installed with `mise bootstrap --adopt`,
so it is the user's global mise config and manages dotfiles and config for
their Macs ([mise](https://mise.jdx.dev): `mise bootstrap` + `mise dot`). The
base config is `config.toml` + `config.macos.toml` at the repo root;
`miserc.toml` sets `auto_env = true`, so the platform envs (`macos`, `linux`)
load automatically: `config.toml` is always loaded, `config.macos.toml` on macOS
only. It is extended by modules, folders `conf.d/<name>/` (`fish`, `git`, `ssh`,
`claude`, `dev`), each with `mise.toml` plus `mise.macos.toml` / `mise.linux.toml`
where needed. Modules are always loaded (not optional) and globally, so their
`[tools]`, `[env]`, `[bootstrap.packages]` and `[dotfiles]` apply everywhere;
machine files `conf.d/machines/mise.{personal,radiofrance}.toml` carry the
differences and load only via `-E` (`mise -E radiofrance bootstrap`, comma list
allowed), `MISE_ENV` or `~/.config/mise/miserc.local.toml` (gitignored; written automatically
by the `persist-profile` task, first command of the post-packages hook, from the first
`-E` bootstrap if absent, never overwritten; edit it to change profile). The root
`config.toml` loads after the `conf.d` fragments and overrides them, so
per-machine vars have no base default (templates use `| default(value="")`).
Each module has its own `home/` tree (mirrors `$HOME`, resolved relative to the
module folder; files are symlinked into the repo, only `*.tera` files are
rendered templates, copied). Base task bodies live in `scripts/` (`banner.sh`),
module task bodies in `conf.d/<name>/scripts/`. A fresh Mac: install mise, then
`mise -E <profile> bootstrap --adopt https://github.com/xunleii/.dots.git` into
an empty `~/.config/mise`. See [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) for the
full cheat sheet (layout, modules, hook order, identity, chezmoi equivalents,
Tera gotchas, safe testing).

## The one rule that matters here

**Never edit files on the live machine to fix something — edit the source in
this repo instead**, then apply. If you're asked to change `~/.config/foo` or
similar, find its entry in `[dotfiles]` (in `config.toml` / `config.macos.toml` or the owning `conf.d/<name>/mise[.macos].toml`)
and edit the `source` it points to (usually `conf.d/<name>/home/.config/foo`). Dotfiles are
symlinks into this repo, so for those the edit is live (and already in git); templates need an apply. A fix made only on disk is clobbered
by the next apply.

Apply with `mise bootstrap` (the full run), or `mise dot apply` for
dotfiles only. Preview with `mise dot diff` / `mise dot status`. Never run
`mise run` / `exec` / `install` to test: they auto-install all global tools
(see [Testing safely](docs/BOOTSTRAP.md#testing-safely)).

## macOS only

This repo is **single-platform on purpose**. Do not add portability: no
Linux/WSL/Windows branches, no per-distro package abstraction, no CI images for
other OSes.

The `check-volumes` task (inlined in `config.macos.toml`) is the `pre-packages`
bootstrap hook, defined in `config.macos.toml` (so macOS only), and runs on every
`mise bootstrap` before anything is installed. It fails hard when the
Runtimes/Spaces volumes are not mounted. macOS-only content goes in
`config.macos.toml` / a module's `mise.macos.toml`. Keep it working.

Concretely, when editing a template here:

- **Don't** branch on the OS — it's always macOS. Write the macOS code
  directly (in `mise.macos.toml` where a module has cross-OS content too; use
  `os() == "macos"` in a template only when one file serves both).
- **Do** still branch where a real difference exists (e.g. Intel vs Apple
  Silicon release assets).
- **Do** still vary by machine, with the machine files (`conf.d/machines/mise.{personal,radiofrance}.toml`): extra packages and `[vars]` overrides
  (`git_email`, `git_signingkey`) live there, and templates read the vars.
  Those are not OS branches.

## Machine layout: Runtimes and Spaces

Two dedicated volumes — an external drive on desktop Macs, a dedicated APFS
volume on the internal disk on laptops — declared once in the `[vars]` table of
`config.toml` (base) as `runtimes_root`, `spaces_root` and `spaces`, and exported to
scripts and templates via `[env]` (`MISE_VAR_*`). Read them from there; never
hardcode `/Volumes/...` in a template, a fish function or a script. Neither is
guaranteed to be mounted (`check-volumes` refuses to run without them).

- `/Volumes/Runtimes` — every toolchain, cache and package dir (`MISE_DATA_DIR` in `config.toml` and the
  `[env]` of modules, e.g. dev's toolchain env, redirect them all there).
- `/Volumes/Spaces/<Space>/<host>/<user>/<repo>` — all working copies. Spaces
  are `Lab`, `Work`, `OSS`, `Personal`.

Adding a Space is one edit to `spaces` (space-separated, `[vars]` only takes
scalars) plus an apply. Full convention, including the `clone` helper:
[docs/SPACES.md](docs/SPACES.md).

## Package changes: GUI-only apps need a manual follow-up step

Adding a `brew`/`brew-cask` line to `[bootstrap.packages]` (in `config.toml` / `config.macos.toml` for
everywhere, else in the `conf.d/` module or machine file that needs it; casks go in the macOS files) is enough to get it *installed* on the next `mise bootstrap`. But installing
the app is not the same as configuring it — anything that only has a GUI setup
flow (e.g. Secretive: open the app once and generate a Secure Enclave key
yourself, there's no CLI for that) needs a manual step afterwards, and any
config value that depends on it has to be updated by hand, then re-applied.
For the signing key, that value is the `git_signingkey` var in the
machine file (e.g. `conf.d/machines/mise.personal.toml`; empty means no signing); update it, then
re-run `mise bootstrap`. There are no secrets in this setup: `git_name` is a plain
`[vars]` entry in `config.toml`; `git_email` lives in the machine files.

The post-packages hook runs `persist-profile`, then `mise bootstrap packages prune --yes`, so anything
**not** declared in `[bootstrap.packages]` gets uninstalled on the next
bootstrap, across the active files (a profile selected only with `-E` and not
persisted in `miserc.local.toml` counts as dropped; `persist-profile` normally
writes it, unless bootstrap failed before this hook). The list is hand-curated: never suggest a
bare `brew install`, it gets reverted. Edit the right `config*.toml` / `conf.d/` file instead.

## Where a new tool goes

Pick the narrowest one that works, in this order: `[bootstrap.packages]` in
`config.toml` / `config.macos.toml` or a module (`brew`, `brew-cask`) → mise
`[tools]` in the owning module's `conf.d/<m>/mise.toml` (modules are loaded
globally, so these are on PATH everywhere; runtimes in `dev`, `czg` in `git`,
claude-swap / ccstatusline / plannotator in `claude`, fish on Linux in
`fish/mise.linux.toml`). The base `config.toml` only holds `usage`, settings,
vars, `MISE_DATA_DIR` and the `~/.local/bin` PATH.

Never add a `curl` fetch to a shell startup file: vendor the file as a dotfile
instead (e.g. `kubectl.fish` in the `dev` module).

## Commit messages

See `CLAUDE.md` / `docs/COMMITS.md`: symbol-based `type[scope]: Subject`
convention, not gitmoji shortcodes.
