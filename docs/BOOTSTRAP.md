# mise bootstrap cheat sheet

This repo is driven by `mise bootstrap` + `mise dotfiles` (it used to be a
chezmoi source repo; the chezmoi tree is gone). Everything below is what to
know when editing the setup.

## Layout

| Path | Role |
| --- | --- |
| `.miserc.toml` | `auto_env = true`: platform envs (`unix`, `macos`, `macos-arm64`) load automatically |
| `mise.toml` / `mise.macos.toml` | Base: `[vars]`, `[tasks]`, `[bootstrap.hooks]`, `[bootstrap.packages]`, `[dotfiles]` (macOS file: general casks, GNU userland formulas) |
| `mise/conf.d/<name>/mise.toml` / `mise.macos.toml` | Modules `fish`, `git`, `ssh`, `claude`, `dev`: `mise.toml` loads on every OS, `mise.macos.toml` on macOS only (casks, macOS-only dotfiles) |
| `mise/conf.d/<name>/home/` | The module's dotfile sources, mirroring `$HOME` (resolved relative to the module folder): static files (symlinked) and Tera templates (`*.tera`, rendered) |
| `mise/conf.d/fish/scripts/` | Module task bodies (`fish-plugins.fish`); module tasks run from their folder |
| `mise/conf.d/machines/mise.{personal,radiofrance}.toml` | Machine files, loaded only when selected (`-E`) |
| `home/` | Root dotfile sources: only the mise base config template (`.config/mise/config.toml.tera`) |
| `scripts/` | `check-volumes.sh` (task body) and `banner.sh` (deployed as `dots-banner`, not a task) |

Every `mise*.toml` carries the dots banner and a header explaining its role and documenting its sections.
Every `[dotfiles]` entry points into its own `home/` (module or root), or `scripts/` for `dots-banner`.
Modes: `symlink` for a file, `template` for `*.tera` (rendered and copied:
gitconfig, allowed_signers, claude `settings.json`, mise base config, mise
global fragment of `dev`, fish `40-environment` and `80-secretive-ssh`),
`absent` to delete a retired target. `symlink-each` only where a module owns the
whole directory (nono profiles, atuin, ghostty, lazygit). The shared
`~/.config/fish/functions` and `completions` dirs are written by several
modules, so each declares its files one by one. Symlink mode ignores `permissions`.

## Modules

Modules follow [mise modules](https://mise.jdx.dev/bootstrap/modules.html): a
folder `mise/conf.d/<name>/` with `mise.toml` (+ `mise.macos.toml`) inside.
They are NOT optional: always loaded. Differences between machines live in the
machine files. The root `mise.toml` loads after the `conf.d` fragments, so it
would override them: per-machine vars (`git_email`, `git_signingkey`) have no
base default and templates use `| default(value="")`.

| Module | Holds |
| --- | --- |
| base (`mise.toml`, `mise.macos.toml`) | volume vars, `check-volumes` (macOS file), mise shell activation, general packages, GNU userland and general casks incl. betterdisplay (macOS), retired-target `absent` entries (commented) |
| `fish` | shell, prompt, atuin, fisher, completions; macOS: `conf.d/05-gnu-userland.fish` |
| `git` | gitconfig, signing, lazygit, `__git_remote_slug`, `clone`, global tool `czg` |
| `ssh` | ssh files, `bw*` functions, `ssh-import-key`; macOS: `80-secretive-ssh.fish`, casks Bitwarden and Secretive |
| `claude` | `~/.claude`, nono profiles, `nono` / `clawd` / `claude` functions and completions, global tools claude-swap, ccstatusline, plannotator; macOS: `allow-sleep` / `prevent-sleep` hooks (`settings.json.tera` registers them only when `os() == "macos"`) |
| `dev` | ghostty, zed, `kubectl.fish` completion (vendored), language runtimes and toolchain env (global fragment) |
| `personal`, `radiofrance` | machine files (`mise/conf.d/machines/`): extra casks, `git_email`, `git_signingkey` (personal only) |

The `claude-ssh-signing` nono profile carries the Secretive socket under
`platform_overrides.macos`.

Global tools and env are per module: each deploys
`~/.config/mise/conf.d/<m>/mise.toml` (source under
`mise/conf.d/<m>/home/.config/mise/conf.d/<m>/`). A `[tools]` in the repo's own
module files would only apply inside the repo, hence these global fragments.
The base `~/.config/mise/config.toml` holds only settings, `MISE_DATA_DIR`, the
`~/.local/bin` PATH and `usage`.

mise activation in fish comes from `[bootstrap.mise_shell_activate]
fish = "auto"` (mise edits `~/.config/fish/config.fish`). The old
`mise activate fish | source` block and its first-prompt workaround were
removed from `00-base.fish`; whether that workaround was still needed is
unverified.

Remove a module with `mise bootstrap unapply <module>`.

Add a module: create `mise/conf.d/<name>/mise.toml` (+ `mise.macos.toml`) with
its `[dotfiles]` (`source = "home/..."`, relative to the module folder), put the
files in `mise/conf.d/<name>/home/`, then `mise trust` the files. Add a dotfile
or package: edit the owning module's `[dotfiles]` / `[bootstrap.packages]`.

## Fresh machine

Needs `git`.

```sh
curl https://mise.run | sh
mise -E radiofrance bootstrap --from git@github.com:xunleii/.dots.git
```

[`--from`](https://mise.jdx.dev/bootstrap/from-repository.html) clones the repo
into `$MISE_DATA_DIR/bootstrap-repo` (`--update` pulls) and bootstraps from it.
`-E` selects the machine profile for that run only (`personal` or
`radiofrance`, i.e. `mise/conf.d/machines/mise.<name>.toml`; comma list allowed).

Caveats:

- **Profile is per run.** Re-running `mise bootstrap` without `-E` prunes the
  packages of the omitted profile. Persist it on the machine with `MISE_ENV`
  or `~/.config/mise/miserc.local.toml` (`env = ["radiofrance"]`).
- **Homebrew must exist** for brew packages; mise does not install it.
- **Trust**: each `conf.d` module file must be trusted (`mise trust`; trusting
  a folder's file trusts that folder, `mise trust --all` does not reach them).
  Unverified whether this is handled under `--from`.

`mise bootstrap` order, with this repo's hooks (hooks of all active modules run):

1. `pre-packages` (`mise.macos.toml`): `check-volumes`
2. `[bootstrap.packages]` (Homebrew)
3. `post-packages`: `mise bootstrap packages prune --yes` (uninstalls anything not declared)
4. `[dotfiles]`
5. `post-dotfiles` (fish module): `fish-plugins`
6. tools (global fragments: base config and each module's); no `post-tools` hook

`check-volumes` ([`scripts/check-volumes.sh`](../scripts/check-volumes.sh)) is a hard
failure (macOS only, defined in `mise.macos.toml`, no `uname` guard): it aborts before anything is installed unless both
`/Volumes/Runtimes` and `/Volumes/Spaces` exist (read from `[vars]` via
`MISE_VAR_*`).

## Identity

No secrets to provision. The git identity is plain `[vars]`, public on
purpose since it ends up in every commit.

- `git_name`: in `mise.toml`.
- `git_email`: per machine, in the machine file (`personal`: GitHub noreply;
  `radiofrance`: work address). No base default (root `mise.toml` loads after
  `conf.d` and would override machine files); no `-E` means an empty email.
- `git_signingkey`: per machine (Secretive public key), in `mise/conf.d/machines/mise.personal.toml`.
  Empty means no signing.

## chezmoi to mise

| chezmoi | mise |
| --- | --- |
| `promptStringOnce` | plain `[vars]` (git identity), machine files for per-machine values |
| `.chezmoidata.yaml` | `[vars]` (also exported as `MISE_VAR_*` via `[env]`) |
| `banner.tmpl` | `scripts/banner.sh`, deployed as `~/.local/bin/dots-banner` (no task). Tera in mise 2026.10 has no include/import (`{% include %}` gives "Unknown template", `{% import %}` gives "Unknown tag"); `exec()` works |
| `run_onchange_*` | tasks wired as bootstrap hooks. They run every time, so they must be idempotent: `fish-plugins` checksums `fish_plugins` |
| `.chezmoiexternal` | mise tools (`usage`) + vendored `kubectl.fish` dotfile (dev module); mise itself comes from <https://mise.run> |
| `.chezmoiremove` | `{ mode = "absent" }` entries in `[dotfiles]` |
| `create_` | no equivalent needed: `SOUL.md` (English) is a normal symlinked dotfile (`mise/conf.d/claude/home/.claude/SOUL.md`) |
| `dot_Brewfile.tmpl` | `[bootstrap.packages]` (base + modules). Pruning is automatic, like `brew bundle cleanup --force`: the post-packages hook runs `mise bootstrap packages prune --yes` (preview: `mise bootstrap packages prune --dry-run`) |

## Tera gotchas

- `[vars]` only accepts scalars: `spaces` is a space-separated string, split in the template.
- Tests with arguments (`is starting_with(...)`) fail to parse. Use
  `| truncate(length=N, end="") == "..."`.
- A literal `{` directly before `{%` needs `{{ "{" }}` (see `settings.json.tera`).
- `exec()` may run on status checks too: keep commands cheap.
- `mise dot apply --dry-run` skips template rendering, so it won't catch template errors.

## Testing safely

Never run `mise bootstrap` or `mise dotfiles apply` to test. Prefer read-only
commands (no hooks): `mise -E radiofrance dotfiles status|diff`,
`mise -E radiofrance bootstrap plan`, `mise -E radiofrance bootstrap packages status`.

With a throwaway `$HOME`, also set `MISE_CEILING_PATHS=<real home>` and unset
the `XDG_*` variables, otherwise mise still reads the real config:

```sh
real=$HOME; unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
HOME=$(mktemp -d) MISE_CEILING_PATHS=$real mise -E radiofrance dotfiles status
```

## Known gaps

- Directory permissions: `private_` dirs were `0700` and are not reproduced.
- `trusted_signers` support in `allowed_signers` dropped (the chezmoi data key was never set).
- The old clawd-browser LaunchAgent (`dev.axnic.clawd-browser`) is removed from
  disk but not unloaded: boot it out manually if it was loaded
  (`launchctl bootout gui/$(id -u)/dev.axnic.clawd-browser`).
- Removed for good: clawd-browser, `seed-soul`, kitty, memex, ocx, lm-studio, toolhive-studio, hermes-desktop.
- `gitleaks-redact.sh` warns on stderr when gitleaks is missing and skips empty inputs.
