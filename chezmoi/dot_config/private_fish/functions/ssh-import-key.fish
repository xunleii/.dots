function ssh-import-key --description "Import SSH public key from URL or string"
    set -l target "authorized_keys"
    set -l key ""
    set -l email ""

    # Parse options
    set -l options (fish_opt -s t -l target --required-val)
    set -l options $options (fish_opt -s e -l email --required-val)
    if not argparse $options -- $argv
        return 1
    end

    if set -q _flag_target
        set target $_flag_target
    end

    if set -q _flag_email
        set email $_flag_email
    end

    set -l input $argv[1]

    if string match -q "http*" $input
        set key (curl -sL $input | head -n 1)
    else
        set key $input
    end

    if test -z "$key"
        echo "Error: No key provided or found at URL."
        return 1
    end

    set -l file ""
    if test "$target" = "allowed_signers"
        set file "$HOME/.ssh/allowed_signers"
        if test -z "$email"
            read -P "Email for allowed_signers: " email
        end
        set entry "$email $key"
    else
        set file "$HOME/.ssh/authorized_keys"
        set entry "$key"
    end

    # Ensure directory exists
    mkdir -p (dirname $file)
    
    # Check if key already exists to avoid duplicates
    if not grep -qF "$key" "$file" 2>/dev/null
        echo "$entry" >> "$file"
        echo "Successfully added key to $file"
        
        # If it's a chezmoi managed file, warn user
        if test -f "$HOME/.local/share/chezmoi/chezmoi/dot_ssh/"(basename $file)".tmpl"
            echo "Warning: This file is managed by chezmoi. You should update your chezmoi source to make it permanent."
        end
    else
        echo "Key already exists in $file"
    end
end
