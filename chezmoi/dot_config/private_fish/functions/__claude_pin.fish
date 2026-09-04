function __claude_pin --description "upsert an entry in \$claude_profile_map" --argument-names key val
    set -l kept
    for entry in $claude_profile_map
        string match -q -- "$key=*" $entry
        or set -a kept $entry
    end
    set -U claude_profile_map $kept "$key=$val"
end
