function nono-unpin --description "un-pin the nono profile pinned to the current repo"
    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)
    test -n "$repo"; or return 0
    set -l kept
    for entry in $claude_profile_map
        string match -q -- "$repo=*" $entry
        or set -a kept $entry
    end
    set -U claude_profile_map $kept
    echo "nono: unpinned "(basename $repo)
end
