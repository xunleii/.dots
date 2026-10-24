function __claude_default_profile --description "print \$claude_default_profile, seeding it (or migrating a legacy '*' pin) on first use"
    if not set -q claude_default_profile[1]
        set -l legacy
        set -l kept
        for entry in $claude_profile_map
            if string match -q '\*=*' -- $entry
                set legacy (string split -m1 = -- $entry)[2]
            else
                set -a kept $entry
            end
        end
        set -U claude_profile_map $kept
        set -U claude_default_profile (test -n "$legacy"; and echo $legacy; or echo claude-code)
    end
    echo $claude_default_profile
end
