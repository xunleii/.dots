# Single normalizer for "git remote URL -> host/user/repo". Callers apply their
# own final shaping on top: conf.d/40-environment.fish.tmpl (headroom's
# per-project URL), __claude_repo_slug (nono profile names), clone (target path
# under a Space).
#
# Run `__git_remote_slug --self-check` after editing the pipeline below.

function __git_remote_slug --description "git remote URL -> host/user/repo (no scheme, no user@, no .git)"
    if test "$argv[1]" = --self-check
        set -l cases \
            "git@github.com:xunleii/.dots.git|github.com/xunleii/.dots" \
            "https://github.com/user/repo.git|github.com/user/repo" \
            "https://github.com/User/Repo|github.com/user/repo" \
            "ssh://git@gitlab.example.com/grp/sub/repo.git|gitlab.example.com/grp/sub/repo" \
            "git@bitbucket.org:team/proj.git|bitbucket.org/team/proj"
        set -l failed 0
        for case in $cases
            set -l kv (string split '|' -- $case)
            set -l got (__git_remote_slug $kv[1])
            set -l st $status
            # Status matters as much as the value: `string` builtins exit 1
            # when they change nothing.
            if test "$got" = "$kv[2]" -a $st -eq 0
                echo "ok   $kv[1] -> $got"
            else
                echo "FAIL $kv[1] -> $got (status $st, want '$kv[2]' status 0)"
                set failed (math $failed + 1)
            end
        end
        test $failed -eq 0; and echo "self-check: all good"
        return $failed
    end

    set -l url $argv[1]
    if test -z "$url"
        set url (command git remote get-url origin 2>/dev/null)
        or set url (command git remote get-url (command git remote 2>/dev/null)[1] 2>/dev/null)
    end
    test -n "$url"; or return 1

    # https://host/user/repo.git, ssh://git@host/user/repo.git and
    # git@host:user/repo.git all collapse to the same host/user/repo.
    #
    # Captured into a variable rather than left as the function's last command:
    # every `string` builtin exits 1 when it matches nothing, so an
    # already-lowercase URL would make `string lower` — and this whole
    # function — report failure.
    set -l slug (string replace -r '\.git$' '' -- $url \
        | string replace -r '^\w+://' '' \
        | string replace -r '^[^@/]+@' '' \
        | string replace -ra '[:/]+' '/' \
        | string trim -c / \
        | string lower)

    test -n "$slug"; or return 1
    echo $slug
end
