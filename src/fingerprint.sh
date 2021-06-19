# path_fingerprint  STRING
#
# Generate a fingerprint from the first argument treated as a string
path_fingerprint() {
    realpath -- "$1" | sha384sum | cut -d ' ' -f 1 | head -c 24
}

# file_fingerprint  FILENAME
#
# Generate a fingerprint from the file pointed at by the path in the 
# first argument
file_fingerprint() {
    sha384sum -- "$1" | cut -d ' ' -f 1 | head -c 20
}

