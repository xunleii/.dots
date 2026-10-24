#                                       __
#                                     /\\ \
#                                   /\\ \\ \\
#                                   \// // //
#                                     \//_/
#
#                                   . d o t s
#                            Fish - Custom Functions
#
# -----------------------------------------------------------------------------


# --- Banner
# -----------------------------------------------------------------------------
# `dots-banner` is deployed from scripts/banner.sh (see config.toml). Same argument
# order as the former banner: TITLE SUBTITLE.
if command -sq dots-banner
  function dots_banner --description "Generate personal file header"
    dots-banner $argv[2] $argv[1]
  end
end

abbr --add --global banner dots_banner
