#                                       __
#                                     /\\ \
#                                   /\\ \\ \\
#                                   \// // //
#                                     \//_/
#
#                                   . d o t s
#                          Fish - Prompt lag logger
#
# -----------------------------------------------------------------------------


# --- Slow prompt diagnostics
# -----------------------------------------------------------------------------
# When the prompt takes more than $prompt_lag_threshold ms (default 500) to come
# back after a command ends, append a report to ~/.local/share/fish/prompt-lag.log.
# Timeline: command end (preexec + CMD_DURATION) -> our fish_postexec handler ->
# fish_prompt event (mise hook-env runs there) -> left prompt -> right prompt.
# Loaded after 20-prompt.fish so the starship prompt functions exist to wrap.
# ponytail: log grows unbounded, truncate it by hand (or add rotation if it gets big).
status is-interactive; or return
command -sq gdate; or return # BSD date has no milliseconds

set -q prompt_lag_threshold; or set -g prompt_lag_threshold 500
set -g __prompt_lag_log $XDG_DATA_HOME/fish/prompt-lag.log

function __prompt_lag_preexec --on-event fish_preexec
    set -g __prompt_lag_cmd $argv[1]
    set -g __prompt_lag_pre (gdate +%s%3N)
end

function __prompt_lag_postexec --on-event fish_postexec
    set -g __prompt_lag_status $pipestatus
    set -g __prompt_lag_post (gdate +%s%3N)
end

function __prompt_lag_prompt_event --on-event fish_prompt
    set -q __prompt_lag_post; and set -g __prompt_lag_prompt (gdate +%s%3N)
end

# Wrappers call the original first, so starship still sees the real $status.
if functions -q fish_prompt
    functions -c fish_prompt __prompt_lag_orig_left
    function fish_prompt
        __prompt_lag_orig_left $argv
        set -q __prompt_lag_post; and set -g __prompt_lag_left (gdate +%s%3N)
    end
end

if functions -q fish_right_prompt
    functions -c fish_right_prompt __prompt_lag_orig_right
    function fish_right_prompt
        __prompt_lag_orig_right $argv
        __prompt_lag_report
    end
else
    function fish_right_prompt
        __prompt_lag_report
    end
end

function __prompt_lag_report
    set -q __prompt_lag_post __prompt_lag_pre; or return
    set -l now (gdate +%s%3N)
    set -l cmd_end (math -s0 $__prompt_lag_pre + $CMD_DURATION)
    set -l total (math -s0 $now - $cmd_end)
    set -l post $__prompt_lag_post
    set -l prompt $__prompt_lag_prompt
    set -l left $__prompt_lag_left
    set -e __prompt_lag_pre __prompt_lag_post __prompt_lag_prompt __prompt_lag_left
    test $total -ge $prompt_lag_threshold; or return

    test -n "$prompt"; or set prompt $post
    test -n "$left"; or set left $prompt
    set -l id (gdate +%Y%m%d-%H%M%S)-$fish_pid
    begin
        echo "=== $id  total=$total"ms"  pwd=$PWD"
        echo "cmd: $__prompt_lag_cmd  (status $__prompt_lag_status, ran "$CMD_DURATION"ms)"
        echo "split: cmd_end->postexec="(math $post - $cmd_end)"ms" \
            "postexec->prompt_event="(math $prompt - $post)"ms" \
            "left_prompt="(math $left - $prompt)"ms" \
            "right_prompt="(math $now - $left)"ms"
        echo "load: "(sysctl -n vm.loadavg)"  jobs: "(jobs | count)"  fs: "(df -P . 2>/dev/null | tail -1)
        echo "git: "(command git rev-parse --show-toplevel 2>/dev/null; or echo none)
        echo "handlers:"
        functions --handlers-type generic | string match -r '^fish_(?:pre|post)exec .*|^fish_prompt .*' | string replace -r '^' '  '
        functions --handlers-type variable | string match -r '^PWD .*' | string replace -r '^' '  '
    end >>$__prompt_lag_log 2>&1

    # Re-time the usual suspects in the background, same dir and env (appended under the id).
    command sh -c '
        cd "$1" || exit
        {
            echo "--- $2 replay"
            s=$(gdate +%s%3N); mise hook-env -s fish >/dev/null 2>&1
            echo "mise hook-env: $(( $(gdate +%s%3N) - s ))ms"
            echo "starship timings:"; starship timings 2>&1 | sed "s/^/  /"
        } >>"$3" 2>&1
    ' sh $PWD $id $__prompt_lag_log &
    disown 2>/dev/null
end
