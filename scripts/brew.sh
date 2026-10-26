# Shared by the brew:* tasks. Source it, do not run it.
#
# brew_unmanaged: one "<brew|brew-cask> <name>" per line for every formula (installed on request)
# and cask installed on this Mac that no loaded config declares in [bootstrap.packages].
brew_unmanaged() {
  declared=$(mise bootstrap packages status 2>/dev/null | awk '$1 ~ /^brew/ { print $1, $2 }')
  { brew leaves | sed 's/^/brew /'; brew list --cask | sed 's/^/brew-cask /'; } | while read -r kind name; do
    printf '%s\n' "$declared" | grep -qxF "$kind $name" || echo "$kind $name"
  done
}
