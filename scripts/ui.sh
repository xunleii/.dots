# Tiny output helpers shared by the task scripts. Source it, do not run it:
#
#   . "${MISE_CONFIG_DIR:-$HOME/.config/mise}/scripts/ui.sh"
#   ui_title "Choosing the key that signs your commits"
#   ui_step  "pick the key that signs your commits"
#   ui_ok    "wrote ~/.config/mise/conf.d/git/mise.local.toml"
#
# Output is a bold title, then one short line per event under a 4-character label:
#
#   Choosing the key that signs your commits
#     ..  pick the key that signs your commits
#     ok  wrote ~/.config/mise/conf.d/git/mise.local.toml
#     ->  mise dot apply
#
#   ui_title <text>   bold         what this task is about (print once, first)
#   ui_step  <msg>    blue    ..   what is being done
#   ui_ok    <msg>    green   ok   done
#   ui_warn  <msg>    yellow  !!   not fatal, worth a look (stderr)
#   ui_hint  <msg>    grey    ->   what to run next
#   ui_fail  <msg>    red     xx   to stderr, then exit 1
#
# $HOME is shortened to ~ in messages. Colours come from gum (brew:gum, base config) when it is
# installed AND the stream is a terminal; otherwise, or if gum fails (a mise shim can exist while
# the tool is not active), the same layout is printed as plain text. That also covers logs, pipes
# and the pre-packages hook, which runs before Homebrew has installed gum on a fresh machine.

_ui() { # <gum flags> <fd 1|2> <text>
  flags=$1 fd=$2 text=$3
  # shellcheck disable=SC2086  # $flags is a deliberate word list (--foreground N --bold)
  if [ -t "$fd" ] && command -v gum >/dev/null 2>&1 && gum style $flags "$text" >&"$fd" 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "$text" >&"$fd"
}

# <label> <message...>: "  ok  message", with $HOME shortened to ~.
_line() {
  label=$1
  shift
  printf '  %s  %s' "$label" "$(printf '%s' "$*" | sed "s|$HOME|~|g")"
}

ui_title() { _ui "--bold" 1 "$*"; }
ui_step() { _ui "--foreground 4" 1 "$(_line '..' "$@")"; }
ui_ok() { _ui "--foreground 2" 1 "$(_line 'ok' "$@")"; }
ui_warn() { _ui "--foreground 3" 2 "$(_line '!!' "$@")"; }
ui_hint() { _ui "--foreground 8" 1 "$(_line '->' "$@")"; }
ui_fail() {
  _ui "--foreground 1 --bold" 2 "$(_line 'xx' "$@")"
  exit 1
}
