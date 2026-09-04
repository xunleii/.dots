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

    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)
    set -l profile (test -n "$repo"; and __claude_profile_for "$repo")
    test -z "$profile"; and set profile (__claude_default_profile)

    set_color -d
    echo "nono → $profile"(test -n "$repo"; and echo "  ["(basename $repo)"]")
    set_color normal
    command nono run --profile $profile --allow-cwd -- claude $argv
end
