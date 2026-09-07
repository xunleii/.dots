# `claude` is left untouched (real binary, no sandbox). `clawd` = claude,
# sandboxed: nono profile per repo (see __claude_profile_for/__claude_pin,
# managed by `nono-profile`), plus the extras below.
#
# Flags clawd understands, all optional and stripped before reaching claude:
#   -h, --help       show usage and exit, no nono/claude launch
#   --raw            skip the sandbox entirely (plain `command claude $argv`)
#   --nono 'FLAGS'    extra flags forwarded to `nono run`, e.g.
#                     clawd --nono '--allow ~/.toolhive'
#   --onboard        set up this project (nono profile, MCPs, Serena), see
#                     __clawd_onboard
#
# Logic lives in __clawd_run (sandbox launch) and __clawd_onboard (--onboard),
# kept separate so each stays a one-screen, one-job function.

function clawd --description "Launch Claude Code in the nono sandbox, per-repo profile aware"
    if contains -- -h $argv; or contains -- --help $argv
        printf '%s\n' \
            'clawd — claude, sandboxed (nono run --profile <per-repo profile> --allow-cwd -- claude)' \
            '' \
            'Usage: clawd [FLAGS] [CLAUDE ARGS...]' \
            '' \
            'Flags (all optional, stripped before reaching claude):' \
            '  -h, --help        show this help and exit' \
            '  --raw             skip the sandbox entirely: `command claude $argv`' \
            '  --nono '"'"'FLAGS'"'"'    extra flags forwarded to `nono run`' \
            '                    e.g. clawd --nono '"'"'--allow ~/.toolhive'"'"'' \
            '  --onboard         set up this project: pick/create its nono profile,' \
            '                    propose MCP servers, offer Serena (with onboarding)' \
            '' \
            'Anything else is passed straight through to claude.' \
            '' \
            'Examples:' \
            '  clawd' \
            '  clawd --nono '"'"'--allow ~/.toolhive --allow ~/.claude.json'"'"'' \
            '  clawd --onboard'
        return 0
    end

    if not command -sq nono; or contains -- --raw $argv
        command claude (string match -v -- --raw $argv)
        return
    end

    if contains -- --onboard $argv
        __clawd_onboard (string match -v -- --onboard $argv)
        return
    end

    __clawd_run $argv
end
