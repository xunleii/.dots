function __claude_unpin --description "remove a repo's entry from \$claude_profile_map" --argument-names key
    set -l kept
    for entry in $claude_profile_map
        string match -q -- "$key=*" $entry
        or set -a kept $entry
    end
    set -U claude_profile_map $kept
end
