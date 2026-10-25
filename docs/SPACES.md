# Machine layout: Spaces and Runtimes

This setup is macOS-only and keeps everything that isn't config on two volumes
of their own — an external drive where the machine allows it (Mac Mini, Mac
Studio), a dedicated APFS volume on the internal disk otherwise (MacBook). See
[the README](../README.md#two-volumes) for how to create them.

Both are declared once in the `[vars]` table of
[`config.toml`](../config.toml) (base; exported as `MISE_VAR_*` via `[env]`) and read
from there by every template and script that needs them — never hardcode either path again.

| Volume | Var | Holds |
| --- | --- | --- |
| `/Volumes/Runtimes` | `runtimes_root` | every language toolchain, cache and package dir (mise, npm, Go, Cargo, pip/uv) |
| `/Volumes/Spaces` | `spaces_root` | all working copies, grouped by Space |

`mise bootstrap` fails on macOS when either volume is missing — see
[`config.macos.toml`](../config.macos.toml), the `dots:check:volumes` task run as the `pre-packages` hook. An
unmounted volume is transient; mount it and re-run, everything pointing at it
recovers on its own.

## Spaces

A Space is a *context*, not a project type: it answers "which hat am I wearing
in this directory". That's what makes a per-Space git identity meaningful.

| Space | For |
| --- | --- |
| `Lab` | throwaway work — POCs, spikes, reproductions, anything expected to be deleted |
| `Work` | Radio France repos |
| `OSS` | open source: public repos, forks, upstream contributions |
| `Personal` | personal projects that aren't public, including `PKM.garden` (notes / knowledge base) |

### Layout inside a Space

Repos are laid out by origin, so two repos with the same name never collide and
the path tells you where a checkout came from:

```
/Volumes/Spaces/<Space>/<host>/<user>/<repo>
/Volumes/Spaces/OSS/github.com/xunleii/.dots
```

The `clone` fish function does this for you. Run it from inside a Space and
give it any remote URL form (`https://`, `ssh://`, `git@host:user/repo`):

```fish
cd /Volumes/Spaces/OSS
clone git@github.com:xunleii/.dots.git   # -> /Volumes/Spaces/OSS/github.com/xunleii/.dots, then cd's in
```

It refuses to run outside a known Space — that guard is the whole point, since
the Space is what decides the target path.

### No per-Space git identity

Work and personal each have their own machine, so `user.email` is settled once
per machine from the plain `git_email` var (default in `conf.d/git/mise.toml`, overridden in a machine file under `conf.d/machines/`). `conf.d/git/home/.gitconfig.tera` deliberately emits no
`includeIf "gitdir:"` blocks — Spaces are about *where things live*, not about
who you are while editing them.

## Adding or renaming a Space

One edit, one apply:

1. Add the name to `spaces` (space-separated) in the `[vars]` table of `config.toml`.
2. `mise dot apply` — fish's `$SPACES` follows (the `fish` module renders `40-environment`).
3. `mkdir /Volumes/Spaces/<Name>`.

Consumers of that list today: `conf.d/fish/home/.config/fish/conf.d/40-environment.fish.tera` (exports
`$SPACES_ROOT` and `$SPACES`) and `clone.fish` in the `git` module (via those variables).
