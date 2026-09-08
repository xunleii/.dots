function __bw_ssh_sock --description "print the active Bitwarden SSH agent socket path, or error if none found"
    set -l bw_ssh_socket ~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock
    set -l bw_legacy_socket ~/.bitwarden-ssh-agent.sock

    if test -S "$bw_legacy_socket"
        echo "$bw_legacy_socket"
    else if test -S "$bw_ssh_socket"
        echo "$bw_ssh_socket"
    else
        echo "bwssh: no Bitwarden SSH agent socket found — open Bitwarden and unlock the vault (SSH agent must be enabled in its settings)" >&2
        return 1
    end
end
