function bwansible-playbook --description "ansible-playbook via the Bitwarden SSH agent, forced for this command only"
    __bw_exec ansible-playbook $argv
end
