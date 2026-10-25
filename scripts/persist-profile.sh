#!/bin/sh
# Remember the machine profile (-E <profile>) in miserc.local.toml, once.
#
# `mise -E radiofrance bootstrap --adopt <repo>` only applies the profile for that run. Without it,
# later commands (mise dot apply, mise bootstrap) would see no profile: default git_email and the
# profile's packages missing. So the first bootstrap writes it to the machine-local, gitignored
# miserc.local.toml. Never overwrites: edit that file to change the profile of a machine.

rc="${MISE_CONFIG_DIR:-$HOME/.config/mise}/miserc.local.toml"
[ -e "$rc" ] && exit 0

# Neither hooks nor templates receive the -E value (MISE_ENV stays empty), so read the `-E` / `--env`
# option from the command line of the parent `mise bootstrap`, walking up the process tree.
profile_from_parent() {
  pid=$$
  for _ in 1 2 3 4 5 6 7 8; do
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -n "$pid" ] && [ "$pid" -gt 1 ] || return 0
    args=$(ps -o args= -p "$pid" 2>/dev/null)
    case " $args " in
      *" bootstrap "*)
        found=$(printf '%s\n' "$args" | sed -n -E 's/.* (-E|--env)[ =]([^ ]+).*/\2/p')
        [ -n "$found" ] && { echo "$found"; return 0; }
        ;;
    esac
  done
}

profile="${MISE_ENV:-$(profile_from_parent)}"
[ -n "$profile" ] || exit 0

# "home,nix" -> env = ["home", "nix"]
printf 'env = ["%s"]\n' "$(printf '%s' "$profile" | sed 's/,/", "/g')" > "$rc"
echo "persist-profile: wrote $rc (env = $profile)"
