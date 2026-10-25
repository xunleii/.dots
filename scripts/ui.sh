# Tiny output helpers shared by the task scripts. Source it, do not run it:
#
#   UI_TASK="dots:some:task"
#   . "$(dirname "$0")/ui.sh"
#
# Colours come from gum (brew:gum, base config) when it is installed AND the stream is a terminal.
# Otherwise the text is printed plain, so logs, pipes and the pre-packages hook (which runs before
# Homebrew has installed gum on a fresh machine) keep working.
#
#   ui_step <msg>   blue    what is being done
#   ui_ok   <msg>   green   done
#   ui_warn <msg>   yellow  something to look at, not fatal
#   ui_fail <msg>   red     to stderr, then exit 1
#
# Every line is prefixed with $UI_TASK so output stays attributable inside `mise bootstrap`.

_ui() { # <colour 0-255> <fd 1|2> <message...>
  colour=$1 fd=$2
  shift 2
  # A mise shim can exist for gum while the tool is not active (it then fails): fall back to plain.
  if [ -t "$fd" ] && command -v gum >/dev/null 2>&1 &&
    gum style --foreground "$colour" "${UI_TASK:-task}: $*" >&"$fd" 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "${UI_TASK:-task}: $*" >&"$fd"
}

ui_step() { _ui 4 1 "$@"; }
ui_ok() { _ui 2 1 "$@"; }
ui_warn() { _ui 3 2 "$@"; }
ui_fail() {
  _ui 1 2 "$@"
  exit 1
}
