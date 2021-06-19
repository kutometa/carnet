# IO functions and general process control

step_message() {
    printf "${GREEN-}%12s${RESET-} %s\n" "$1" "$2" 1>&2
}

fail() {
    printf "\r${RED-}%s${RESET-} %s\n" "$1" "$2" 1>&2
    exit 107
}

ignored_step_message() {
    printf "${YELLOW-}%12s${RESET-} %s\n" "$1" "$2" 1>&2
}

fatal() {
    printf "${RED-}error${RESET-}${BOLD-}:${RESET-} ${DIM-} -- $PROJECT_NAME -- ${RESET-} $*\n" 1>&2
    exit 107
}

warn() {
    printf "${YELLOW-}warning${RESET-}${BOLD-}:${RESET-} ${DIM-} -- $PROJECT_NAME -- ${RESET-} $*\n" 1>&2
}

debug() {
    if [[ "${DEBUG-}" == "yes" ]]; then
        printf "${DIM-}verbose:  -- $PROJECT_NAME --  $*${RESET-}\n" 1>&2
    fi
}

# 
prompt_yes_no() {
    read -r ANSWER
    if [[ "$ANSWER" == "${1-yes}" ]]; then
        return 0
    else
        return 1
    fi
}


# prompt_yes_no_and_require_yes PROMT Strings
# Ask the user a yes/no question
prompt_yes_no_and_require_yes() {
    printf "$* (enter 'yes' and hit the Enter key to continue) "
    if ! prompt_yes_no; then
        fatal "'yes' was not given. Aborting."
    fi
}


