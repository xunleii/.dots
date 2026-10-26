#                                       __
#                                     /\\ \
#                                   /\\ \\ \\
#                                   \// // //
#                                     \//_/
#
#                                   . d o t s
#                           Fish - Nix environment
#
# -----------------------------------------------------------------------------
# Loads Nix (PATH, NIX_PROFILES, NIX_SSL_CERT_FILE...) once dots:setup:nix has installed it. The
# Determinate installer drops the same snippet in /opt/homebrew/etc/fish/conf.d/nix.fish; this one
# is the versioned copy and works without it. Guards:
#   - file missing: Nix not installed (this module is loaded on every machine), nothing to do
#   - __ETC_PROFILE_NIX_SOURCED set: nix-daemon.fish was already sourced (it is exported, so
#     child shells inherit it) and would `exit` at its first line
# -----------------------------------------------------------------------------

set -l nix_daemon_fish /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
if test -e $nix_daemon_fish; and not set -q __ETC_PROFILE_NIX_SOURCED
    source $nix_daemon_fish
end
