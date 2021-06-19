#!/bin/bash
#
#  Carnet © 2021 Kutometa SPC, Kuwait
# 
#  Unless otherwise expressly stated, this work and all related 
#  material are made available to you under the terms of version 3 
#  of the GNU Lesser General Public License (hereinafter, the 
#  LGPL-3.0) and the following supplemental terms:
#
#  1. This work must retain all legal notices. These notices must 
#     not be altered or truncated in any way.
#
#  2. The origin of any derivative or modified versions of this 
#     work must not be presented in a way that may mislead a 
#     reasonable person into mistaking the derive work to originate 
#     from Kutometa or the authors of this work.
#
#  3. Derivative or modified versions of this work must be clearly 
#     and easily distinguishable from the original work by a 
#     reasonable person.
#     
#  4. Unless express permission is granted in writing, The name of 
#     the original work may not be used within the name of any 
#     derivative or modified version of the work.
#
#  5. Unless express permission is granted in writing, Trade names, 
#     trademarks, and service marks used in this work may not be 
#     included in any derivative or modified versions of this work.
#     
#  6. Unless express permission is granted in writing, the names and
#     trademarks of Kutometa and other right holders may not be used
#     to endorse derivative or modified versions of this work.
#
#  7. The licensee must defend, indemnify, and hold harmless 
#     Kutometa and authors of this software from any and all 
#     actions, claims, judgments, losses, penalties, liabilities, 
#     damages, expenses, demands, fees (including, but not limited 
#     to, reasonable legal and other professional fees), taxes, and 
#     cost that result from or in connection with any liability 
#     imposed on Kutometa or other authors of this software as a 
#     result of the licensee conveying this work or a derivative 
#     thereof with contractual assumptions of liability to a third 
#     party recipient.
#
#  Unless expressly stated otherwise or required by applicable law, 
#  this work is provided AS-IS with NO WARRANTY OF ANY KIND, 
#  INCLUDING THE WARRANTY OF MERCHANTABILITY AND FITNESS FOR A
#  PARTICULAR PURPOSE. Use this work at your own risk.
#
#  This license agreement is governed by and is construed in 
#  accordance with the laws of the state of Kuwait. You must submit 
#  all disputes arising out of or in connection with this work to 
#  the exclusive jurisdiction of the courts of Kuwait.
#
#  You should have received a copy of the LGPL-3.0 along with this 
#  program; if not, visit www.ka.com.kw/en/legal, write to 
#  legal@ka.com.kw, or write to Kutometa SPC, 760 SAFAT 13008, 
#  Kuwait.
#


source "misc/warning-message.sh"       
source "init.sh"       
source "trap.sh"
source "io.sh"
source "dependencies.sh"
source "fingerprint.sh"
source "help.sh"
source "trust.sh"
source "packaging.sh"
source "ownership.sh"
source "identity.sh"
source "configuration.sh"
source "authentication.sh"
source "session.sh"
source "sandboxing.sh"
#source "commands/authentication.sh"



# Find Cargo Directory 
KNOWN_CRATE_STATE=""                    # If set to 'found', the crate has been
                                        # 'seen'/registered by carnet on this system

KNOWN_CRATE_PATH="."                    # Presumed root of carnet-initialized crate 
                                        # root. This value is an untrustworthy 
                                        # assumption unless KNOWN_CRATE_STATE is set 
                                        # to "found".

KNOWN_CRATE_PATH_HASH=""                # Presumed path hash of carnet-initialized crate 
                                        # root. This value is an untrustworthy 
                                        # assumption unless KNOWN_CRATE_STATE is set 
                                        # to "found".
                                        #
                                        # path hashes are what carnet uses to track 
                                        # seen/registered crates on this system
                                        
KNOWN_CRATE_ORIGIN="foreign"            # Can be 'foreign', 'local', '', or any 
                                        # other value. Used for crate authentication
                                        # and signing (sealing).
                                        
SANDBOX_ALL="yes"                       # If yes, apply the most restrictive sandboxing 
                                        # possible. This includes sandboxing resources 
                                        # that aren't currently controllable by the user.
                                        #
                                        # You need to set this to no whenever granularity 
                                        # is needed.
                                                        
SANDBOX_FILESYSTEM="yes"

SANDBOX_NETWRORK="yes"

SANDBOX_PROCESSES="yes"

SANDBOX_SESSION="yes"

SANDBOX_CARGO_HOME="yes"

SANDBOX_RO_PATHS=""

SANDBOX_RW_PATHS=""

USERCONFIGDIR="$HOME/.config/kw.com.ka.$PROJECT_NAME" # Where "seen"/registered crates are tracked, user keys are stored, and all other "user" state maintained. 

DISABLE_AUTOVERIFICATION="no"           # Disables automatic verification.
                                        # Manually set to yes when the appropriate 
                                        # flag is given, and automatically set to yes
                                        # when the appropriate user configuration 
                                        # setting is set or when a dev session is active.

DISABLE_SANDBOX="no"                    # Disables sandboxing (bypassing bublewrap entirely)
                                        # Manually set to yes when the appropriate 
                                        # flag is given, and automatically set to yes
                                        # when the appropriate user configuration 
                                        # setting is set.

COMMAND=""                              # The primary command carnet is supposed to execute.

NEW_DEV_SESSION="no"                    # If set to yes, automatically start/extend a dev 
                                        # session where autoverification is set to no.

LOCAL_IDENTITY_CERT_PATH=""             # The certificate used for signatures when sealing
                                        # a local crate. 

LOCAL_IDENTITY_PUBKEY_PATH=""           # The public key used when sealing
                                        # a local crate. You should remove this in favor 
                                        # of maintaining a single source of truth 
                                        # LOCAL_IDENTITY_CERT_PATH
                                        
LOCAL_IDENTITY_PRIVKEY_PATH=""          # The private key used for signatures when sealing
                                        # a local crate. 
                                        
LOCAL_IDENTITY_FINGERPRINT=""           # The local identity fingerprint used when sealing
                                        # a local crate. 
                                        
PINNED_OWNER_IDENTITY_FINGERPRINT=""    # If set, only verify crates against this identity 
                                        # and no other when verifying crates.

declare -a UNHANDLED_NON_OPTIONS;       # Any non-option (not prefixed by a dash) 
                                        # that isn't consumed by carnet. '--cargo:'-style 
                                        # flags are converted to their unprefixed counterparts
                                        
declare -a FILTERED_ARGS                # All arguments that aren't consumed by carnet. This
                                        # array is a superset of UNHANDLED_NON_OPTIONS.
                                        # '--cargo:'-style flags are converted to their 
                                        # unprefixed counterparts.
                                        
END_OF_OPTIONS="no"                     # Used when processing cli args. If set to 'yes', 
                                        # treat args as opaque strings, possibly passing 
                                        # them to cargo as-is with the exception of 
                                        # '--cargo:' style flags which are converted to
                                        # normal cargo flags.

# Sort CLI arguments. Set appropriate flags/vars if args are relevant or sort them into FILTERED_ARGS and UNHANDLED_NON_OPTIONS buckets
for arg in "$@"; do
    if   [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:disable-sandbox" ]] || [[ "$arg" == "--disable-sandbox" ]] ); then
        DISABLE_SANDBOX="yes"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:disable-verification" ]] || [[ "$arg" == "--disable-verification" ]] ); then
        DISABLE_AUTOVERIFICATION="yes"
    
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:unsandbox-cargo-home" ]] || [[ "$arg" == "--unsandbox-cargo-home" ]] ); then
        SANDBOX_CARGO_HOME="no"
        SANDBOX_ALL="no"
    
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:unsandbox-filesystem" ]] || [[ "$arg" == "--unsandbox-filesystem" ]] ); then
        SANDBOX_FILESYSTEM="no"
        SANDBOX_ALL="no"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:unsandbox-processes" ]] || [[ "$arg" == "--unsandbox-processes" ]] ); then
        SANDBOX_PROCESS="no"
        SANDBOX_ALL="no"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:unsandbox-network" ]] || [[ "$arg" == "--unsandbox-network" ]] ); then
        SANDBOX_NETWORK="no"
        SANDBOX_ALL="no"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:unsandbox-session" ]] || [[ "$arg" == "--unsandbox-session" ]] ) ; then
        SANDBOX_SESSION="no"
        SANDBOX_ALL="no"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ( [[ "$arg" == "--$PROJECT_NAME:verbose" ]] || [[ "$arg" == "--verbose" ]] ); then
        DEBUG="yes"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--$PROJECT_NAME:config-dir= ]]; then
        USERCONFIGDIR="${arg:20}"
        if ! [[ -d "$(dirname "$USERCONFIGDIR" 2>/dev/null || true)" ]]; then
            fatal "Cannot find parent directory for '$USERCONFIGDIR'"
        fi
        USERCONFIGDIR="$(realpath -- "${USERCONFIGDIR}")"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--config-dir= ]]; then
        USERCONFIGDIR="${arg:13}"
        if ! [[ -d "$(dirname "$USERCONFIGDIR" 2>/dev/null || true)" ]]; then
            fatal "Cannot find parent directory for '$USERCONFIGDIR'"
        fi
        USERCONFIGDIR="$(realpath -- "${USERCONFIGDIR}")"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--$PROJECT_NAME:pinned-owner= ]]; then
        PINNED_OWNER_IDENTITY_FINGERPRINT="${arg:22}"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--pinned-owner= ]]; then
        PINNED_OWNER_IDENTITY_FINGERPRINT="${arg:15}"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--$PROJECT_NAME:ro-paths= ]]; then
        SANDBOX_RO_PATHS="${arg:18}"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--ro-paths= ]]; then
        SANDBOX_RO_PATHS="${arg:11}"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--$PROJECT_NAME:rw-paths= ]]; then
        SANDBOX_RW_PATHS="${arg:18}"
    
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" =~ ^--rw-paths= ]]; then
        SANDBOX_RW_PATHS="${arg:11}"
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "--$PROJECT_NAME:help" ]] || [[ "$arg" == "$PROJECT_NAME:help" ]] ) ; then
        if ! [[ "${COMMAND}" ]]; then COMMAND="help"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "--help" ]] || [[ "$arg" == "help" ]] || [[ "$arg" == "-h" ]]) ; then
        if ! [[ "${COMMAND}" ]]; then COMMAND="cargo-help"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:sandbox-run" ]] || [[ "$arg" == "sandbox-run" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="sandbox-run"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:seal" ]] || [[ "$arg" == "seal" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="seal"; fi
    
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:disable" ]] || [[ "$arg" == "disable" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="disable"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:enable" ]] || [[ "$arg" == "enable" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="enable"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:verify" ]] || [[ "$arg" == "verify" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="verify"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:owners" ]] || [[ "$arg" == "owners" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="list-owners"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:files" ]] || [[ "$arg" == "files" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="list-seal-files"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:own" ]] || [[ "$arg" == "own" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="own"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:disown" ]] || [[ "$arg" == "disown" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="disown"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:distrust" ]] || [[ "$arg" == "distrust" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="distrust"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:init" ]] || [[ "$arg" == "init" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="init"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:uninit" ]] || [[ "$arg" == "uninit" ]] ) ; then
        if ! [[ "${COMMAND}" ]]; then COMMAND="uninit"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:identity" ]] || [[ "$arg" == "identity" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="identity"; fi
    
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "--$PROJECT_NAME:version" ]] || [[ "$arg" == "--version" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="version"; fi
    
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "--$PROJECT_NAME:legal" ]] || [[ "$arg" == "--legal" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="legal"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:edit" ]] || [[ "$arg" == "edit" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="edit"; fi
    
    elif [[ "$END_OF_OPTIONS" == "no" ]] && ! [[ "${COMMAND}" ]] && ( [[ "$arg" == "$PROJECT_NAME:done" ]] || [[ "$arg" == "done" ]] ); then
        if ! [[ "${COMMAND}" ]]; then COMMAND="done"; fi
        
    elif [[ "$END_OF_OPTIONS" == "no" ]] && [[ "$arg" == "--$PROJECT_NAME:end" ]]; then
        END_OF_OPTIONS="yes"
        
    else 
        if [[ "$arg" == "--" ]]; then
            END_OF_OPTIONS="yes"
        fi
        # strip namespaced cargo args
        if [[ "$END_OF_OPTIONS" == "no" ]]; then
            arg="$(printf "%s\n" "$arg" | sed 's/^--cargo:/--/g' | sed 's/^cargo://g')"
        fi
        # collect a copy of arg in UNHANDLED_NON_OPTIONS if it isn't a flag
        if ! [[ "$arg" =~ ^- ]]; then
            UNHANDLED_NON_OPTIONS=("${UNHANDLED_NON_OPTIONS[@]}" "$arg")
        fi
        FILTERED_ARGS=( "${FILTERED_ARGS[@]}" "$arg" ) 
    fi
done

if ! [[ "${CARGO_PATH-}" ]]; then 
    CARGO_PATH=$(which "cargo") || {
        fatal "Could not find cargo in PATH."
    }
fi

debug "Carnet command selected was '$COMMAND'. If empty, this means that this is a direct cargo pass though.";

if [[ "$COMMAND" == "cargo-help" ]] || [[ "$#" -eq 0 ]]; then
    # TODO sandbox 
    "$CARGO_PATH" "help"
    printf "%s\n\n" "See '$PROJECT_NAME $PROJECT_NAME:help' or '$PROJECT_NAME --$PROJECT_NAME:help' for more information about options and commands that are specific to carnet."
    exit 0
elif [[ "$COMMAND" == "help" ]]; then
    printf "$HELP\n" | less -R
    exit 0
elif [[ "$COMMAND" == "version" ]]; then
    echo "$PROJECT_NAME $PROJECT_VERSION ($PROJECT_DATE NCA)"
    # TODO sandbox 
    "$CARGO_PATH" version
    exit 0
elif [[ "$COMMAND" == "legal" ]]; then
    echo "$COPYRIGHT_BLURB"
    exit 0

fi

if ! [[ -d "$USERCONFIGDIR" ]]; then
    debug "Could not find identity directory '$USERCONFIGDIR'. Setting up new identity..."
    printf "
    This appears to be the first time Carnet runs on this system. 
    Before you continue, you need to provide some information to 
    generate a new identity for you. This information is shown to 
    other users when they attempt to verify your crates for the first
    time.
    
    This information cannot be changed once the identity has been 
    generated.
    "
    
    if ! [[ "${CARNET_PUBLISHER_NAME-}" ]]; then 
        while true; do
            printf "
    What is your name?

    [                                                             ]\r    [ "
            read -r CARNET_PUBLISHER_NAME
            if [[ "$CARNET_PUBLISHER_NAME" ]]; then
                break
            else
                printf "\n"
                warn "A name is needed to generate a new Identity."
            fi
        done
    fi
    
    
    if ! [[ "${CARNET_PUBLISHER_EMAIL-}" ]]; then 
        while true; do
            printf "
    What email address would you like to include?

    [                                                             ]\r    [ "
            read -r CARNET_PUBLISHER_EMAIL
            if [[ "$CARNET_PUBLISHER_EMAIL" ]]; then
                break
            else
                printf "\n"
                warn "An email address is needed to generate a new Identity."
            fi
        done
    fi
    
    
    if ! [[ "${CARNET_PUBLISHER_ORG-}" ]]; then 
    printf "
    What is the name of your organization? (You can leave this empty)

    [                                                             ]\r    [ "
    read -r CARNET_PUBLISHER_ORG
    fi
    
    
    if ! [[ "${CARNET_PUBLISHER_COUNTRY-}" ]]; then 
    printf "
    What is the two-letter ISO code of your country? (You can leave 
    this empty)

    [                                                             ]\r    [ "
    read -r CARNET_PUBLISHER_COUNTRY
    fi
    
    
    
    mkdir -p "$USERCONFIGDIR"
    chmod 700 "$USERCONFIGDIR"
    printf "%s\n" "Generating new identity keys.."
    
    x509_escape() {
        printf "%s\n" "$1" | sed -E 's/([\/,;])/\\\1/g'
    }
    X509_CN="/CN=$(x509_escape "$CARNET_PUBLISHER_NAME")"
    X509_EMAIL="/emailAddress=$(x509_escape "$CARNET_PUBLISHER_EMAIL")"
    X509_O=""
    if [[ "$CARNET_PUBLISHER_ORG" ]]; then
        X509_O="/O=$(x509_escape "$CARNET_PUBLISHER_ORG")"
    fi
    X509_C=""
    if [[ "$CARNET_PUBLISHER_COUNTRY" ]]; then
        X509_C="/C=$(x509_escape "$CARNET_PUBLISHER_COUNTRY")"
    fi
    
    if [[ "${CARNET_UNSTABLE_RSA_BITS-}" ]]; then
        warn "WARNING: rsa key length is set to ${CARNET_UNSTABLE_RSA_BITS}"
    fi
    
    if ! openssl req -x509 \
                -newkey "rsa:${CARNET_UNSTABLE_RSA_BITS:-8192}" \
                -utf8 \
                -nameopt multiline,utf8 \
                -keyout "$USERCONFIGDIR/identity.key" \
                -out "$USERCONFIGDIR/identity.cert" \
                -days 100000 \
                -sha384 \
                -nodes \
                -subj "${X509_CN}${X509_EMAIL}${X509_O}${X509_C}" \
                -addext "keyUsage = digitalSignature" \
                -addext "extendedKeyUsage = codeSigning" \
                1>&2; then
                #-subj "/" 1>&2; then
        fatal "Failed to generate a new certificate"
    fi
    openssl x509 -pubkey -noout -in "$USERCONFIGDIR/identity.cert" > "$USERCONFIGDIR/identity.pub"
    chmod 600 "$USERCONFIGDIR/identity.key"
fi

LOCAL_IDENTITY_CERT_PATH="$USERCONFIGDIR/identity.cert"
LOCAL_IDENTITY_PUBKEY_PATH="$USERCONFIGDIR/identity.pub"
LOCAL_IDENTITY_PRIVKEY_PATH="$USERCONFIGDIR/identity.key"
LOCAL_IDENTITY_FINGERPRINT="$( file_fingerprint "$LOCAL_IDENTITY_CERT_PATH")"

CONFIGURATION_DISABLED_VERIFICATION_PATH="$USERCONFIGDIR/settings/verification.setting"
CONFIGURATION_DISABLED_SANDBOXING_PATH="$USERCONFIGDIR/settings/sandbox.setting"
CONFIGURATION_EULA_AGREEMENT_PATH="$USERCONFIGDIR/settings/eula-agreement.setting"
CONFIGURATION_DISABLED_VERIFICATION="$( if [[ -f "$CONFIGURATION_DISABLED_VERIFICATION_PATH" ]]; then cat "$CONFIGURATION_DISABLED_VERIFICATION_PATH"; fi )"
CONFIGURATION_DISABLED_SANDBOXING="$( if [[ -f "$CONFIGURATION_DISABLED_SANDBOXING_PATH" ]]; then cat "$CONFIGURATION_DISABLED_SANDBOXING_PATH"; fi )"
CONFIGURATION_EULA_AGREEMENT="$( if [[ -f "$CONFIGURATION_EULA_AGREEMENT_PATH" ]]; then cat "$CONFIGURATION_EULA_AGREEMENT_PATH"; fi )"


source "setup-and-upgrade-scripts.sh"


if [[ "${CONFIGURATION_DISABLED_VERIFICATION-}" == "disabled" ]]; then
    debug "Disabling automatic verification because ${CONFIGURATION_DISABLED_VERIFICATION_PATH} is set to disabled."
    DISABLE_AUTOVERIFICATION="yes"
fi

if [[ "${CONFIGURATION_DISABLED_SANDBOXING-}" == "disabled" ]]; then
    debug "Disabling sandbox because ${CONFIGURATION_DISABLED_SANDBOXING_PATH} is set to disabled."
    DISABLE_SANDBOX="yes"
fi



# Starting proper...
if [[ "$COMMAND" ]]; then
    if [[ "$COMMAND" == "sandbox-run" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        sandbox "${FILTERED_ARGS[@]}" || exit "$?"
    
    elif [[ "$COMMAND" == "enable" ]] || [[ "$COMMAND" == "disable" ]]; then
        configuration_settings "$COMMAND" "${FILTERED_ARGS[@]}"
        
    elif [[ "$COMMAND" == "help" ]]; then
        printf "$HELP\n" | less -R 1>&2
    
    elif [[ "$COMMAND" == "seal" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        if [[ "$KNOWN_CRATE_ORIGIN" != "local" ]]; then
            fatal "You cannot seal crates you don't own. To own this crate, run $PROJECT_NAME $PROJECT_NAME:own. ($KNOWN_CRATE_PATH)"
        fi
        seal
        verify
    elif [[ "$COMMAND" == "init" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        crate_root="${UNHANDLED_NON_OPTIONS[0]:-.}"
        if ! [[ -d "$crate_root" ]]; then
            fatal "'$crate_root' is not a directory"
        fi
        if ! [[ -f "$crate_root/Cargo.toml" ]]; then
            warn "'$crate_root' doesn't seem to be a rust crate (no Cargo.toml). Proceeding anyway."
        fi
        initialize_crate "$crate_root"
        trust_crate "$crate_root" 
        own_crate "$crate_root"
    elif [[ "$COMMAND" == "uninit" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        prompt_yes_no_and_require_yes "This command will remove this crate from" \
                      "your system's list of trusted crates. This"\
                      "command will also remove any cached"\
                      "identities. Would you like to proceed?"
        uninitialize_crate "${UNHANDLED_NON_OPTIONS[0]:-.}"
        
    elif [[ "$COMMAND" == "verify" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        verify
        
    elif [[ "$COMMAND" == "list-owners" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        if ! [[ "${KNOWN_CRATE_STATE-}" ]] ||  [[ "$KNOWN_CRATE_STATE" != "found" ]]; then
            fatal "Could not find a registered crate in '$PWD' or any parent directory"
        fi
        list_identities "$KNOWN_CRATE_PATH/.carnet/owners"
        printf "\n"
    elif [[ "$COMMAND" == "identity" ]]; then
        printf "Identity = ${LOCAL_IDENTITY_FINGERPRINT}"
        show_cert_information "$LOCAL_IDENTITY_CERT_PATH" "identity-mode" | sed -E 's/ +/ /g' | sed -E 's/^ //g'
        
    elif [[ "$COMMAND" == "list-seal-files" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        generate_crate_seal_list "sha384" "$KNOWN_CRATE_PATH" | tr '\n' '␤' | tr '\0' '\n' | cut -d ' ' -f 1
        
    elif [[ "$COMMAND" == "own" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        own_crate "${UNHANDLED_NON_OPTIONS[0]:-$KNOWN_CRATE_PATH}"
        
    elif [[ "$COMMAND" == "disown" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        disown_crate "${UNHANDLED_NON_OPTIONS[0]:-$KNOWN_CRATE_PATH}"
        
    elif [[ "$COMMAND" == "distrust" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        prompt_yes_no_and_require_yes "This command will remove this crate from" \
                      "your system's list of trusted crates. This"\
                      "command will also remove any cached" \
                      "identities. Would you like to proceed?"
        distrust_crate "${UNHANDLED_NON_OPTIONS[0]:-$KNOWN_CRATE_PATH}"
        
    elif [[ "$COMMAND" == "edit" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        NEW_DEV_SESSION="yes"
        refresh_dev_session

    elif [[ "$COMMAND" == "done" ]]; then
        KNOWN_CRATE_PATH="."
        locate_known_crate_from_the_inside_and_set_up_global_variables
        clear_dev_session
    
    elif [[ "$COMMAND" == "version" ]]; then
        echo "$PROJECT_NAME $PROJECT_VERSION ($PROJECT_DATE NCA)"
        sandbox "$CARGO_PATH" version
    else
        fatal "INTERNAL BUG: Unknown $PROJECT_NAME command"
    fi
else
    KNOWN_CRATE_PATH="."
    locate_known_crate_from_the_inside_and_set_up_global_variables
    refresh_dev_session
    
    if [[ "${UNHANDLED_NON_OPTIONS[0]-}" == "new" ]]; then
        
        sandbox "$CARGO_PATH" "${FILTERED_ARGS[@]}" || exit "$?"
        
        if ! [[ "${UNHANDLED_NON_OPTIONS[1]-}" ]] || ! [[ -f "${UNHANDLED_NON_OPTIONS[1]}/Cargo.toml" ]]; then 
            fatal "Carnet has failed to setup your new crate properly. You can try to use cargo directly and then run $PROJECT_NAME carnet:init manually inside your new crate. Please consider reporting this issue if you can reproduce it."
             Please consider reporting this issue.
        fi
        initialize_crate "${UNHANDLED_NON_OPTIONS[1]}"
        trust_crate "${UNHANDLED_NON_OPTIONS[1]}"
        own_crate "${UNHANDLED_NON_OPTIONS[1]}"
        
        if ! [[ "${UNHANDLED_NON_OPTIONS[1]-}" ]] || ! [[ -d "${UNHANDLED_NON_OPTIONS[1]}/.carnet" ]]; then 
            fatal "Carnet has failed to setup your new crate properly. Try to run $PROJECT_NAME carnet:init manually inside your new crate. Please consider reporting this issue if you can reproduce it."
        fi
    elif [[ "${UNHANDLED_NON_OPTIONS[0]-}" == "version" ]]; then
        echo "$PROJECT_NAME $PROJECT_VERSION ($PROJECT_DATE NCA)"
        sandbox "$CARGO_PATH" version
    elif [[ "${UNHANDLED_NON_OPTIONS[0]-}" == "help" ]]; then
        sandbox "$CARGO_PATH" "${FILTERED_ARGS[@]}"
        printf "%s\n\n" "See '$PROJECT_NAME $PROJECT_NAME:help' or '$PROJECT_NAME --$PROJECT_NAME:help' for more information about the options and commands that are specific to Carnet."
    else
        if ! [[ "${KNOWN_CRATE_STATE-}" ]] ||  [[ "$KNOWN_CRATE_STATE" != "found" ]]; then
            fatal "Could not find a registered crate in current directory or any parent directory.\n See 'carnet new' and 'carnet init' commands."
        fi
        if [[ "$DISABLE_AUTOVERIFICATION" != "yes" ]]; then
            verify
        else
            ignored_step_message "Verifying" "Automatic verification is disabled"
        fi
        sandbox "$CARGO_PATH" "${FILTERED_ARGS[@]}" || exit "$?"
    fi
fi

exit 0


