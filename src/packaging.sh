# initialize_crate PATH
# 
# This function initializes a plain cargo crate as a carnet crate
# This function does not register the given crate with the system
# use trust_crate.
initialize_crate() {
    local CRATE_PATH="$(realpath -- "$1")"
    if ! [[ -d "$CRATE_PATH/.$PROJECT_NAME/owners" ]]; then mkdir -p "$CRATE_PATH/.$PROJECT_NAME/owners"; fi
    # if ! [[ -d "$CRATE_PATH/.$PROJECT_NAME/identity.blacklist.d" ]]; then mkdir -p "$CRATE_PATH/.$PROJECT_NAME/identity.blacklist.d"; fi
    echo '/\.git/'                     >  "$CRATE_PATH/.$PROJECT_NAME/seal-ignore.list"
    echo '/\.git$'                     >> "$CRATE_PATH/.$PROJECT_NAME/seal-ignore.list"
    echo '^\./target/'                 >> "$CRATE_PATH/.$PROJECT_NAME/seal-ignore.list"
    echo "^\./\.$PROJECT_NAME/seal/"   >> "$CRATE_PATH/.$PROJECT_NAME/seal-ignore.list"
    
    echo "initialized"                > "$CRATE_PATH/.$PROJECT_NAME/initialized"
    step_message "Initialized" "Initialized crate root ($CRATE_PATH)"
}


uninitialize_crate() {
    local CRATE_PATH="$(realpath -- "$1")"
    distrust_crate "$CRATE_PATH"
    if [[ -d "$KNOWN_CRATE_PATH/.$PROJECT_NAME" ]]; then 
        rm -r "$KNOWN_CRATE_PATH/.$PROJECT_NAME"
        step_message "Uninit" "Uninitialized crate ($CRATE_PATH)"
    else
        step_message "Uninit" "Crate is already uninitialized ($CRATE_PATH)"
    fi
}
