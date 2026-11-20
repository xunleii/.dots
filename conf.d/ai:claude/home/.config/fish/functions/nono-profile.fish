function nono-profile --description "inspect or change the nono sandbox profile for the current repo"
    argparse 'h/help' 'use=' 'default' 'new=' 'from=' 'rm=' -- $argv
    or return 1

    if set -q _flag_help
        printf '%s\n' \
            'nono-profile — inspect or change the nono sandbox profile pinned to the current repo' \
            '' \
            'Usage: nono-profile [FLAG]' \
            '' \
            '  (no flags)         show the current repo'"'"'s resolved profile (pinned or default) and why' \
            '  --use NAME         pin an existing profile to this repo' \
            '  --new NAME [--from BASE]' \
            '                     scaffold a profile (extends BASE, default: the default profile)' \
            '                     and pin it to this repo' \
            '  --default          unpin this repo, fall back to $claude_default_profile' \
            '  --rm NAME          delete a profile (unpins any repo using it)' \
            '  -h, --help         show this help and exit' \
            '' \
            'Examples:' \
            '  nono-profile' \
            '  nono-profile --use claude-restricted' \
            '  nono-profile --new my-project --from claude' \
            '  nono-profile --default' \
            '  nono-profile --rm my-project'
        return 0
    end

    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)

    # --new NAME [--from FROM]: scaffold a profile and pin it to this repo.
    if set -q _flag_new
        set -l name $_flag_new
        set -l from (__claude_default_profile)
        set -q _flag_from; and set from $_flag_from

        set -l file ~/.config/nono/profiles/$name.json
        if test -f $file
            echo "nono-profile: $file already exists, reusing" >&2
        else
            mkdir -p (dirname $file)
            printf '%s\n' '{' \
                '  "extends": "'$from'",' \
                '  "meta": { "name": "'$name'", "description": "Local sandbox overrides" },' \
                '  "filesystem": { "read": [], "allow": [] },' \
                '  "network": { "allow_domain": [] }' \
                '}' >$file
            echo "nono-profile: created $file (extends $from)" >&2
        end
        if test -n "$repo"
            __claude_pin "$repo" $name
            echo "nono-profile: "(basename $repo)" → $name"
        end
        return 0
    end

    # --rm NAME: delete a profile, unpinning any repo that uses it.
    if set -q _flag_rm
        set -l name $_flag_rm
        set -l file ~/.config/nono/profiles/$name.json
        if not test -f $file
            if nono profile list 2>/dev/null | string match -qr "^\s+$name\s"
                echo "nono-profile: $name is a built-in or package profile, not a user profile — refusing to delete" >&2
            else
                echo "nono-profile: $file does not exist" >&2
            end
            return 1
        end
        if test "$name" = (__claude_default_profile)
            echo "nono-profile: $name is the default profile, set another default first (nono-profile --default after pinning elsewhere, or edit \$claude_default_profile)" >&2
            return 1
        end
        set -l dependents
        for other in ~/.config/nono/profiles/*.json
            test (basename $other) = "$name.json"; and continue
            grep -q '"extends"[[:space:]]*:[[:space:]]*"'$name'"' $other 2>/dev/null
            and set -a dependents (basename $other .json)
        end
        if test -n "$dependents"
            echo "nono-profile: $name is extended by: $dependents — delete or repoint those first" >&2
            return 1
        end
        set -l unpinned
        for entry in $claude_profile_map
            set -l kv (string split -m1 = -- $entry)
            if test "$kv[2]" = "$name"
                __claude_unpin "$kv[1]"
                set -a unpinned (basename $kv[1])
            end
        end
        rm $file
        if test -n "$unpinned"
            echo "nono-profile: unpinned $unpinned (was using $name)"
        end
        echo "nono-profile: removed $file"
        return 0
    end

    # --use NAME: pin an existing profile to this repo.
    if set -q _flag_use
        if test -z "$repo"
            echo "nono-profile: not inside a git repo" >&2
            return 1
        end
        __claude_pin "$repo" $_flag_use
        echo "nono-profile: "(basename $repo)" → $_flag_use"
        return 0
    end

    # --default: unpin this repo, fall back to \$claude_default_profile.
    if set -q _flag_default
        if test -z "$repo"
            echo "nono-profile: not inside a git repo" >&2
            return 1
        end
        __claude_unpin "$repo"
        echo "nono-profile: "(basename $repo)" → "(__claude_default_profile)" (default)"
        return 0
    end

    # No flags: show current resolution + why.
    set -l default (__claude_default_profile)
    if test -z "$repo"
        echo "nono-profile: no repo — default profile: $default"
        return 0
    end
    set -l pinned (__claude_profile_for "$repo")
    if test -n "$pinned"
        echo (basename $repo)" → $pinned (pinned)"
    else
        echo (basename $repo)" → $default (default, not pinned)"
    end
end
