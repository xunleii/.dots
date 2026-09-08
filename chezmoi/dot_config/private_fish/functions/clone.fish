# Clones into the Space you're standing in, at <host>/<user>/<repo> — the
# layout documented in docs/SPACES.md. $SPACES_ROOT / $SPACES come from
# conf.d/40-environment.fish.tmpl, which reads them from .chezmoidata.yaml, so
# nothing here hardcodes a path or a Space name.

function clone --description "git clone into the current Space, at <host>/<user>/<repo>"
    set -l url $argv[1]
    if test -z "$url"
        echo "Usage: clone <url>" >&2
        echo "Run it from inside a Space: "(printf '%s ' $SPACES_ROOT/$SPACES) >&2
        return 1
    end

    # Must be inside a known Space: that's what decides the target path, and
    # what picks up the Space's .gitconfig identity (see dot_gitconfig.tmpl).
    set -l rel (string replace -r '^'(string escape --style=regex $SPACES_ROOT)'/' '' -- $PWD)
    set -l space (string split -m1 / -- $rel)[1]
    if test "$rel" = "$PWD"; or not contains -- $space $SPACES
        echo (set_color red)"clone: not inside a Space"(set_color normal) >&2
        echo "cd into one of: "(printf '%s ' $SPACES_ROOT/$SPACES) >&2
        return 1
    end

    set -l slug (__git_remote_slug $url)
    or begin
        echo (set_color red)"clone: cannot parse '$url' as a git remote URL"(set_color normal) >&2
        return 1
    end

    set -l target "$SPACES_ROOT/$space/$slug"
    echo (set_color blue)"Space:       $space"(set_color normal)
    echo (set_color blue)"Destination: $target"(set_color normal)

    if mkdir -p (dirname $target); and git clone $url $target
        cd $target
    else
        return 1
    end
end
