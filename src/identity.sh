# Code for handling identities

# remove_certs removes user's identity cert from the cache
# should this also remove the certs from the crate itself? 
# I don't think so because a crate author can transfer their 
remove_certs() {
    rm "$USERCONFIGDIR/known/$1/owners/$LOCAL_IDENTITY_FINGERPRINT.cert"
}

# copy_cert  PATH_TO_CERT  PATH_TO_KEY_DIR
#
# Copy a public openssl PEM certificate to a directory and rename it
# to the hash of its file. Then generate the public key for that file
#
copy_cert() {
    local identity_fingerprint="$( file_fingerprint "$1" )"
    cp "$1" "$2/$identity_fingerprint.cert.part"
    mv "$2/$identity_fingerprint.cert.part" "$2/$identity_fingerprint.cert"
    openssl x509 -pubkey -noout -in "$2/$identity_fingerprint.cert" > "$2/$identity_fingerprint.pub"
    debug "Copied cert '$1' as '$2/$identity_fingerprint.cert'."
    debug "Extracted public key from '$1' as '$2/$identity_fingerprint.pub'."
}

# copy_certs  PATH_TO_CERTS_DIR  PATH_TO_KEY_DIR
#
# Same as `copy_cert` but treat first arg as directory and iterate 
# over each file in it. Ignore nonfiles. See  `copy_cert`.
#
copy_certs() {
    mkdir -p "$2"
    for i in "$1"/*.cert; do 
        if [[ -f "$i" ]]; then
            copy_cert "$i" "$2"
        else
            debug "Ignored '$i' while copying certs from '$1' to '$2'."
        fi
    done
}


swapname() {
    tcc -run - "$@" <<"CODE"
    #include <unistd.h>
    #include <fcntl.h> 
    #include <stdio.h>
    #include <sys/syscall.h>
    
    // Ubuntu 18.04 doesn't define this constant
    // Obtained from '/usr/include/linux/fs.h'
    // Always test first! Might not always correspond to userland 
    // RENAME_EXCHANGE
    int local_RENAME_EXCHANGE = (1 << 1);
    
    int main(int argc, char **argv) {
        if (argc != 3) { 
            fprintf(stderr, "Error: Could not swap names. Usage: %s PATH1 PATH2\n", argv[0]);
            return 2; 
        }
        int r = syscall(
            SYS_renameat2,
            AT_FDCWD, argv[1],
            AT_FDCWD, argv[2], 
            local_RENAME_EXCHANGE
        );
        if (r < 0) {
            perror("Error: Could not swap names");
            return 1;
        }
        else return 0;
    }
CODE
}


# Sanity test
SWAPNAME_TEST_PATH_1="$(mktemp)"
SWAPNAME_TEST_PATH_2="$(mktemp)"
echo "A" >"$SWAPNAME_TEST_PATH_1"
echo "B" >"$SWAPNAME_TEST_PATH_2"
swapname "$SWAPNAME_TEST_PATH_1" "$SWAPNAME_TEST_PATH_2"
if [[ "$(cat "$SWAPNAME_TEST_PATH_1")" != "B" ]]; then 
    fatal "Internal tests failed: 'swapname' is not swapping files!"
fi
rm "$SWAPNAME_TEST_PATH_1"
rm "$SWAPNAME_TEST_PATH_2"



# update_certs  PATH_TO_CERTS_DIR  PATH_TO_KEY_DIR
#
# Replaces all keys in  PATH_TO_KEY_DIR  with those in 
# PATH_TO_CERTS_DIR, and do so in a manner that is resistant to 
# corruption.
#
update_certs() {
    mkdir -p "$2"
    if [[ -d "$2.partial" ]]; then
        rm -r "$2.partial"
    fi
    copy_certs "$1" "$2.partial"
    swapname "$2.partial" "$2" || fatal "Could not update owners in '$2'"
}


#  show_cert_information PATH-TO-PEM-CERT ["identity-mode"]
show_cert_information() {
    local AUTHOR_IDENT_ID="$(file_fingerprint "$1")"
    if [[ "$AUTHOR_IDENT_ID.cert" != "$(basename "$1")" ]] && [[ "${2-}" != "identity-mode" ]]; then
        fatal "Found corrupted identity certificate: the given certificate was not named correctly: '$1'"
    fi
    echo ""
    if [[ "${2-}" != "identity-mode" ]]; then
        printf "  Identity $AUTHOR_IDENT_ID which claims:\n"
    fi
    openssl x509 -nameopt multiline,-esc_msb,utf8 -in "$1" -noout -subject \
        | sed -E "/^subject=/d" \
        | sed -E 's/^    commonName   /    Name   /g' \
        | sed -E 's/^    emailAddress    /    Email     /g' \
        | sed -E 's/^    organizationName   /    Organization /g' \
        | sed -E 's/^    countryName   /    Country /g' 
    
}


# List all identities found in the given directory
list_identities() {
    if ! [[ -d "${1}" ]]; then
        fatal "Given identity directory doesn't contain any identities or does not exist (${1-})."
    fi
    for licert in "$1"/*.cert; do 
        if [[ -f "$licert" ]]; then
            show_cert_information "$licert"
        else
            fatal "Found corrupted or missing identity certificates in '$1'. Has this crate been sealed yet?"
        fi
    done
}
