# Commit message convention

Replaces the old gitmoji-shortcode style (`:sparkles:(fish): ...`) with a
symbol-based type, adapted from
[chezmoi.sh's ADR 010](https://github.com/xunleii/chezmoi.sh/blob/main/docs/decisions/010-replace-gitmoji-with-symbol-commit-types.md).

## Format

```
type[scope]: Subject
```

Breaking change (only `+`, `~`, `-` can break):

```
type![scope]: Subject
```

- `scope` is required, lower-case, comma-separated for multiple (`fish,mise`).
- `Subject` is sentence-case, no trailing period, ≤100 chars.
- Body/footer: free text, optional.

## Types

| Symbol | Meaning  | Use for                                             |
| ------ | -------- | ---------------------------------------------------- |
| `+`    | Add      | new tool, config, dotfile, initial setup              |
| `-`    | Remove   | delete config, dead file                              |
| `~`    | Improve  | tweak, perf, behavioral improvement (non-bug)         |
| `!`    | Fix      | repair broken behavior                                |
| `=`    | Refactor | no behavior change (style, reorg)                     |
| `^`    | Bump     | dependency/tool version change                        |
| `>`    | Move     | rename or relocate                                    |
| `<`    | Revert   | undo a previous commit                                |
| `@`    | Docs     | README, docs/, comments                               |
| `$`    | Security | secrets, permissions, sandbox policy                  |
| `?`    | Experiment | POC, investigation                                  |
| `*`    | Wildcard | doesn't fit any other type                            |
| `+!` `~!` `-!` | breaking variants | of Add / Improve / Remove             |

## Scopes

One per top-level dotfile/tool this repo manages. Add a new one here when a
new tool/dir shows up — don't pre-invent scopes for things that don't exist
yet.

`chezmoi`, `fish`, `nono`, `brew`, `git`, `mise`, `headroom`, `ghostty`,
`kitty`, `lazygit`, `atuin`, `starship`, `zed`, `opencode`, `macOS`, `ci`,
`docs`, `claude`

## Examples

```
+[fish]: Add nono-profile picker
!(nono): fix cwd read/write on sandboxed claude
```

should now be written:

```
+[fish]: Add nono-profile picker
![nono]: Fix cwd read/write on sandboxed claude
```
