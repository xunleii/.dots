function __clawd_run --description "clawd's default path: resolve the nono profile and launch claude under it"
    # --nono 'extra flags' → forwarded to `nono run` (e.g. --nono '--allow ~/.toolhive')
    # --rollback           → force nono's atomic rollback snapshots on (see `nono run --help`)
    set -l nono_flags
    set -l want_rollback 0
    set -l rest
    set -l i 1
    set -l n (count $argv)
    while test $i -le $n
        if test "$argv[$i]" = --nono
            set i (math $i + 1)
            test $i -le $n; and set nono_flags $argv[$i]
        else if test "$argv[$i]" = --rollback
            set want_rollback 1
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

    # No git repo → no version-control safety net, so fall back to nono's own
    # rollback snapshots unless the caller already asked for them explicitly.
    set -l rollback_banner
    if test -z "$repo"; or test $want_rollback -eq 1
        set -a extra --rollback
        set rollback_banner "  [rollback]"
    end

    # Plain variable interpolation, not `(command substitution)`: an empty/no-op
    # substitution has zero elements and silently voids the whole concatenated
    # echo argument (repo_banner/rollback_banner being unset would too, if
    # embedded that way) — a real bug this line used to have outside a repo.
    set -l repo_banner
    test -n "$repo"; and set repo_banner "  ["(basename $repo)"]"

    set_color -d
    echo "nono → $profile$repo_banner$rollback_banner"
    set_color normal
    command nono run --profile $profile --allow-cwd $extra -- claude $rest
end
