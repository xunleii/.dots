function nono-profile --description "inspect or change the nono sandbox profile for the current repo"
    argparse 'use=' 'default' 'new=' 'from=' -- $argv
    or return 1

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
