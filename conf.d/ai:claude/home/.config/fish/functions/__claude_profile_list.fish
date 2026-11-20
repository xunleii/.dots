function __claude_profile_list --description "list all known nono profile names, for completion"
    command nono profile list 2>/dev/null | string match -rg '^\s{4}(\S+)\s'
end
