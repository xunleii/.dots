# `claude` is left untouched (real binary, no sandbox). `clawd` = claude,
# sandboxed: nono profile per repo (see __claude_profile_for/__claude_pin,
# managed by `nono-profile`), plus the extras below.
#
# Flags clawd understands, all optional and stripped before reaching claude:
#   --raw            skip the sandbox entirely (plain `command claude $argv`)
#   --nono 'FLAGS'    extra flags forwarded to `nono run`, e.g.
#                     clawd --nono '--allow ~/.toolhive'
#   --init           bootstrap this project's local Claude config, see
#                     __clawd_init
#
# Logic lives in __clawd_run (sandbox launch) and __clawd_init (--init), kept
# separate so each stays a one-screen, one-job function.

function clawd --description "Launch Claude Code in the nono sandbox, per-repo profile aware"
    if not command -sq nono; or contains -- --raw $argv
        command claude (string match -v -- --raw $argv)
        return
    end

    if contains -- --init $argv
        __clawd_init (string match -v -- --init $argv)
        return
    end

    __clawd_run $argv
end
