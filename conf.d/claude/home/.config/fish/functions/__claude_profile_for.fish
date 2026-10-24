function __claude_profile_for --description "resolve a repo path to its pinned nono profile, if any" --argument-names repo
    test -n "$repo"; or return 1
    for entry in $claude_profile_map
        set -l kv (string split -m1 = -- $entry)
        if test "$kv[1]" = "$repo"
            echo $kv[2]
            return 0
        end
    end
    return 1
end
