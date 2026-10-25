#!/bin/sh
# Abort early unless the Runtimes and Spaces volumes are mounted, dedicated APFS volumes (and /nix
# too when the nix profile is active). Run by the pre-packages hook (config.macos.toml).
# Reads MISE_VAR_RUNTIMES_ROOT, MISE_VAR_SPACES_ROOT and MISE_VAR_NIX, exported by config.toml [env].

fail() {
  echo "check-volumes: $*" >&2
  exit 1
}

# One diskutil field of a path, empty when diskutil cannot resolve it.
diskutil_field() { # <path> <plist key>
  diskutil info -plist "$1" 2>/dev/null | plutil -extract "$2" raw - 2>/dev/null
}

# A plain folder on the boot volume is not a mount point: its MountPoint is "/", not the path.
require_apfs_volume() { # <path>
  mount_point=$(diskutil_field "$1" MountPoint)
  fs_type=$(diskutil_field "$1" FilesystemType)
  [ "$mount_point" = "$1" ] && [ "$fs_type" = apfs ] && return 0
  fail "$1 is not a dedicated APFS volume (mount point: ${mount_point:-none}, fs: ${fs_type:-none})"
}

for volume in "$MISE_VAR_RUNTIMES_ROOT" "$MISE_VAR_SPACES_ROOT"; do
  [ -d "$volume" ] || fail "$volume is not mounted"
  require_apfs_volume "$volume"
done

# /nix only matters on devices with the nix profile (mise -E home,nix, see conf.d/machines/mise.nix.toml).
[ "$MISE_VAR_NIX" != true ] || require_apfs_volume /nix
