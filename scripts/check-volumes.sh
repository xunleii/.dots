#!/bin/sh
# Fail before bootstrap installs anything if a required volume is missing.
# Only wired from mise.macos.toml (pre-packages hook): volumes exist on macOS only.
set -eu

for vol in "$MISE_VAR_RUNTIMES_ROOT" "$MISE_VAR_SPACES_ROOT"; do
  [ -d "$vol" ] || { echo "check-volumes: $vol is not mounted" >&2; exit 1; }
done
