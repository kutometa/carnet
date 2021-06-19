if [[ "$CONFIGURATION_EULA_AGREEMENT" != "enabled" ]] && [[ "$COMMAND" != "enable" ]] && [[ "$COMMAND" != "disable" ]]; then
    printf "
    ${BOLD-}Welcome to version $PROJECT_VERSION of Carnet!${RESET-}

    This is experimental, alpha-grade software. This software should 
    not be used in any environment without a proper understanding the 
    risks involved. 
    
    Crate authentication is not ready yet. We strongly encourage you
    to disable automatic verification by running the following 
    command:
    
        carnet disable verification
        
    You can enable it again at any time if you want.

    The terms and conditions governing your use and redistribution of
    this software impose important limitations on warranty and 
    liability. These terms and conditions can be viewed by running 
    the command 'carnet --carnet:legal'. DO NOT USE THIS SOFTWARE if 
    you do not or cannot agree to the terms and conditions of this 
    license.

    If you would like to proceed, please type I AGREE in the box 
    bellow:

    [         ]\r    [ "

    if [[ -t 0 ]] && [[ -t 1 ]] && [[ -t 2 ]]; then
        if ! prompt_yes_no "I AGREE"; then
            echo ""
            fail "Aborted:" "User declined to agree. Aborting."
        else
            echo ""
            configuration_settings "enable" "eula-agreement"
        fi
    else
        fail "Aborted:" "Not connected to a normal tty. Note that you can indicate your agreement by running 'carnet enable eula-agreement' once."
    fi
fi
