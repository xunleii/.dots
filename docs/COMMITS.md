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
yet. The one exception is `modules:<name>` (below): any existing `conf.d/`
folder is valid without being listed here.

`fish`, `nono`, `brew`, `git`, `mise`,
`ghostty`, `lazygit`, `atuin`, `starship`, `zed`, `ssh`, `macOS`,
`docs`, `claude`

`modules:<name>` (`<name>` = a `conf.d/` folder: `claude`, `dev`, `fish`, `git`,
`nix`, `ssh`) is for changes that belong to one module as a whole (its
`mise.toml`, `mise-tasks`, `scripts`, dotfile groups). A change to a tool's own
config file keeps the tool scope (`fish`, `git`, ...). `mise` is for base
plumbing (`config.toml`, `config.macos.toml`, `miserc.toml`, `tasks/`,
`scripts/`). Machine files (`conf.d/machines/mise.<name>.toml`) use the scope of
the tool they configure.

## Examples

```
+[fish]: Add nono-profile picker
!(nono): fix cwd read/write on sandboxed claude
```

should now be written:

```
+[fish]: Add nono-profile picker
![nono]: Fix cwd read/write on sandboxed claude
+[modules:nix]: Add the /nix volume check
~[modules:git]: Keep the signing key out of the repo
```
