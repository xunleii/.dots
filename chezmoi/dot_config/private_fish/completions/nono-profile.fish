complete -c nono-profile -f
complete -c nono-profile -s h -l help -d 'show usage and exit'
complete -c nono-profile -l use -d 'pin an existing profile to this repo' -x -a "(__claude_profile_list)"
complete -c nono-profile -l from -d 'base profile the new one extends' -x -a "(__claude_profile_list)"
complete -c nono-profile -l new -d 'create and pin a new profile for this repo' -x -a "(__claude_repo_slug 2>/dev/null)"
complete -c nono-profile -l default -d 'unpin this repo, fall back to the default profile'
