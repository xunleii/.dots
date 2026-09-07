# chezmoi cheat sheet

Condensed reference for the parts of [chezmoi's docs](https://www.chezmoi.io/reference/)
that matter when editing this repo, so an agent (or future me) doesn't have
to re-fetch the upstream docs each time.

Source root here is `chezmoi/` (see `.chezmoiroot`) — every path below is
relative to it, not the repo root.

## Source file naming (attributes)

chezmoi derives the target path and behavior from the source file name.
Prefixes/suffixes can be combined (e.g. `private_dot_ssh/private_config`).

| Attribute | Effect |
| --- | --- |
| `dot_` | leading `.` in target (`dot_gitconfig` → `.gitconfig`) |
| `private_` | target gets mode `0600`/`0700` |
| `executable_` | target gets the executable bit |
| `readonly_` | target gets the readonly bit |
| `symlink_` | file's *content* is the target of a symlink to create |
| `empty_` | keep the target even if content is empty (normally empty = not created) |
| `create_` | only create if it doesn't already exist; never overwrite |
| `modify_` | script that reads current content on stdin, writes new content on stdout |
| `remove_` | (in `.chezmoiremove` or as a file) remove the target on apply |
| `.tmpl` suffix | file is a Go template, rendered with `chezmoi.*` data |
| `run_` scripts | see below |
| `encrypted_` | content is encrypted (age/gpg), decrypted on apply |
| `literal_` | disables all attribute parsing for the rest of the name |

## Scripts (`run_*`)

- `run_` — runs every `chezmoi apply`.
- `run_once_` — runs once; re-runs if the script's *content* changes (hash
  tracked in chezmoi's state).
- `run_onchange_` — runs when the *rendered output* changes (typically a
  `.tmpl` script that embeds a hash of files it depends on — see
  `run_onchange_after_brew.sh.tmpl` for the pattern used here).
- `_before_` / `_after_` (infix) — ordering relative to the rest of apply,
  e.g. `run_once_before_`, `run_onchange_after_`.
- Numeric prefix (`run_once_10-foo.sh`) — sort order within the same phase.

## Special files/dirs (source root only)

| Path | Purpose |
| --- | --- |
| `.chezmoiroot` | points to the actual source dir (`chezmoi/` here) |
| `.chezmoi.toml.tmpl` | generates `~/.config/chezmoi/chezmoi.toml` (prompts, `data`) |
| `.chezmoiignore` | lines/patterns to skip; supports `{{ if }}` templating |
| `.chezmoiexternal.toml[.tmpl]` | declares files/archives/git-repos to fetch and place (see `.chezmoiexternal.toml.tmpl` for the OS/arch-branched pattern used here) |
| `.chezmoitemplates/` | partials includable from other templates via `template` |
| `.chezmoiversion` | minimum chezmoi version required |
| `.chezmoidata.{toml,yaml,json}` | static extra template data |

## Template data worth knowing

Available in any `.tmpl` (and in `.chezmoi.toml.tmpl`, `.chezmoiignore`,
`.chezmoiexternal.toml.tmpl`) as `.chezmoi.*`:

- `.chezmoi.os` — `darwin`, `linux`, `windows`
- `.chezmoi.arch` — `amd64`, `arm64`, ...
- `.chezmoi.hostname`, `.chezmoi.username`
- `.chezmoi.kernel.osrelease` — useful to detect WSL (contains `microsoft`)
- `.chezmoi.homeDir`

This repo's rule: branch inside one `.tmpl` on `.chezmoi.os`/`.chezmoi.arch`
rather than maintaining parallel per-OS files — see [AGENTS.md](../AGENTS.md)
and the examples listed there.

## Everyday commands

```bash
chezmoi diff                  # preview what apply would change
chezmoi apply                 # apply source state to $HOME
chezmoi add <path>             # import an existing file into the source state
chezmoi edit <path>            # open the source file for a target path
chezmoi source-path [path]     # source path for a target (or repo root if omitted)
chezmoi target-path <path>     # inverse of source-path
chezmoi cd                     # shell in the source dir
chezmoi execute-template '...' # render a template string against live data, for debugging
chezmoi data                   # dump all available template data as JSON
```

Full reference: <https://www.chezmoi.io/reference/>.
