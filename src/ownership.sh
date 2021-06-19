# Functionality for marking a _registered_ crate as belonging to the
# user (i.e a local crate as aposed to a forgin crate). 

# own_crate PATH
own_crate() {
    local CRATE_PATH="$(realpath -- "$1")"
    local new_crate_fingerprint="$( path_fingerprint "$CRATE_PATH" )"    
    
    if ! [[ -f "$USERCONFIGDIR/known/$new_crate_fingerprint/registered" ]]; then
        fatal "Crate at '$CRATE_PATH' is not known or trusted or it does not exist."
    fi
    
    # Adding user's identity to the local cache
    mkdir -p "$USERCONFIGDIR/known/$new_crate_fingerprint/owners"
    copy_cert "$LOCAL_IDENTITY_CERT_PATH" "$USERCONFIGDIR/known/$new_crate_fingerprint/owners"
    # We don't need to copy cert into the crate itself since seal() does this automatically.

    
    # Updating cookies (files to make sure that local keys don't get messed up when the user moves directories)
    # 
    mkdir -p "$USERCONFIGDIR/known/$new_crate_fingerprint/cookies.d"
    mkdir -p "$CRATE_PATH/.$PROJECT_NAME/cookies.d"
    local local_cookie="$(head -c 12 /dev/urandom | base64)"
    local crate_cookie="$(printf "%s\n" "$local_cookie" | sha384sum | cut -d ' ' -f 1 | head -c 24)"
    printf "%s\n" "$crate_cookie" > "$CRATE_PATH/.$PROJECT_NAME/cookies.d/$LOCAL_IDENTITY_FINGERPRINT.cookie"
    printf "%s\n" "$local_cookie" > "$USERCONFIGDIR/known/$new_crate_fingerprint/cookies.d/$LOCAL_IDENTITY_FINGERPRINT.cookie"
    
    # Updating origin
    printf "local\n" > "$USERCONFIGDIR/known/$new_crate_fingerprint/origin"
    
    step_message "Owned" "Claimed ownership over ($CRATE_PATH)"
}

# disown_crate PATH
disown_crate() {
    local CRATE_PATH="$(realpath -- "$1")"
    local new_crate_fingerprint="$( path_fingerprint "$CRATE_PATH" )"
    if ! [[ -f "$USERCONFIGDIR/known/$new_crate_fingerprint/registered" ]]; then
        fatal "Crate at '$CRATE_PATH' is not known or trusted or it does not exist."
    fi
    
    printf "forign\n" > "$USERCONFIGDIR/known/$new_crate_fingerprint/origin"
    
    remove_certs  "$new_crate_fingerprint"
    
    step_message "Disowned" "Disclaimed ownership over ($CRATE_PATH)"
}
