#!/bin/sh

# Print the personal file header. Usage: banner.sh "Subtitle" [Title]
# Shared file header (Title defaults to ".dots").
sub=${1:?usage: banner.sh SUBTITLE [TITLE]}
title=$(printf '%s' "${2:-.dots}" | sed 's/./& /g; s/ $//')
center() { printf '# %*s%s\n' $(( (77 - ${#1}) / 2 )) '' "$1"; }
cat <<'ART'
#                                       __
#                                     /\\ \
#                                   /\\ \\ \\
#                                   \// // //
#                                     \//_/
#
ART
center "$title"
center "$sub"
printf '#\n# -----------------------------------------------------------------------------\n'
