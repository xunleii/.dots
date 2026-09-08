function __claude_repo_slug --description "repo -> repo-<host-user-name> from the git remote"
    set -l slug (__git_remote_slug)
    or return 1

    # nono profile names must be alphanumeric-with-hyphens only, so every
    # separator the slug still carries (the `/`s, host dots, dotfile repos like
    # ".dots", …) becomes a hyphen too — then runs of hyphens collapse so the
    # name stays readable: github.com/user/.dots -> repo-github-com-user-dots
    echo repo-(string replace -ra '[^a-zA-Z0-9-]' '-' -- $slug \
        | string replace -ra -- '-+' '-' \
        | string trim -c -)
end
