function __claude_user_profile_list --description "list user-defined nono profile names (excludes built-in/pack), for completion"
    for f in ~/.config/nono/profiles/*.json
        test -e $f; and basename $f .json
    end
end
