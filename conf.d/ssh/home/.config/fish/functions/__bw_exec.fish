function __bw_exec --description "run a command with \$SSH_AUTH_SOCK forced to the Bitwarden agent, for this invocation only"
    if not command -q $argv[1]
        echo "$argv[1]: not installed, nothing to run" >&2
        return 127
    end
    set -l sock (__bw_ssh_sock)
    or return 1
    env SSH_AUTH_SOCK="$sock" $argv
end
