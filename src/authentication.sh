



# describe_mismatch     path-TO-TRUSTED-HASH LIST  PATH-TO-ROOT-OF-CRATE  HASH-ALGO
describe_mismatch() {
    local DISPLAY_CURRENT_SIGNATURES="$(generate_crate_seal_list "$hashalgo" "$2"  | tr '\n' '␤' | tr '\0' '\n')"
    local DISPLAY_TRUSTED_SIGNATURES="$(cat "$1" | tr '\n' '␤' | tr '\0' '\n')"
    
    local CURRENT_LINECOUNT=$(printf "%s" "$DISPLAY_CURRENT_SIGNATURES" | wc -l)
    local TRUSTED_LINECOUNT=$(printf "%s" "$DISPLAY_TRUSTED_SIGNATURES" | wc -l)
    #  Signed file manifest does not list files that are currently present in this directory.
    if [[ "$CURRENT_LINECOUNT" -lt "$TRUSTED_LINECOUNT" ]]; then
        warn "Missing files (and possibly edited and extra files) not accounted for in the signed manifest."
    elif [[ "$CURRENT_LINECOUNT" -gt "$TRUSTED_LINECOUNT" ]]; then
        warn "Extra files (and possibly edited and missing files) not accounted for in the signed manifest."
    else [[ "$CURRENT_LINECOUNT" == "$TRUSTED_LINECOUNT" ]]
        warn "Missing, edited, or missing files not accounted for in the signed manifest."
    fi
    
    set -e
    set -u
    set -H
    set -o pipefail
    # Some concerns:
    #   Filenames can contain anything but nulls and forward slashs. This means that
    #   an attacker can include newlines hashes. It's not clear to me if this can 
    #   be exploited (especially given how sha*sum handles newlines in filenames.
    # 
    # TODO investigate this when you have more time.
    #
    comm --nocheck-order --output-delimiter= -3 <(printf "%s" "$DISPLAY_CURRENT_SIGNATURES") <(printf "%s" "$DISPLAY_TRUSTED_SIGNATURES") | sed -E 's/^([^ ]+)+[ 	]*.*$/\1/g' | sort | uniq |  while read -r l; do warn "Problem with file: $l"; done
    
}


# generate_crate_seal_list "sha384"|"sha256" INSECURE_KNOWN_CRATE_PATH
#
# Generate a sorted list of all files in $2, with the
# exclusion of any relative paths that match one of the patterns 
# listed. 
generate_crate_seal_list() {
    local -a find_args
    
    if ! [[ "${1-}" ]]; then
        fatal "INTERNAL BUG: HASH ALGO REQUIRED"
    fi
    # "^\b$"
    if [[ -f "$2/.$PROJECT_NAME/seal-ignore.list" ]]; then
        while read -r pattern; do
            #find_args=( "${find_args[@]}" "-not" "-regex" "$pattern" )
            find_args=( "${find_args[@]}" "-e" "$pattern" )
        done < <( cat "$2/.$PROJECT_NAME/seal-ignore.list" | sed '/^\s*$/d' )
    fi
    
    ( 
      set -e
      set -u
      set -H;
      set -o pipefail; 
      local PATHNAME;
      cd "$2" 
      find "." -type f -print0 | grep -vzE "${find_args[@]}" -e "^\b$" | while read -d '' -r PATHNAME; do
        printf "%s %s\0" "$PATHNAME" "$(cat "$PATHNAME" | "$1"sum | cut -d ' ' -f 1)"
      done | env LC_ALL=C sort -z
     ) 
}



# seal
#
# Sign current owned carnet crate, but ignore any files matching 
# .$PROJECT_NAME/seal-ignore.list.
#
# Will not sign any crate that is not registered and is not local/owned.
seal() {
    if ! [[ "${KNOWN_CRATE_STATE-}" ]] ||  ! [[ "$KNOWN_CRATE_STATE" == "found" ]] || ! [[ "$KNOWN_CRATE_ORIGIN" == "local" ]]; then
        fatal "Cannot sign a crate that is not owned by you (${KNOWN_CRATE_PATH-}). Run $PROJECT_NAME carnet:crate-info for more information about the crate."
    fi
    
    if ! [[ -f "$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/registered" ]]; then
        ignored_step_message "Sealing" "Cannot seal crate because it wasn't initialized by $PROJECT_NAME."
        return 0
    fi
    step_message "Sealing" "Signing crate root ($KNOWN_CRATE_PATH)"
    if [[ -f "$KNOWN_CRATE_PATH/.$PROJECT_NAME/seal" ]]; then rm -r "$KNOWN_CRATE_PATH/.$PROJECT_NAME/seal"; fi
    mkdir -p "$KNOWN_CRATE_PATH/.$PROJECT_NAME/seal"
    mkdir -p "$KNOWN_CRATE_PATH/.$PROJECT_NAME/owners"
    # mkdir -p "$KNOWN_CRATE_PATH/.$PROJECT_NAME/identity.blacklist.d"
        
    #cp "$LOCAL_IDENTITY_PUBKEY_PATH" "$KNOWN_CRATE_PATH/.$PROJECT_NAME/owners/$LOCAL_IDENTITY_FINGERPRINT.pub"
    cp "$LOCAL_IDENTITY_CERT_PATH"   "$KNOWN_CRATE_PATH/.$PROJECT_NAME/owners/$LOCAL_IDENTITY_FINGERPRINT.cert"
    
    for hashalgo in "${HASH_ALGORITHMS[@]}"; do
        generate_crate_seal_list "$hashalgo" "$KNOWN_CRATE_PATH" > "$KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/signatures.$hashalgo"
        
        openssl dgst -sign "$LOCAL_IDENTITY_PRIVKEY_PATH" \
                     -"$hashalgo" \
                     -out "$KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/signatures.$hashalgo.$LOCAL_IDENTITY_FINGERPRINT.sig" \
                     "$KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/signatures.$hashalgo"
        
    done
    echo "sealed" > "$KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/sealed"
}

verify() {
    if ! [[ "${KNOWN_CRATE_STATE-}" ]] ||  [[ "$KNOWN_CRATE_STATE" != "found" ]]; then
        fatal "Cannot verify crate because it isn't known."
        return 0
    fi
    
    # To minimize the chances of accidentally relying on unverified crate content, 
    # $KNOWN_CRATE_PATH is temporarly set to an invalid value. Only use INSECURE_KNOWN_CRATE_PATH 
    # for informative purposes. Set back when the crate is verified
    local INSECURE_KNOWN_CRATE_PATH="$KNOWN_CRATE_PATH"
    KNOWN_CRATE_PATH="HIDDEN"
    
    step_message "Verifying" "Checking file signatures ($INSECURE_KNOWN_CRATE_PATH)"
    
    if ! [[ -f "$INSECURE_KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/sealed" ]]; then
        fatal "Cannot verify crate because it wasn't sealed. See --carnet:help for more information."
    fi
    
    local CACHED_WHITELIST_DIR="$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/owners"
    
    local -a issues;
    
    # Verify pk signatures
    local KEY=""
    for candidate_identity_cert in "$CACHED_WHITELIST_DIR"/*.cert; do
        # If the certificate isn't a file, skip it.
        if ! [[ -f "$candidate_identity_cert" ]]; then 
            fatal "No owners were found or a non file was found in '$CACHED_WHITELIST_DIR'"
            return 1
        fi
        
        # Generate owner fingerprint from cert
        local cached_whitelist_fingerprint="$(file_fingerprint "$candidate_identity_cert")"
        
        # (Consistency check) Ensure that fingerprint of the cert matches its filename
        local expected_cached_whitelist_fingerprint="$(basename "$candidate_identity_cert")"
        expected_cached_whitelist_fingerprint="${expected_cached_whitelist_fingerprint::-5}"
        if [[ "$expected_cached_whitelist_fingerprint" != "$cached_whitelist_fingerprint" ]]; then
            fatal "The filename of the identity certificate for does not match its fingerprint: Found '$candidate_identity_cert' which should be named '$cached_whitelist_fingerprint'"
            return 1
        fi
        
        # If a crate owner is pinned, skip any crate owner that doesn't doesn't match it
        if [[ "${PINNED_OWNER_IDENTITY_FINGERPRINT-}" ]] && [[ "$PINNED_OWNER_IDENTITY_FINGERPRINT" != "$cached_whitelist_fingerprint" ]]; then
            debug "Ignored ${cached_whitelist_fingerprint} because it isn't the pinned owner $PINNED_OWNER_IDENTITY_FINGERPRINT"
            issues=( "${issues[@]}" "Ignored any signatures by identity ${cached_whitelist_fingerprint} because it doesn't match what was pinned ($PINNED_OWNER_IDENTITY_FINGERPRINT)" )
            verified="no"
            break
        fi
        
        # Verifying public key against
        local candidate_identity_pubkey="$(dirname "$candidate_identity_cert")/$cached_whitelist_fingerprint.pub"
        if ! cmp -s -- "$candidate_identity_pubkey" < <(openssl x509 -pubkey -noout -in "$candidate_identity_cert"); then
            fatal "The on-disk public key '$candidate_identity_pubkey' does not correspond of that is generated from '$candidate_identity_cert'"
            return 1
        fi
        
        
        debug "looking for signatures made by '$cached_whitelist_fingerprint' in '$INSECURE_KNOWN_CRATE_PATH/.$PROJECT_NAME/seal'"
        
        # If this crate was signed by this particular crate owner 
        if [[ -f "$INSECURE_KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/signatures.sha384.$cached_whitelist_fingerprint.sig" ]]; then
            debug "signature found: 'signatures.sha384.$cached_whitelist_fingerprint.sig'"
            
            # Make sure that crate files are verified against the checksum files of ALL hash algorithms 
            local verified="no"
            for hashalgo in "${HASH_ALGORITHMS[@]}"; do
                debug "Verifying signatures made using $hashalgo..."
                verified="no"
                local signature_file="$INSECURE_KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/signatures.$hashalgo.$cached_whitelist_fingerprint.sig"
                local hashsum_file="$INSECURE_KNOWN_CRATE_PATH/.$PROJECT_NAME/seal/signatures.$hashalgo"
                local OPENSSL_OUTPUT
                
                # First verify the signature of the checksum file using the owner's public key
                debug "Verifying signature of '$hashsum_file' using '$candidate_identity_pubkey'"
                if ! OPENSSL_OUTPUT="$(openssl dgst \
                     -verify "$candidate_identity_pubkey" \
                     -keyform pem \
                     "-$hashalgo" \
                     -signature "$signature_file" \
                     "$hashsum_file" 2>&1)"; then
                     debug "Invalid signature '$signature_file' for '$hashsum_file' with $hashalgo: $OPENSSL_OUTPUT"
                     issues=( "${issues[@]}" "Bad signature for ${cached_whitelist_fingerprint}" )
                     verified="no"
                     break
                fi 
                
                # Then generate a local checksum list of all files using whatever /untrusted/ parameters in 'seal-ignore.list',
                # hash both checksum files (trusted and untrusted), and compare.
                
                debug "Generating checksums of unverified crate content"
                local CURRENT_SIGNATURES_HASH="$(generate_crate_seal_list "$hashalgo" "$INSECURE_KNOWN_CRATE_PATH" | "$hashalgo"sum)"
                local TRUSTED_SIGNATURES_HASH="$(cat "$hashsum_file" | "$hashalgo"sum)"
                
                debug "Verifying checksums against of '$hashsum_file'"
                if [[ "$CURRENT_SIGNATURES_HASH" != "$TRUSTED_SIGNATURES_HASH" ]]; then
                    describe_mismatch "$hashsum_file" "$INSECURE_KNOWN_CRATE_PATH" "$hashalgo"
                    fatal "$hashalgo checksum mismatch."
                fi
                verified="yes"
            done
            
            # If all hash checksum checks pass, consider the crate verified
            if [[ "$verified" == "yes" ]]; then
                KNOWN_CRATE_PATH="$INSECURE_KNOWN_CRATE_PATH"
                # Overwrite local crate owners with the list provided by the now trusted crate 
                update_certs "$KNOWN_CRATE_PATH/.$PROJECT_NAME/owners" "$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/owners"
                step_message "Verified" "Sealed by ${cached_whitelist_fingerprint}"
                debug "verification okay"
                return
            else 
                debug "Verification failed for ${cached_whitelist_fingerprint}."
                continue
            fi
        else
            debug "signature not found."
            issues=( "${issues[@]}" "Signature missing for ${cached_whitelist_fingerprint}" )
        fi    
    done
    fatal "Could not verify crate:$(echo ""; for issue in "${issues[@]}"; do printf "        - %s\n" "$issue"; done)"
    return 1
}
