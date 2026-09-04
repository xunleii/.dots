function __claude_repo_slug --description "repo -> repo-<host-user-name> from the git remote"
    set -l url (command git remote get-url origin 2>/dev/null)
    or set url (command git remote get-url (command git remote 2>/dev/null)[1] 2>/dev/null)
    test -n "$url"; or return 1
    # Same normalization as conf.d/40-environment.fish.tmpl: strip .git + scheme +
    # user@, collapse :/ to -, lowercase -> github.com-user-name. nono profile
    # names must be alphanumeric-with-hyphens only, so anything else (host
    # dots, dotfile repos like ".dots", …) becomes a hyphen too, not just the
    # :/ separators — collapse the resulting runs so it stays readable.
    echo repo-(string replace -r '\.git$' '' -- $url \
        | string replace -r '^\w+://' '' \
        | string replace -r '^[^@/]+@' '' \
        | string replace -ra '[:/]+' '-' \
        | string replace -ra '[^a-zA-Z0-9-]' '-' \
        | string replace -ra -- '-+' '-' \
        | string lower | string trim -c -)
end
