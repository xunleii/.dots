function bwansible --description "ansible via the Bitwarden SSH agent, forced for this command only"
    __bw_exec ansible $argv
end
