# nono sandbox — prefer `clawd`

Sessions run inside a nono sandbox (Landlock/Seatbelt). When a Bash command is denied and the
built-in nono-sandbox skill's quick fix would normally be `nono run --allow <path> -- claude`,
prefer `clawd` instead — it's the user's own fish function (`xunleii/dots` chezmoi repo,
`functions/clawd.fish`) wrapping `nono run --profile <per-repo profile> --allow-cwd -- claude`.

`clawd` has **no direct `--allow <path>` flag**. The equivalent is:

```
clawd --nono '--allow <path>'
```

(`--nono`'s value is split on spaces and forwarded as-is to `nono run`, so multiple `--allow`
flags fit in one string: `clawd --nono '--allow ~/.toolhive --allow ~/.claude.json'`.)

Other flags (stripped before reaching `claude`; anything else passes straight through):
- `-h, --help` — usage.
- `--raw` — bypass the sandbox entirely (`command claude $argv`).
- `--onboard` — onboard a project: pick/create its nono profile (fzf menu over
  `nono-profile --use/--new`), then hand off to claude with a prompt that reports what's
  already configured vs. still missing and only acts on the gaps (MCP servers grouped by
  concern, Serena for code repos plus its project onboarding, `AGENTS.local.md`,
  `.claude/settings.local.json`). Was named `--init` before it grew the profile step.

Guidance:
- Before suggesting a `clawd` invocation, run `clawd --help` to reconfirm current syntax — it
  may change; don't rely solely on the summary above if it looks stale.
- If `clawd` isn't available (non-interactive/non-fish context, or `--help` fails), fall back to
  the raw `nono run --allow <path> -- claude` form.
- The persistent-fix path (drafting/promoting a nono profile under
  `~/.config/nono/profile-drafts/`) is unaffected — `clawd` only replaces the session-relaunch
  quick fix, not profile authoring.
