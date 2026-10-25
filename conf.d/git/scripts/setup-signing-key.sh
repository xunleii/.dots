#!/bin/sh
# Pick this machine's SSH signing key from the agent and store it as git_signingkey.
#
# git_signingkey is machine-specific, so it is deliberately not in the repo: it goes to the gitignored
# conf.d/git/mise.local.toml, a file this script owns entirely. Needs ssh-add (the agent, e.g.
# Secretive) and fzf.

out="$(cd "$(dirname "$0")/.." && pwd)/mise.local.toml"

keys=$(ssh-add -L 2>/dev/null) || {
  echo "setup-signing-key: no key in the SSH agent (SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-unset})" >&2
  exit 1
}

key=$(printf '%s\n' "$keys" | fzf --prompt='signing key> ' --height=40% --reverse) || exit 1

printf '[vars]\ngit_signingkey = "%s"\n' "$key" > "$out"
echo "setup-signing-key: wrote $out"
echo "Next: mise dot apply"
