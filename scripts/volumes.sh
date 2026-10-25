# APFS volume helpers shared by the dots:check:* tasks. Source it, do not run it:
#
#   . "${MISE_CONFIG_DIR:-$HOME/.config/mise}/scripts/volumes.sh"
#
# Needs ui.sh (sourced here): require_apfs_volume reports through ui_ok / ui_fail.

. "${MISE_CONFIG_DIR:-$HOME/.config/mise}/scripts/ui.sh"

# One diskutil field of a path, empty when diskutil cannot resolve it.
diskutil_field() { # <path> <plist key>
  diskutil info -plist "$1" 2>/dev/null | plutil -extract "$2" raw - 2>/dev/null
}

# A plain folder on the boot volume is not a mount point: its MountPoint is "/", not the path.
# A symlink (e.g. /nix -> /Volumes/...) is refused for the same reason.
require_apfs_volume() { # <path>
  mount_point=$(diskutil_field "$1" MountPoint)
  fs_type=$(diskutil_field "$1" FilesystemType)
  if [ "$mount_point" = "$1" ] && [ "$fs_type" = apfs ]; then
    ui_ok "$1 is a dedicated APFS volume"
    return 0
  fi
  ui_fail "$1 is not a dedicated APFS volume (mount point: ${mount_point:-none}, fs: ${fs_type:-none})"
}
