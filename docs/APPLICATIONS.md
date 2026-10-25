# Applications

## Where the inventory lives

No hand-written list here: a catalogue of installed apps duplicates
`[bootstrap.packages]` and drifts out of sync with it. The installed set is the
union of `[bootstrap.packages]` over the active files (base, modules, selected machine file; the per-OS files on their OS), and
only that:

| Method | Source of truth |
| --- | --- |
| Homebrew formulae & casks | `[bootstrap.packages]` in [`config.toml`](../config.toml) / [`config.macos.toml`](../config.macos.toml) (base), `conf.d/<module>/mise.toml` / `mise.macos.toml` (fish, git, ssh, claude, dev; casks in the macOS file) or `conf.d/machines/mise.<profile>.toml` (home, radiofrance) — commented, one line per app |
| Language runtimes, npm/pipx CLIs, GitHub-release binaries | `[tools]` of `config.toml` (go, node, rust, python, uv; `usage`) and of each module's `conf.d/<module>/mise.toml` (dev: jqp, crane, doggo, rage; git: czg; claude: claude-swap, ccstatusline, plannotator; fish on Linux: fish itself) |

To see what's actually on the machine right now, ask the machine:

```bash
mise bootstrap packages status    # declared packages vs. what is installed
brew leaves                        # formulae nobody depends on
mise ls                            # runtimes and mise-managed CLIs
```

`mise bootstrap packages prune` (manual, never run by bootstrap) makes the active
`[bootstrap.packages]` *the* state: anything not listed gets uninstalled. Dropping a non-default machine profile (running without its `-E` and without `miserc.local.toml`) or `mise bootstrap unapply <module>` drops its apps.

## Manual steps `mise bootstrap` cannot do

Installing an app is not configuring it. These have GUI-only setup flows with
no CLI equivalent, and are required for the rest of the config to work:

| App | Step | Why it matters |
| --- | --- | --- |
| **Secretive** | Open it once, create a Secure Enclave key, copy the public key | `git` commit signing. Then run `mise run dots:setup:signing:key` and `mise dot apply`: it sets `git_signingkey` (also lands in `~/.ssh/allowed_signers`); until then commits are unsigned. Installed by `conf.d/ssh/mise.macos.toml`; see `conf.d/ssh/home/.config/fish/conf.d/80-secretive-ssh.fish.tera`. |
| **Bitwarden** (desktop) | Enable the SSH agent in Settings, unlock the vault | `bwssh` / `bwansible*` need the agent socket to reach fleet hosts. See `functions/__bw_ssh_sock.fish`. `bwansible*` run only if the `ansible` binaries are on `PATH` (no module installs ansible). Only the desktop app and its SSH agent are used here; there is no secrets manager in this setup. |
| **Little Snitch** | Approve the system extension, then reboot | Nothing else installs cleanly while its rules prompt is pending. |
| **Tailscale** | Sign in | Fleet access. |
| **Claude desktop / Claude Code** | Sign in | — |
| **Terminal font** | Nothing, if you use ghostty | `font-iosevka-term-nerd-font` is installed by the `fish` module and referenced by the ghostty config. |

Everything else in `[bootstrap.packages]` is either headless or logs in on first launch
with nothing to configure.
