#                                       __
#                                     /\\ \
#                                   /\\ \\ \\
#                                   \// // //
#                                     \//_/
#
#                                   . d o t s
#                           Fish - Base Configuration
#
# -----------------------------------------------------------------------------


# --- XDG Base Directory Specification
# -----------------------------------------------------------------------------
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

# --- Path Configuration
# -----------------------------------------------------------------------------
fish_add_path $HOME/.local/bin
