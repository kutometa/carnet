#!/bin/bash

set -eu
set -H

# beware! this script is retarded.
#
# 1. Assumes source is argumentless
# 2. Does not parse source's arguments or attempt to handle them in any way
# 3. Will recurse infinitly if given a cyclic sourcing is encounterd.
# 
# treat this script with care. 

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
