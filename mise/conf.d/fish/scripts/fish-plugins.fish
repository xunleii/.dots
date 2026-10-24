#!/usr/bin/env fish
# Update fisher plugins when fish_plugins changed since the last run
# (replaces run_onchange_after_fish_plugins).
set -l state (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $HOME/.local/state)/dots-fisher
set -l sum (shasum -a 256 <$HOME/.config/fish/fish_plugins | cut -d' ' -f1)
# No state file on the first run: compare against an explicit (possibly empty) string.
set -l previous ""
test -f $state; and set previous (cat $state)
test "$sum" = "$previous"; and exit 0
if not functions -q fisher
    curl -sL https://git.io/fisher | source
end
fisher update
and begin; mkdir -p (dirname $state); printf %s $sum >$state; end
