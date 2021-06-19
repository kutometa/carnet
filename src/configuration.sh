# code for setting configuration settings.

configuration_settings() {
    if [[ "${1-}" == "enable" ]]; then
        val="enabled"
    elif [[ "${1-}" == "disable" ]]; then
        val="disabled"
    else
        fatal "internal error: first argument given to configuration_settings must be enable/disable. '${1-}' given. "
    fi
    
    mkdir -p "$USERCONFIGDIR/settings"
    
    if  [[  "${2-}" == "verification" ]]; then
        echo "$val" > "$USERCONFIGDIR/settings/$2.setting"
        step_message "Settings" "Automatic verification is now $val"
    elif [[ "${2-}" == "sandbox" ]]; then
        echo "$val" > "$USERCONFIGDIR/settings/$2.setting"
        step_message "Settings" "Sandboxing is now $val"  
    elif [[ "${2-}" == "eula-agreement" ]]; then
        echo "$val" > "$USERCONFIGDIR/settings/$2.setting"
        if [[ "${1-}" == "enable" ]]; then
            step_message "Settings" "You indicate that you agree to the terms and conditions of the EULA"
        else
            step_message "Settings" "You indicate that you do not agree to the terms and conditions of the EULA"
        fi
        
    else 
        fatal "Setting '${2-}' is not known."
    fi
    
    
}
