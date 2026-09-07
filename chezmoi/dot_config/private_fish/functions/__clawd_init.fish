function __clawd_init --description "clawd --init: bootstrap this project's local (never-committed) Claude config via a dedicated prompt"
    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)
    if test -z "$repo"
        read -l -P "clawd --init: not inside a git repo — configure $PWD anyway? [y/N] " confirm
        string match -qri '^y' -- $confirm
        or return 1
        set repo $PWD
    end

    set -l prompt "Bootstrap this project's local Claude Code setup. Everything you create here is per-developer and must never be committed (the global gitignore already covers the filenames below, but keep them local-scope regardless):
1. Inspect the project (language, frameworks, tooling) and add the MCP servers relevant to it, at local scope only (\`claude mcp add\` defaults to local scope — don't use --scope project).
2. If the project has actual source code (not just docs/config), also add the Serena MCP server (https://github.com/oraios/serena, local scope) for semantic code navigation — check its README for the current install/add command.
3. Create AGENTS.local.md at the repo root: project-specific agent instructions for what you found, complementing (not duplicating) any existing AGENTS.md/CLAUDE.md.
4. Create or update .claude/settings.local.json with sensible project-local settings.
Explain each MCP server you add in one line. Ask before anything destructive."
    test (count $argv) -gt 0; and set prompt "$prompt

Additional instructions from the user: $argv"

    pushd $repo
    clawd $prompt
    popd
end
