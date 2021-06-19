
clear_dev_session() {
    if ! [[ "${KNOWN_CRATE_PATH_HASH-}" ]]; then
        debug "Not refreshing dev session because no crate was found"
        return
    fi
    local SESSION_DIR="$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/session"
    mkdir -p "$SESSION_DIR"
    if ! [[ -f "$SESSION_DIR/starting.timestamp" ]]; then printf "%s\n" "0" > "$SESSION_DIR/starting.timestamp"; fi
    if ! [[ -f "$USERCONFIGDIR/session.duration" ]]; then printf "%s\n" "3600" > "$USERCONFIGDIR/session.duration"; fi
    
    printf "0\n" > "$SESSION_DIR/starting.timestamp"
}
refresh_dev_session() {
    if ! [[ "${KNOWN_CRATE_PATH_HASH-}" ]]; then
        debug "Not refreshing dev session because no crate was found"
        return
    fi
    local SESSION_DIR="$USERCONFIGDIR/known/$KNOWN_CRATE_PATH_HASH/session"
    mkdir -p "$SESSION_DIR"
    if ! [[ -f "$SESSION_DIR/starting.timestamp" ]]; then printf "%s\n" "0" > "$SESSION_DIR/starting.timestamp"; fi
    if ! [[ -f "$USERCONFIGDIR/session.duration" ]]; then printf "%s\n" "3600" > "$USERCONFIGDIR/session.duration"; fi
    
    local last_session_ts="$(cat "$SESSION_DIR/starting.timestamp")"
    local max_session_duration="$(cat "$USERCONFIGDIR/session.duration")"
    local now="$(date +%s)"
    [[ "$last_session_ts" -eq "$last_session_ts" ]]
    [[ "$max_session_duration" -eq "$max_session_duration" ]]
    
    if (( now < last_session_ts )) || (( now >= (last_session_ts + max_session_duration) )); then
        local session_status="inactive"
    else
        local session_status="active"
    fi
    
    if [[ "$NEW_DEV_SESSION" == "yes" ]]; then
        printf "%s\n" "$now" > "$SESSION_DIR/starting.timestamp"
        DISABLE_AUTOVERIFICATION="yes"
        NEW_DEV_SESSION="no"
        printf "\n"
        if [[ "$session_status" == "active" ]]; then
            printf "The edit session for this crate is still active "
        else
            printf "The edit session for this crate is now active "
        fi
        printf "and is set to expire after $(( $max_session_duration/60 )) minute(s).
  - To change this duration, edit '$USERCONFIGDIR/session.duration'.
  - To expire this duration, run 'carnet carnet:done'.\n\n"
    else
        if [[ "$session_status" == "active" ]]; then
            printf "%s\n" "$now" > "$SESSION_DIR/starting.timestamp"
            DISABLE_AUTOVERIFICATION="yes"
            NEW_DEV_SESSION="no"
        fi
    fi
}
