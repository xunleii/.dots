function clone
    set -l url $argv[1]
    if test -z "$url"
        echo "Usage: clone <url>"
        return 1
    end

    # 1. Strict check: must be inside /Volumes/Spaces/<something>
    if not string match -q "/Volumes/Spaces/*" "$PWD"
        echo (set_color red)"❌ Error: Not inside /Volumes/Spaces/X"(set_color normal)
        echo "Please cd into a workspace (e.g., /Volumes/Spaces/work) before cloning."
        return 1
    end

    # 2. Extract workspace name (4th segment: /, Volumes, Spaces, WORKSPACE)
    set -l ws (string split '/' $PWD)[4]
    
    if test -z "$ws"
        echo (set_color red)"❌ Error: Could not determine workspace from current path."(set_color normal)
        return 1
    end

    # 3. Build target path (domain/user/repo)
    # Strip protocols, .git suffix, and normalize separators
    set -l path (string replace -ra '^(git@|https?://|ssh://git@)|.git$|/+$' '' $url | string replace -ra '[:/]' '/')
    set -l target "/Volumes/Spaces/$ws/$path"

    echo (set_color blue)"📂 Workspace: $ws"(set_color normal)
    echo (set_color blue)"🚀 Destination: $target"(set_color normal)

    # 4. Execute clone and move into the new directory
    if mkdir -p (dirname $target); and git clone $url $target
        cd $target
    else
        return 1
    end
end
