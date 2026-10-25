# mise bootstrap cheat sheet

This repo IS `~/.config/mise`: it is installed with `mise bootstrap --adopt`
([docs](https://mise.jdx.dev/bootstrap/from-repository.html)), which clones the
default branch into `$MISE_CONFIG_DIR`, so every later mise command reads it as
the global config. It used to be a chezmoi source repo; the chezmoi tree is
gone. Everything below is what to know when editing the setup.

## Layout

| Path | Role |
| --- | --- |
| `config.toml` | Base global config: `[vars]`, `[env]`, `[settings]`, `[tools]` (`usage`), shell activation, post-packages hook, general `[bootstrap.packages]`, shared `[dotfiles]` and retired `absent` targets |
| `config.macos.toml` | macOS base: general casks, GNU userland, the `pre-packages` hook that runs `dots:check:volumes` (Runtimes/Spaces) |
| `miserc.toml` | `auto_env = true`: platform envs (`macos`, `linux`, ...) load automatically; `env = ["home"]`: default machine profile |
| `.gitignore` | Machine-local files (`miserc.local.toml`, `config.local.toml`, `mise.local.toml`) |
| `conf.d/<name>/mise.toml` (+ `mise.macos.toml`, `mise.linux.toml`) | Modules `fish`, `git`, `ssh`, `claude`, `dev`: `mise.toml` loads on every OS, the per-OS files on that OS only. They are loaded globally, so they carry `[tools]`, `[env]`, `[bootstrap.packages]` and `[dotfiles]` |
| `conf.d/<name>/home/` | The module's dotfile sources, mirroring `$HOME` (resolved relative to the module folder): static files (symlinked) and Tera templates (`*.tera`, rendered) |
| `conf.d/fish/mise-tasks/` | File task `dots/fish/plugins` (`dots:fish:plugins`), the `post-dotfiles` hook; puts Homebrew's bin dir on PATH itself because fish does not exist yet in the hook phase |
| `conf.d/git/mise-tasks/` | File task `dots/setup/signing/key` (`dots:setup:signing:key`) |
| `conf.d/nix/mise-tasks/` | File task `dots/check/nix` (`dots:check:nix`), run by the nix module's own `pre-packages` hook |
| `tasks/` | File tasks `dots/check/volumes` and `dots/persist/profile` (mise's global task dir) |
| `conf.d/machines/mise.{home,radiofrance,nix}.toml` | Machine files (`nix` is a feature flag combined with one of the others); `home` is the default (`env` in `miserc.toml`), `-E` / `miserc.local.toml` replace it |
| `scripts/` | `banner.sh` (deployed as `~/.local/bin/dots-banner`, not a task); `ui.sh` (output helper) and `volumes.sh` (`diskutil_field`, `require_apfs_volume`; sources `ui.sh`), both sourced by task scripts, see [Tasks](#tasks) |

Every config file carries the dots banner and a header explaining its role and documenting its sections.
Every `[dotfiles]` entry points into its own `home/` (module), or `scripts/` for `dots-banner`.
Modes: `symlink` for a file, `template` for `*.tera` (rendered and copied:
gitconfig, allowed_signers, claude `settings.json`, fish `40-environment` and
`80-secretive-ssh`), `absent` to delete a retired target. `symlink-each` only
where a module owns the whole directory (nono profiles, atuin, ghostty,
lazygit). The shared `~/.config/fish/functions` and `completions` dirs are
written by several modules, so each declares its files one by one. Symlink mode
ignores `permissions`.

## Modules

Modules follow [mise modules](https://mise.jdx.dev/bootstrap/modules.html): a
folder `conf.d/<name>/` with `mise.toml` (+ per-OS files) inside.
They are NOT optional: always loaded. Differences between machines live in the
machine files. `config.toml` loads after `conf.d`, so it would override it:
`git_email` defaults in `conf.d/git` (`git_signingkey` is local, not in the repo); templates
keep `| default(value="")` as a safety net (a profile is always active).

| Module | Holds |
| --- | --- |
| base (`config.toml`, `config.macos.toml`) | volume vars, language runtimes (go, node, rust, python) and `uv`, toolchain cache/install env, `usage`, `dots:check:volumes` hook (macOS file), mise shell activation, general packages, GNU userland and general casks (macOS), retired-target `absent` entries |
| `fish` | shell, prompt, atuin, fisher, completions; macOS: `conf.d/05-gnu-userland.fish`; Linux: fish itself as a tool (`mise.linux.toml`) |
| `git` | gitconfig, signing, lazygit, `__git_remote_slug`, `clone`, tool `czg` |
| `ssh` | ssh files, `bw*` functions, `ssh-import-key`; macOS: `80-secretive-ssh.fish`, casks Bitwarden and Secretive |
| `claude` | `~/.claude`, nono profiles, `nono` / `clawd` / `claude` functions and completions, tools claude-swap, ccstatusline, plannotator; macOS: `allow-sleep` / `prevent-sleep` hooks (`settings.json.tera` registers them only when `os() == "macos"`) |
| `dev` | ghostty, zed, `kubectl.fish` completion (vendored), dev CLIs (`jqp`, `crane`, `doggo`, `rage`), cmake, neovim, orbstack |
| `home`, `radiofrance` | machine files (`conf.d/machines/`): extra casks, `git_email` override (`radiofrance`) |

The `claude-ssh-signing` nono profile carries the Secretive socket under
`platform_overrides.macos`.

Because modules are loaded globally, a module's `[tools]` and `[env]` apply
everywhere, not only inside the repo.

mise activation in fish comes from `[bootstrap.mise_shell_activate]
fish = "auto"` (mise edits `~/.config/fish/config.fish`). The old
`mise activate fish | source` block and its first-prompt workaround were
removed from `00-base.fish`; whether that workaround was still needed is
unverified.

Remove a module with `mise bootstrap unapply <module>`.

Add a module: create `conf.d/<name>/mise.toml` (+ per-OS files) with
its `[dotfiles]` (`source = "home/..."`, relative to the module folder), put the
files in `conf.d/<name>/home/`, then `mise trust` the files. Add a dotfile
or package: edit the owning module's `[dotfiles]` / `[bootstrap.packages]`; put a dotfile in the matching commented group (or add a new commented group).

## Tasks

- **Naming**: `dots:<area>:<action>` (`dots:check:volumes`, `dots:persist:profile`, `dots:setup:signing:key`, `dots:fish:plugins`); `:` is the separator.
- **File tasks**: `tasks/` at the repo root (= `~/.config/mise/tasks`, mise's global task dir) and `conf.d/<name>/mise-tasks/` in a module (`.mise/tasks/` also works). The path gives the name, `/` becomes `:` (`tasks/dots/check/volumes` is `dots:check:volumes`). `conf.d/<m>/tasks/` is NOT discovered.
- **Header**: `#MISE description=...`, `#MISE tools={fzf="latest", gum="latest"}` (all tools on one line), `#MISE quiet=true` comments, plus `#MISE hide=true` on the hook-only tasks (`dots:check:volumes`, `dots:check:nix`, `dots:persist:profile`: not listed by `mise tasks`, run by name or `mise tasks ls --hidden`) at the top, then a long doc comment in the file.
- **All tasks are file tasks**: there is no toml task.
- **`scripts/ui.sh`**: sourced by task scripts; a bold `ui_title`, then one short line per event under a label (`ui_step` `..`, `ui_ok` `ok`, `ui_hint` `->`, `ui_warn` `!!`, `ui_fail` `xx`), `$HOME` shown as `~`, coloured through `gum` when installed and on a tty, plain text otherwise (also if gum fails, or before Homebrew installs it). Tasks run quiet (no `[task] $ cmd` echo).
- **Hooks** call tasks with `mise run --skip-tools <name>`, so no tool gets installed during bootstrap.
- **Tool declaration**: a file task declares each non-system tool it uses (`fzf`, `gum`, ...) in its `#MISE` header, all on one line in the [inline-table form](https://mise.jdx.dev/tasks/file-tasks.html): `#MISE tools={fzf="latest", gum="latest"}` (or `#MISE tools={gum="latest"}`). A task that only reaches gum through `scripts/ui.sh` still declares it (output falls back to plain text without it). System commands (`ssh-add`, `diskutil`, `plutil`, `ps`, `sed`) are not declared. Since hooks use `--skip-tools`, declared tools are not installed there: they must exist another way (Homebrew `brew:gum`, or the module's global `[tools]` for `fzf`).

## Fresh machine

Needs `git`.

```sh
curl https://mise.run | sh
mise bootstrap --adopt https://github.com/xunleii/.dots.git                # home (default)
mise -E radiofrance bootstrap --adopt https://github.com/xunleii/.dots.git  # other profile
```

`--adopt` clones the repo's default branch into `$MISE_CONFIG_DIR` (default
`~/.config/mise`) and bootstraps from it. To try a branch, `?ref=<branch>` on
the URL may work (unverified). The machine profile (`home` or `radiofrance`,
i.e. `conf.d/machines/mise.<name>.toml`) defaults to `home` (`env` in
`miserc.toml`); `-E` selects another one (comma list allowed) and REPLACES the
default, it does not add to it. A home machine needs no `-E`.

Caveats:

- **`$MISE_CONFIG_DIR` must be empty or absent.** Empty an existing populated
  dir first (`--adopt` on a populated dir is unverified). In containers where
  `MISE_CONFIG_DIR=MISE_DATA_DIR=/mise`, set `MISE_CONFIG_DIR=$HOME/.config/mise`.
- **`-E` is persisted automatically.** The `dots:persist:profile` task (first
  post-packages command) writes `~/.config/mise/miserc.local.toml` (gitignored)
  if it does not exist, e.g. `env = ["radiofrance"]`; it never overwrites it and
  does nothing without `-E`. It replaces the `miserc.toml` default too. Later `mise dot apply|diff` and `mise bootstrap`
  need no `-E`. To change the profile, edit that file by hand. If bootstrap
  failed before the post-packages hook, no file is written: rerun with `-E` or
  create it manually, else a bare `mise bootstrap` falls back to `home`
  (home packages added, the omitted profile's packages not installed).
- **How `dots:persist:profile` finds `-E`.** Workaround: hooks and templates do not
  receive the `-E` value (`MISE_ENV` stays empty in a hook, even with `-E`).
  The task uses `$MISE_ENV` if set, else walks up the process tree and reads
  `-E` / `--env` from the command line of the parent `mise bootstrap` (comma
  lists supported). It writes `${MISE_CONFIG_DIR:-$HOME/.config/mise}/miserc.local.toml`
  only if absent.
- **Homebrew must exist** for brew packages; mise does not install it.
- **Trust**: each `conf.d` module file must be trusted (`mise trust`; trusting
  a folder's file trusts that folder, `mise trust --all` does not reach them).
  Unverified whether this is handled under `--adopt`.

`mise bootstrap` order, with this repo's hooks (hooks of all active modules run):

1. `pre-packages`, hooks from different files add up (`mise run --skip-tools`, so no tool is installed yet):
   1. nix module (`conf.d/nix/mise.macos.toml`): `dots:check:nix`
   2. base (`config.macos.toml`): `dots:check:volumes`
2. `[bootstrap.packages]` (Homebrew)
3. `post-packages`: `dots:persist:profile` (writes `miserc.local.toml` from `-E` if absent), nothing else (no pruning)
4. `[dotfiles]`
5. `post-dotfiles` (fish module): `dots:fish:plugins`
6. tools (`[tools]` of the base config and of each module); no `post-tools` hook

Package upgrades: `mise bootstrap packages upgrade` only upgrades casks mise itself installed
(it records a receipt in the Caskroom); casks installed by Homebrew are skipped ("installed and
managed by Homebrew; leaving unchanged"). `[bootstrap.brew] adopt = true` (`config.toml`) lets mise
take over a Homebrew-installed cask whose app is identical to the cask's current download (a single
entry can opt out with `{ adopt = false }`). One-time migration: `brew upgrade --cask`, then
`mise bootstrap packages apply`; after that `packages upgrade` covers them. Unverified in practice:
that `apply` adopts an already brew-installed cask.

`dots:check:volumes` is a hard
failure (macOS only, file task `tasks/dots/check/volumes`, no `uname` guard): it aborts before anything is installed unless both
`/Volumes/Runtimes` and `/Volumes/Spaces` (read from `[vars]` via
`MISE_VAR_*`) are mounted and are dedicated APFS volumes (a plain folder on the boot disk is
refused). `/nix` is checked by its own task, `dots:check:nix` (`conf.d/nix/mise-tasks/dots/check/nix`, nix module hook, runs first), only when the `nix` feature profile is active (`conf.d/machines/mise.nix.toml`
sets `nix = "true"`): `mise -E home,nix bootstrap` or `mise -E radiofrance,nix bootstrap` (`-E`
replaces the default, so list the machine profile too). Without it, `dots:check:nix` does nothing (`/nix not checked`), so it is safe on every machine.

## Identity

No secrets to provision. The git identity is plain `[vars]`, public on
purpose since it ends up in every commit.

- `git_name`: in `config.toml`.
- `git_email`: default GitHub noreply in `conf.d/git/mise.toml` (not `config.toml`,
  which loads after `conf.d` and would override machine files); `radiofrance`
  overrides it with the work address. `home` and no `-E` inherit the default.
- `git_signingkey`: not in the repo. After creating the key in Secretive, run
  `mise run dots:setup:signing:key` (picks from `ssh-add -L`, writes
  the gitignored `conf.d/git/mise.local.toml`), then `mise dot apply`; rerun to change it.
  Unset means no signing config at all (no `signingkey`, `[gpg]` or `gpgsign`; empty `allowed_signers`).

## chezmoi to mise

| chezmoi | mise |
| --- | --- |
| `promptStringOnce` | plain `[vars]` (git identity), machine files for per-machine values |
| `.chezmoidata.yaml` | `[vars]` (also exported as `MISE_VAR_*` via `[env]`) |
| `banner.tmpl` | `scripts/banner.sh`, deployed as `~/.local/bin/dots-banner` (no task). Tera in mise 2026.10 has no include/import (`{% include %}` gives "Unknown template", `{% import %}` gives "Unknown tag"); `exec()` works |
| `run_onchange_*` | tasks wired as bootstrap hooks. They run every time, so they must be idempotent: `dots:fish:plugins` checksums `fish_plugins` |
| `.chezmoiexternal` | mise tools (`usage`, in `config.toml`) + vendored `kubectl.fish` dotfile (dev module); mise itself comes from <https://mise.run> |
| `.chezmoiremove` | `{ mode = "absent" }` entries in `[dotfiles]` |
| `create_` | no equivalent needed: `SOUL.md` (English) is a normal symlinked dotfile (`conf.d/claude/home/.claude/SOUL.md`) |
| `dot_Brewfile.tmpl` | `[bootstrap.packages]` (base + modules). Pruning is manual, like `brew bundle cleanup --force`: `mise bootstrap packages prune` (preview: `--dry-run`); bootstrap never runs it |

## chezmoi cheat sheet

| chezmoi | mise |
| --- | --- |
| `chezmoi init --apply <repo>` | `mise [-E <profile>] bootstrap --adopt <repo>` |
| `chezmoi apply` / `diff` / `status` | `mise dot apply` / `diff` / `status` (from anywhere) |
| `chezmoi cd` / `edit` | `cd ~/.config/mise` / `mise dot edit` |
| `chezmoi add` | `mise dot add` |
| `chezmoi update` | `git -C ~/.config/mise pull`, then `mise bootstrap` |

Most dotfiles are symlinks into the repo, so editing the target already edits
the repo (commit it); `*.tera` files are rendered, edit the source and apply.
`mise dot track` / `save` / `history-watch` is a separate local history, not
needed here.

## Tera gotchas

- `[vars]` only accepts scalars: `spaces` is a space-separated string, split in the template.
- Tests with arguments (`is starting_with(...)`) fail to parse. Use
  `| truncate(length=N, end="") == "..."`.
- A literal `{` directly before `{%` needs `{{ "{" }}` (see `settings.json.tera`).
- `exec()` may run on status checks too: keep commands cheap.
- `mise dot apply --dry-run` skips template rendering, so it won't catch template errors.

## Testing safely

Never run `mise bootstrap`, `mise dot apply`, `mise run`, `mise exec` or
`mise install` to test: the last three auto-install every global tool, and the
config `[env]` points `MISE_DATA_DIR` at the runtimes volume. Prefer read-only
commands (no hooks): `mise config ls`, `mise -E radiofrance dot status|diff`,
`mise -E radiofrance bootstrap plan`.

Use a fake `$HOME` holding a copy of the repo (no `.git`) at `$HOME/.config/mise`,
run from another directory, unset the `XDG_*` and `MISE_DATA_DIR` /
`MISE_CONFIG_DIR` variables, and set `MISE_CEILING_PATHS=<real home>`, otherwise
mise still reads the real config:

```sh
real=$HOME; fake=$(mktemp -d)
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME MISE_DATA_DIR MISE_CONFIG_DIR
mkdir -p $fake/.config/mise && rsync -a --exclude .git ./ $fake/.config/mise/
cd $fake && HOME=$fake MISE_CEILING_PATHS=$real mise -E radiofrance dot status
```

## Known gaps

- Directory permissions: `private_` dirs were `0700` and are not reproduced.
- `trusted_signers` support in `allowed_signers` dropped (the chezmoi data key was never set).
- The old clawd-browser LaunchAgent (`dev.axnic.clawd-browser`) is removed from
  disk but not unloaded: boot it out manually if it was loaded
  (`launchctl bootout gui/$(id -u)/dev.axnic.clawd-browser`).
- Removed for good: clawd-browser, `seed-soul`, kitty, memex, ocx, lm-studio, toolhive-studio, hermes-desktop.
- `gitleaks-redact.sh` warns on stderr when gitleaks is missing and skips empty inputs.
- starship, atuin and zoxide stay Homebrew packages on purpose; `fzf` is a mise
  tool (`[tools]` in `conf.d/fish/mise.toml`). `conf.d/fish` runs the `init` of
  the first three at shell startup, before the mise activation block that
  `mise bootstrap` writes into `~/.config/fish/config.fish` (`config.fish` runs
  after `conf.d`), so mise tools are not on PATH yet. fzf is only called at use
  time. Moving those three to mise would need an early PATH/activation in
  `conf.d/00-base`.
