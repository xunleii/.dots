function bwssh --description "ssh via the Bitwarden SSH agent, forced for this command only"
    __bw_exec ssh $argv
end
