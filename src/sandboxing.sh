# Sandboxing


# Runs args in a sandbox if sandboxing is not disabled. Run args 
# directly if it is.
sandbox() {
    (
        set -euH
        set -o pipefail
        trap - EXIT TERM INT
        
        if [[ "${DISABLE_SANDBOX-}" == "yes" ]]; then
            ignored_step_message "Sandbox" "Sandboxing is disabled"
            debug "Bypassing sandbox because sandboxing is disabled"
            exec "$@"
        fi
        
        
        local SANDBOX_ARGS=( "--die-with-parent" )
        if [[ "${SANDBOX_ALL}" == "yes" ]]; then
            SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--unshare-all" )
        else
            if ! [[ "${SANDBOX_NETWORK-}" == "no" ]]; then
                SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--unshare-net" )
            fi
            if ! [[ "${SANDBOX_PROCESS-}" == "no" ]]; then
                SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--unshare-ipc"  "--unshare-pid" )
            fi
            # Note: Sandboxing/unsandboxing cargo home is done later
            # Note: Sandboxing/unsandboxing tty session is done later
            
        fi
        
        if [[ "$SANDBOX_ALL" == "yes" ]] || ! [[ "$SANDBOX_FILESYSTEM" == "no" ]]; then
            EFFECTIVE_CARGO_HOME="${CARGO_HOME-$HOME/.cargo/}" 
            
            # only useful when cargo-home is unsandboxed and cargo was never run 
            # on the current system
            mkdir -p "$EFFECTIVE_CARGO_HOME"
            
            SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" \
                           "--ro-bind" "/etc"       "/etc"  \
                           "--ro-bind" "/bin"       "/bin"  \
                           "--ro-bind" "/lib"       "/lib"  \
                           "--ro-bind" "/lib64"     "/lib64" \
                           "--ro-bind" "/sbin"      "/sbin" \
                           "--ro-bind" "/usr"       "/usr"  \
                           "--tmpfs"   "/tmp"       \
                           "--bind"    "${KNOWN_CRATE_PATH:-$PWD}" "${KNOWN_CRATE_PATH:-$PWD}" \
                           "--dir"     "/run/user/$(id -u)" \
                           "--proc"    "/proc"  \
                           "--dev"      "/dev"  )
           
            if [[ "${SANDBOX_CARGO_HOME-}" == "no" ]]; then
                SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--bind" "$EFFECTIVE_CARGO_HOME" "$EFFECTIVE_CARGO_HOME" )
            else
                SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--dir" "$HOME" )
            fi
            
            if [[ -f "/run/systemd/resolve/stub-resolv.conf" ]]; then
                SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--ro-bind" "/run/systemd/resolve/stub-resolv.conf" "/run/systemd/resolve/stub-resolv.conf" )
            fi
            
            if [[ "${SANDBOX_RW_PATHS-}" ]]; then
                OIFS="$IFS"
                IFS=":" 
                for bind in $SANDBOX_RW_PATHS; do
                    IFS="$OIFS" 
                    if ! [[ -e "$bind" ]]; then
                        fatal "The following path does not exist: '$bind'"
                    fi
                    bind="$(realpath -- "$bind")"
                    SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--bind" "$bind" "$bind")
                done
                IFS="$OIFS"
            fi
            if [[ "${SANDBOX_RO_PATHS-}" ]]; then
                OIFS="$IFS"
                IFS=":" 
                for bind in $SANDBOX_RO_PATHS; do
                    IFS="$OIFS" 
                    if ! [[ -e "$bind" ]]; then
                        fatal "The following path does not exist: '$bind'"
                    fi
                    bind="$(realpath -- "$bind")"
                    SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}" "--ro-bind" "$bind" "$bind")
                done
                IFS="$OIFS"
            fi
        else
            SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}"  "--bind" "/" "/" "--dev" "/dev" )
        fi
        
        if [[ "$SANDBOX_ALL" == "yes" ]] || ! [[ "$SANDBOX_SESSION" == "no" ]]; then
            SANDBOX_ARGS=( "${SANDBOX_ARGS[@]}"  "--new-session" )
        fi
        
        
        debug "Standard bublewrap options being applied are: "
        for opt in "${SANDBOX_ARGS[@]}"; do
            debug "   $opt"
        done
        if [[ "$(printf '0.3.0\n%s\n' "$(bwrap --version | cut -d ' ' -f2)" | sort -V )" == "0.3.0" ]]; then
            exec bwrap "${SANDBOX_ARGS[@]}" --chdir "$PWD" -- "$@"
        else
            exec bwrap "${SANDBOX_ARGS[@]}" --chdir "$PWD" "$@"
        fi        
    ) || return "$?"
    REQUESTED_PERMISSIONS=""
}


