# Functionality for making a forgin crate known to the system.

# This function registers a carnet crate as a forign/disowned crate.
# The second argument can be a directory of public keys and certificates,
# a single file?, or nothing for trusting the repository's own credentials
#
# trust_crate PATH [KEYOVERRIDE]
trust_crate() {
    local CRATE_PATH="$(realpath -- "$1")"
    local new_crate_fingerprint="$( path_fingerprint "$CRATE_PATH" )"
    if ! [[ -f "$USERCONFIGDIR/known/$new_crate_fingerprint/registered" ]]; then
        debug "Trusting new crate at '$CRATE_PATH' giving it id $new_crate_fingerprint.."
        mkdir -p "$USERCONFIGDIR/known/$new_crate_fingerprint"
        if [[ -d "${2-}" ]]; then
            update_certs "$2" "$USERCONFIGDIR/known/$new_crate_fingerprint/owners"
            # mkdir "$USERCONFIGDIR/known/$new_crate_fingerprint/identity.blacklist.d"
        elif [[ -f "${2-}" ]]; then
            false
        else
            update_certs "$CRATE_PATH/.$PROJECT_NAME/owners" "$USERCONFIGDIR/known/$new_crate_fingerprint/owners"
            # update_certs "$CRATE_PATH/.$PROJECT_NAME/identity.blacklist.d" "$USERCONFIGDIR/known/$new_crate_fingerprint/identity.blacklist.d"
        fi
        printf "forign\n" > "$USERCONFIGDIR/known/$new_crate_fingerprint/origin"
        echo "registered" > "$USERCONFIGDIR/known/$new_crate_fingerprint/registered"
        step_message "Trusted" "Registered crate with your system ($CRATE_PATH)"
    else
        fatal "Cannot trust crate '$CRATE_PATH' it is already trusted"
    fi
}

distrust_crate() {
    local CRATE_PATH="$(realpath -- "$1")"
    local new_crate_fingerprint="$( path_fingerprint "$CRATE_PATH" )"
    if ! [[ -f "$USERCONFIGDIR/known/$new_crate_fingerprint/registered" ]]; then
        step_message "Distrusted" "Given crate is not registered on your system ($CRATE_PATH)"
    else
        rm -r "$USERCONFIGDIR/known/$new_crate_fingerprint"
        step_message "Distrusted" "Unregistered crate from your system ($CRATE_PATH)"        
    fi
}


# locate_known_crate_from_the_inside_and_set_up_global_variables
# 
# 
locate_known_crate_from_the_inside_and_set_up_global_variables() {
    while true; do
        KNOWN_CRATE_PATH="$(realpath -- $KNOWN_CRATE_PATH)"
        KNOWN_CRATE_PATH_HASH="$( path_fingerprint "$KNOWN_CRATE_PATH" )"

        if ! [[ -f "$KNOWN_CRATE_PATH/.$PROJECT_NAME/initialized" ]] && [[ -f "$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/registered" ]]; then
            fatal "Phantom crate found at '$KNOWN_CRATE_PATH'. This means that a crate at this path was previously registered with Carnet but has since been moved or deleted."
        fi
        
        if [[ -f "$KNOWN_CRATE_PATH/.$PROJECT_NAME/initialized" ]] && ! [[ -f "$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/registered" ]]; then
            echo "Found a new unknown crate at '$KNOWN_CRATE_PATH' that was signed by the following identity(s):"
            list_identities "$KNOWN_CRATE_PATH/.$PROJECT_NAME/owners"
            echo ""
            prompt_yes_no_and_require_yes "Would you like to trust this crate?"
            trust_crate "$KNOWN_CRATE_PATH"
        fi
        
        if [[ -f "$KNOWN_CRATE_PATH/.$PROJECT_NAME/initialized" ]] && [[ -f "$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/registered" ]]; then
            KNOWN_CRATE_STATE="found"
            KNOWN_CRATE_ORIGIN="$(cat "$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/origin")"
            
            if [[ "$KNOWN_CRATE_ORIGIN" == "local" ]]; then
                local crate_cookie="$KNOWN_CRATE_PATH/.$PROJECT_NAME/cookies.d/$LOCAL_IDENTITY_FINGERPRINT.cookie"
                local cached_cookie="$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/cookies.d/$LOCAL_IDENTITY_FINGERPRINT.cookie"
                local crate_cookie_content="$(cat "$crate_cookie")"
                local cached_cookie_content="$(cat "$cached_cookie" | sha384sum | cut -d ' ' -f 1 | head -c 24)"
                if [[ "$crate_cookie_content" != "$cached_cookie_content" ]] ; then
                    debug "Crate cookies do not match: crate:'$crate_cookie_content', cached:'$cached_cookie_content'"
                    fatal "Crate cookies do not match. This means that the crate was likely replaced since it was last owned."
                fi
            fi
            debug "Root crate path: '${KNOWN_CRATE_PATH-}'"
            debug "Root crate path hash: '${KNOWN_CRATE_PATH_HASH-}'"
            debug "Root crate path origin: '${KNOWN_CRATE_ORIGIN-}'"
            break
        fi
        if [[ "$( realpath -- "$KNOWN_CRATE_PATH" )" == "/" ]]; then
            debug "Could not find a crate in this directory or any of its parents.\n"
            unset KNOWN_CRATE_PATH
            unset KNOWN_CRATE_PATH_HASH
            unset KNOWN_CRATE_ORIGIN
            unset KNOWN_CRATE_STATE
            debug "Could not find root of crate."
            debug "Could not derive Root crate's path hash."
            break
        fi
        KNOWN_CRATE_PATH="$KNOWN_CRATE_PATH/.."
    done
}
