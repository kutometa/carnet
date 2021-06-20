#!/bin/bash

# Assemble.sh recursivly collapses simple uses of `source` in bash 
# files. To work correctly, this script assumes:
#
# 1. `source` is argumentless
# 2. No cycles exist between source files.
# 
# Warning: This script will recurse infinitily if there is a cycle. 
#          This can lead to OOM conditions or depletion of disk 
#          space.

set -eu
set -H

DELEMETER="$(head -c 8 /dev/urandom | sha384sum | cut -f 1 -d ' ')SOURCESOURCE "
assemble() {
    printf "Sourcing from '%s' from '%s'..\n" "$1" "$PWD" >&2
    DIR="$(dirname "$1")"
    FILENAME="$(basename "$1")"
    
    (
        set -eu
        set -H
        cd "$DIR"
        while IFS= read -r LINE; do 
            PROCESSED_LINE="$(printf "%s" "$LINE" | sed -E 's/^ *source "([^$\\]+)" *(#.*)?$/'"$DELEMETER"'\1/g')"
            if [[ "$PROCESSED_LINE" =~ ^$DELEMETER ]]; then
                TARGET_PATH="$(printf "%s" "$PROCESSED_LINE" | cut -f 2 -d ' ')"
                assemble "$TARGET_PATH"
            else 
                printf "%s\n" "$LINE"
            fi
        done < <(cat "$FILENAME")
    
    )
}

assemble "$1"
