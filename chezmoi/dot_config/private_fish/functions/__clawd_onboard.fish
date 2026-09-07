function __clawd_onboard --description "clawd --onboard: pick/create this project's nono profile, then hand off to claude for MCPs/Serena/local config"
    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)
    set -l in_repo 1
    if test -z "$repo"
        read -l -P "clawd --onboard: not inside a git repo — configure $PWD anyway? [y/N] " confirm
        string match -qri '^y' -- $confirm
        or return 1
        set repo $PWD
        set in_repo 0
    end

    pushd $repo

    # Step 1: nono profile — pick or create one, pinned via `nono-profile` (see
    # nono-profile.fish for --use/--new/--default; this only adds the picker).
    if test $in_repo -eq 1
        set -l pinned (__claude_profile_for "$repo")
        set -l default (__claude_default_profile)
        set -l slug (__claude_repo_slug 2>/dev/null)
        set -l suggested $pinned $default
        test -n "$slug"; and set -a suggested $slug
        set suggested (printf '%s\n' $suggested | string match -v '' | sort -u)

        set -l pick (printf '%s\n' $suggested '‹ new profile ›' '‹ list all profiles ›' \
            | fzf --prompt="nono profile for "(basename $repo)"> " --height='~40%' \
            --header="currently: "(test -n "$pinned"; and echo "$pinned (pinned)"; or echo "$default (default, not pinned)"))

        if test "$pick" = '‹ list all profiles ›'
            set pick (__claude_profile_list | fzf --prompt="nono profile> ")
        end

        if test "$pick" = '‹ new profile ›'
            read -l -P "New profile name [$slug]: " name
            test -z "$name"; and set name $slug
            test -n "$name"; and nono-profile --new $name
        else if test -n "$pick"
            nono-profile --use $pick
        end
    else
        echo "clawd --onboard: not in a git repo, skipping profile pinning (using "(__claude_default_profile)")"
    end

    # Step 2/3: gather what's already there so the prompt reports status instead
    # of re-asking / recreating blindly, then delegate the actual analysis
    # (MCP proposals, Serena, local files) to claude — it can inspect the
    # project, this fish function can't usefully judge "does this need an MCP".
    set -l facts
    test -f AGENTS.local.md; and set -a facts "AGENTS.local.md: present" ; or set -a facts "AGENTS.local.md: missing"
    test -f .claude/settings.local.json; and set -a facts ".claude/settings.local.json: present" ; or set -a facts ".claude/settings.local.json: missing"
    test -d .serena; and set -a facts ".serena/: present (Serena already set up)" ; or set -a facts ".serena/: missing"
    set -l mcp_list (command claude mcp list 2>/dev/null)
    test -z "$mcp_list"; and set mcp_list "(none configured)"

    # Built with `string join \n ... | string collect`, not adjacent
    # quoted-string/command-substitution concatenation: an embedded
    # multi-element list (facts, mcp_list) re-splits on every newline when
    # merely interpolated, silently fanning $prompt out into several
    # arguments instead of one — string collect is what pins it to one.
    set -l prompt (string join \n \
        "Onboard this project's local Claude Code setup. Everything you create/add here is per-developer and must never be committed." \
        "" \
        "Detected before you started:" \
        $facts \
        "Existing MCP servers (claude mcp list):" \
        $mcp_list \
        "" \
        "Start your reply with a short status list: what's already configured vs. what's still missing. Only act on what's missing — don't recreate or re-propose what's already there unless it looks broken." \
        "" \
        "1. Inspect the project (language, frameworks, tooling) and propose the MCP servers relevant to it, local scope only (\`claude mcp add\` defaults to local — don't use --scope project). If there are several candidates, group them (e.g. by concern: code nav, infra, docs) and ask which to enable rather than adding them all." \
        "2. If the project has actual source code and Serena isn't set up yet, offer to add the Serena MCP server (https://github.com/oraios/serena, local scope — check its README for the current add command) and, once added, run its project onboarding." \
        "3. If missing, create AGENTS.local.md at the repo root: project-specific agent instructions, complementing (not duplicating) any existing AGENTS.md/CLAUDE.md." \
        "4. If missing, create .claude/settings.local.json with sensible project-local settings." \
        "Explain each MCP server you add in one line. Ask before anything destructive." \
        | string collect)

    if test (count $argv) -gt 0
        set prompt (string join \n $prompt "" "Additional instructions from the user: $argv" | string collect)
    end

    clawd $prompt
    popd
end
