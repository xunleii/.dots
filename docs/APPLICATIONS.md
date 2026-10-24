# Applications

## Where the inventory lives

No hand-written list here: a catalogue of installed apps duplicates
`[bootstrap.packages]` and drifts out of sync with it. The installed set is the
union of `[bootstrap.packages]` over the active files (base, modules, selected machine file; `mise.macos.toml` ones on macOS), and
only that:

| Method | Source of truth |
| --- | --- |
| Homebrew formulae & casks | `[bootstrap.packages]` in [`mise.toml`](../mise.toml) / [`mise.macos.toml`](../mise.macos.toml) (base), `mise/conf.d/<module>/mise.toml` / `mise.macos.toml` (fish, git, ssh, claude, dev; casks in the macOS file) or `mise/conf.d/machines/mise.<profile>.toml` (personal, radiofrance) — commented, one line per app |
| Language runtimes, npm/pipx CLIs, GitHub-release binaries | `[tools]` of each module's global fragment, `mise/conf.d/<module>/home/.config/mise/conf.d/<module>/mise.toml[.tera]` (dev: runtimes; git: czg; claude: claude-swap, ccstatusline, plannotator); `usage` in [`home/.config/mise/config.toml.tera`](../home/.config/mise/config.toml.tera) |

To see what's actually on the machine right now, ask the machine:

```bash
mise bootstrap packages status    # declared packages vs. what is installed
brew leaves                        # formulae nobody depends on
mise ls                            # runtimes and mise-managed CLIs
```

The post-packages hook runs `mise bootstrap packages prune --yes` on every
bootstrap, so the active `[bootstrap.packages]` *is* the state: anything not listed gets
uninstalled. Dropping a machine profile (running without its `-E`) or `mise bootstrap unapply <module>` drops its apps.

## Manual steps `mise bootstrap` cannot do

Installing an app is not configuring it. These have GUI-only setup flows with
no CLI equivalent, and are required for the rest of the config to work:

| App | Step | Why it matters |
| --- | --- | --- |
| **Secretive** | Open it once, create a Secure Enclave key, copy the public key | `git` commit signing. Put it in `git_signingkey` in the machine file (e.g. `mise/conf.d/machines/mise.personal.toml`), then re-run `mise bootstrap` — it also lands in `~/.ssh/allowed_signers`. Installed by `mise/conf.d/ssh/mise.macos.toml`; see `mise/conf.d/ssh/home/.config/fish/conf.d/80-secretive-ssh.fish.tera`. |
| **Bitwarden** (desktop) | Enable the SSH agent in Settings, unlock the vault | `bwssh` / `bwansible*` need the agent socket to reach fleet hosts. See `functions/__bw_ssh_sock.fish`. `bwansible*` run only if the `ansible` binaries are on `PATH` (no module installs ansible). Only the desktop app and its SSH agent are used here; there is no secrets manager in this setup. |
| **Little Snitch** | Approve the system extension, then reboot | Nothing else installs cleanly while its rules prompt is pending. |
| **Tailscale** | Sign in | Fleet access. |
| **Claude desktop / Claude Code** | Sign in | — |
| **Terminal font** | Nothing, if you use ghostty | `font-iosevka-term-nerd-font` is installed by the `fish` module and referenced by the ghostty config. |

Everything else in `[bootstrap.packages]` is either headless or logs in on first launch
with nothing to configure.
