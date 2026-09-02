# $claude_profile_map — universal list of `PATH=PROFILE` entries mapping a repo
# root to a nono profile, plus one optional `*=PROFILE` global default. The
# picker writes it; inspect / edit by hand with `set -U claude_profile_map`.

function __claude_profile_for --description "resolve a repo path to a pinned nono profile" --argument-names repo
    set -l fallback
    for entry in $claude_profile_map
        set -l kv (string split -m1 = -- $entry)
        if test "$kv[1]" = "$repo"
            echo $kv[2]
            return 0
        else if test "$kv[1]" = '*'
            set fallback $kv[2]
        end
    end
    test -n "$fallback"
    and echo $fallback
end

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

function __claude_pin --description "upsert an entry in \$claude_profile_map" --argument-names key val
    set -l kept
    for entry in $claude_profile_map
        string match -q -- "$key=*" $entry
        or set -a kept $entry
    end
    set -U claude_profile_map $kept "$key=$val"
end

function __claude_repo_full --description "repo -> host/user/name from the git remote, for display"
    set -l url (command git remote get-url origin 2>/dev/null)
    or set url (command git remote get-url (command git remote 2>/dev/null)[1] 2>/dev/null)
    test -n "$url"; or return 1
    string replace -r '\.git$' '' -- $url \
        | string replace -r '^\w+://' '' \
        | string replace -r '^[^@/]+@' '' \
        | string replace -r ':' '/' \
        | string trim -c /
end

function __claude_clack_select --description "clack-style radio select (fzf, precomputed frames — no per-key subprocess)" --argument-names title
    set -e argv[1]
    set -l items $argv
    set -l n (count $items)
    test $n -eq 0; and return 1

    begin
        set_color cyan; echo -n '◆  '; set_color normal; echo "$title"
    end >&2

    if not command -sq fzf
        for i in (seq $n)
            begin
                set_color -d; echo -n '│  '; set_color normal
                echo "$i) $items[$i]"
            end >&2
        end
        read -l -P '   ❯ ' idx
        test -z "$idx"; and return 1
        echo $items[$idx]
        return 0
    end

    # One frame per index, precomputed up front so `focus:reload` only ever
    # has to `cat` a tiny static file — no fish/config startup per keystroke.
    # The │ bar is drawn by fzf's own --pointer/--gutter column (flush against
    # the left edge) rather than embedded in the candidate text, so there's no
    # margin between it and the terminal edge.
    set -l tmp (mktemp -d)
    for i in (seq $n)
        set -l lines
        for j in (seq $n)
            if test $j -eq $i
                set -a lines (set_color cyan)"● $items[$j]"(set_color normal)
            else
                set -a lines (set_color -d)"○ $items[$j]"(set_color normal)
            end
        end
        printf '%s\n' $lines >$tmp/(math $i - 1)
    end

    set -l choice (cat $tmp/0 | fzf --ansi --height $n --layout reverse \
        --no-input --info hidden \
        --pointer '│' --gutter '│' --color 'pointer:8,gutter:8' \
        --bind "focus:reload(cat $tmp/{n})" \
        | string replace -r '^[●○] ' '')
    rm -rf $tmp
    # fzf clears its own list on exit but leaves our title line above it;
    # erase that too so the caller's own summary (if any) is the only trace
    # left, instead of stacking under a stale "◆ …" line.
    printf '\033[1A\033[G\033[2K' >&2
    test -z "$choice"; and return 1
    echo $choice
end

function claude --description "Launch Claude Code in the nono sandbox, per-repo profile aware"
    # No nono, or --raw → run the real binary untouched.
    if not command -sq nono; or contains -- --raw $argv
        command claude (string match -v -- --raw $argv)
        return
    end

    argparse -i pick p/profile= -- $argv
    or return 1

    set -l repo (command git rev-parse --show-toplevel 2>/dev/null)

    # --- Resolve profile: -p flag > map (repo entry, then `*`) > picker > default
    set -l profile
    if set -q _flag_profile
        set profile $_flag_profile
    else if not set -q _flag_pick
        set profile (__claude_profile_for "$repo")
    end

    if test -z "$profile"; and status is-interactive
        set -l slug (test -n "$repo"; and __claude_repo_slug)
        set -l menu (nono profile list 2>/dev/null | string match -rg '^\s{4}(\S+)\s')
        test -n "$slug"; and set menu $menu "new: $slug"

        set -l header (test -n "$repo"; and echo (basename $repo); or echo "no repo")
        set_color -d; echo "┌  Choix du profil nono (sandbox)" >&2; set_color normal

        set -l choice (__claude_clack_select "Profil ($header)" $menu)
        test -z "$choice"; and return 1
        begin
            set_color green; echo -n '◇  '; set_color normal; echo "Profil ($header)"
            set_color -d; echo "│  $choice"; set_color normal
        end >&2

        # "new: …" → scaffold a repo profile that extends the base claude profile.
        if string match -q 'new: *' -- $choice
            set choice $slug
            set -l file ~/.config/nono/profiles/$choice.json
            if not test -f $file
                printf '%s\n' '{' \
                    '  "extends": "claude",' \
                    '  "meta": { "name": "'$choice'", "description": "Local sandbox overrides for '(basename $repo)'" },' \
                    '  "filesystem": { "read": [], "allow": [] },' \
                    '  "network": { "allow_domain": [] }' \
                    '}' >$file
                echo "nono: created $file — add repo grants there" >&2
            end
        end

        # Offer to pin the choice: this repo, globally, or not at all.
        if test -n "$repo"
            set -l repo_label (__claude_repo_full)
            test -z "$repo_label"; and set repo_label (basename $repo)
            set -l ans (__claude_clack_select "Se souvenir de ce choix pour $repo_label ?" repo global "ne pas se souvenir")
            switch "$ans"
                case repo
                    __claude_pin "$repo" $choice
                case global
                    __claude_pin '*' $choice
            end
        else
            set -l ans (__claude_clack_select "Ne plus demander le choix du profil la prochaine fois ?" Yes No)
            test "$ans" = Yes; and __claude_pin '*' $choice
        end
        set_color -d; echo '└' >&2; set_color normal
        set profile $choice
    end

    test -z "$profile"; and set profile claude

    set_color -d
    echo "nono → $profile"(test -n "$repo"; and echo "  ["(basename $repo)"]")
    set_color normal
    command nono run --profile $profile --allow-cwd -- claude $argv
end
