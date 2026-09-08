# Applications

## Where the inventory lives

No hand-written list here: a catalogue of installed apps duplicates the
Brewfile and drifts out of sync with it. The installed set is defined by, and
only by:

| Method | Source of truth |
| --- | --- |
| Homebrew formulae & casks | [`chezmoi/dot_Brewfile.tmpl`](../chezmoi/dot_Brewfile.tmpl) — commented, one line per app |
| GitHub-release binaries | [`chezmoi/.chezmoiexternal.toml.tmpl`](../chezmoi/.chezmoiexternal.toml.tmpl) + `packages` in [`.chezmoidata.yaml`](../chezmoi/.chezmoidata.yaml) |
| Language runtimes, npm/pipx CLIs | [`chezmoi/dot_config/private_mise/config.toml.tmpl`](../chezmoi/dot_config/private_mise/config.toml.tmpl) |
| Python tools on the internal disk | [`chezmoi/.chezmoiscripts/`](../chezmoi/.chezmoiscripts/) (`run_onchange_after_uv-*.sh.tmpl`) |

To see what's actually on the machine right now, ask the machine:

```bash
brew bundle list --global --all   # everything the Brewfile installs
brew leaves                        # formulae nobody depends on
mise ls                            # runtimes and mise-managed CLIs
uv tool list                       # headroom, serena
```

`brew bundle cleanup` runs on every `chezmoi apply`, so the Brewfile *is* the
state: anything not listed gets uninstalled.

## Manual steps `chezmoi apply` cannot do

Installing an app is not configuring it. These have GUI-only setup flows with
no CLI equivalent, and are required for the rest of the config to work:

| App | Step | Why it matters |
| --- | --- | --- |
| **Secretive** | Open it once, create a Secure Enclave key, copy the public key | `git` commit signing. Feed it to `signingkey` (re-run `chezmoi init`, the prompt is pre-filled from `ssh-add -L`), then `chezmoi apply` — it also lands in `~/.ssh/allowed_signers`. See `conf.d/80-secretive-ssh.fish.tmpl`. |
| **Bitwarden** (desktop) | Enable the SSH agent in Settings, unlock the vault | `bwssh` / `bwansible*` need the agent socket to reach fleet hosts. See `functions/__bw_ssh_sock.fish`. This is the only thing taken from Bitwarden — no CLI, no API token. |
| **Little Snitch** | Approve the system extension, then reboot | Nothing else installs cleanly while its rules prompt is pending. |
| **Tailscale** | Sign in | Fleet access. |
| **Claude desktop / Claude Code** | Sign in | — |
| **ToolHive Studio** | Sign in, install the MCP servers you want | `clawd --onboard` proposes per-project MCP servers but can't install them for you. |
| **Terminal font** | Nothing, if you use ghostty or kitty | `font-iosevka-term-nerd-font` is already referenced by both configs in `dot_config/`. |

Everything else in the Brewfile is either headless or logs in on first launch
with nothing to configure.
