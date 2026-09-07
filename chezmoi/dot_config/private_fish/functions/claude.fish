# $claude_profile_map — list of `repo-root=profile` entries pinning a repo to
# a nono profile. $claude_default_profile is the fallback when a repo has no
# entry. Both are managed by `nono-profile`; inspect/edit by hand with
# `set -U claude_profile_map` / `set -U claude_default_profile` if needed.

function claude --description "Launch Claude Code in the nono sandbox, per-repo profile aware"
    # No nono, or --raw → run the real binary untouched.
    if not command -sq nono; or contains -- --raw $argv
        command claude (string match -v -- --raw $argv)
        return
    end

    # --nono 'extra flags' → forwarded to `nono run` (e.g. --nono '--allow ~/.toolhive')
    set -l nono_flags
    set -l rest
    set -l i 1
    set -l n (count $argv)
    while test $i -le $n
        if test "$argv[$i]" = --nono
            set i (math $i + 1)
            test $i -le $n; and set nono_flags $argv[$i]
        else
            set rest $rest $argv[$i]
        end
        set i (math $i + 1)
    end
    set -l extra
    test -n "$nono_flags"; and set extra (string split ' ' -- $nono_flags)

    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)
    set -l profile (test -n "$repo"; and __claude_profile_for "$repo")
    test -z "$profile"; and set profile (__claude_default_profile)

    set_color -d
    echo "nono → $profile"(test -n "$repo"; and echo "  ["(basename $repo)"]")
    set_color normal
    command nono run --profile $profile --allow-cwd $extra -- claude $rest
end
