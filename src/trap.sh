# Trap setup: Trapping is used to detect when the script exits in 
# abnormal.

# This global variables are exculsivly managed by this code. 
EXITING="no"
EXITING_MESSAGE="no"

at_exit_callback() {
    if [[ "$EXITING" != "yes" ]]; then
        if [[ "${EXITING_MESSAGE-}" != "yes" ]]; then
            debug "crashing.."
            printf "${RED-}A problem occurred and $PROJECT_NAME needs to exit in an unintended way. Specified operations may not have completed correctly or may have been left in an inconsistent state. Please report this issue.${RESET-}\n" 1>&2
            EXITING_MESSAGE="yes"
        fi
        builtin exit 108
    fi
}

trap at_exit_callback EXIT TERM INT

# overiding bash's built-in to avoid trapping on normal exits.
exit() {
    EXITING="yes"
    debug "exiting properly with exit $*."
    builtin exit "$@"
}

