# Check system for needed dependencies

check_installed() {
    if ! hash "$1" > /dev/null 2>&1 || ! which "$1" > /dev/null 2>&1; then
        echo "An error occurred: The program '$1' is needed by $PROJECT_NAME, but that program wasn't found on this system."
        if [[ -x "/usr/lib/command-not-found" ]]; then
            /usr/lib/command-not-found "$1"
        else
            echo "It should be available for installation through your system's software repositories."
        fi
        exit 108
    fi
}

check_installed "bwrap"
check_installed "printf"
check_installed "realpath"
check_installed "id"
check_installed "openssl"
check_installed "sha384sum"
check_installed "sha256sum"
check_installed "comm"
check_installed "sort"
check_installed "uniq"
check_installed "tr"
check_installed "sed"
check_installed "cat"
check_installed "tcc"
