# Mnemosyne — persistent memory via MCP

`mnemosyne` runs as a background LaunchAgent (`com.mnemosyne.mcp`, SSE on
:8788 — see `chezmoi/Library/LaunchAgents/com.mnemosyne.mcp.plist.tmpl`) and
is registered as an MCP server (check with `claude mcp get mnemosyne`). Use
it proactively but selectively — most tasks don't need it.

## Recall

Before relying on assumptions about existing project architecture,
conventions, past decisions, or user preferences, call `mnemosyne_recall` if
the answer might already be stored. Skip it for trivial tasks where memory
is unlikely to help.

## Remember

Call `mnemosyne_remember` for anything likely to matter in a future session:
user preferences, architectural decisions, project conventions, non-obvious
rationale, constraints, recurring workflows — facts that would otherwise
have to be rediscovered.

Do not store: temporary debugging state, routine implementation detail,
anything already obvious from the repo, secrets/credentials, large code
blocks.

Keep entries concise and self-contained; include the *why* when it matters.
When the user changes a stored preference or decision, store the update
rather than keep relying on the stale one.

## Session behavior

At session start, a `SessionStart` hook seeds context via `mnemosyne
recall` (see `~/.claude/settings.json`). Treat that as a starting point, not
a substitute for calling `mnemosyne_recall` mid-task when it's needed.

If the user explicitly says "remember this", always store it. Don't narrate
memory operations unless they're relevant to what's being discussed.
