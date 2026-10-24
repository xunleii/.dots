#                                       __
#                                     /\\ \
#                                   /\\ \\ \\
#                                   \// // //
#                                     \//_/
#
#                                   . d o t s
#                           Fish - GNU userland (macOS only)
#
# -----------------------------------------------------------------------------
# Deployed by mise.macos.toml of the fish module, so it never exists elsewhere.

# --- GNU userland ahead of BSD (coreutils, findutils, sed, awk, grep)
# -----------------------------------------------------------------------------
# ponytail: deliberate — shadows BSD date/stat/sed/ls with GNU behaviour.
# If a script needs BSD semantics, call it as `/usr/bin/<tool>`.
for gnubin in coreutils findutils gnu-sed gawk grep
    set -l dir /opt/homebrew/opt/$gnubin/libexec/gnubin
    test -d $dir; and fish_add_path $dir
end
