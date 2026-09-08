function __bw_exec --description "run a command with \$SSH_AUTH_SOCK forced to the Bitwarden agent, for this invocation only"
    set -l sock (__bw_ssh_sock)
    or return 1
    env SSH_AUTH_SOCK="$sock" $argv
end
