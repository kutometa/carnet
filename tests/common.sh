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

set -euH
set -o pipefail


if [[ -t 2 ]]; then
    RED="\e[1;31m"
    GREEN="\e[1;34m"
    YELLOW="\e[1;33m"
    WEIRD="\e[1;44m"
    DIM="\e[2m"
    BOLD="\e[1m"
    RESET="\e[0m"
fi



step() {
    printf "${GREEN}%12s${RESET} %s\n" "$1" "$2" 1>&2
}
substep() {
    printf "\n\n${DIM}TESTING_SCRIPTS :: Step: %s${RESET}\n" "$*" 1>&2
}
ignored_step() {
    printf "${YELLOW}%12s${RESET} %s\n" "$1" "$2" 1>&2
}

fatal() {
    printf "${RED-}TESTING SCRIPTS :: error${RESET-}${BOLD-}:${RESET-} ${DIM-} ${RESET-} $*\n"  1>&2
    exit 104
}

warn() {
    printf "${YELLOW-}TESTING SCRIPTS :: warning${RESET-}${BOLD-}:${RESET-} ${DIM-} ${RESET-} $*\n"  1>&2
}

debug() {
    if [[ "${DEBUG-}" == "yes" ]]; then
        printf "${DIM-}verbose:  -- $PROJECT_NAME --  $*${RESET-}\n"  1>&2
    fi
}

XX() {
    substep "$@"
}

--() {
    substep "$@"
}


test_environment() {
    step "$2" "$3"  1>&2
    local RESULT="0"
    local TESTDIR="$(mktemp -d)"
    (
        cd "$TESTDIR"
        mkdir "configs"
        mkdir "crates"
        cd "crates"
        "$1"
    ) || RESULT="$?"
    if [[ "$RESULT" != "0" ]] && [[ "${FAIL_SHELL-}" == "yes" ]]; then
        echo "Entering into interactive prompt..." 1>&2
        ( cd "$TESTDIR" && sh ) || true
    fi
    rm -r "$TESTDIR"
    return "$RESULT"
}


run() {
    local RESULT="0"
    local EXPECTED="$1"
    shift
    "$@" || RESULT="$?"
    if [[ "$RESULT" == "$EXPECTED" ]]; then
        printf "OKAY (expected $RESULT): %s\n" "$*" 1>&2
        return 0
    else
        fatal "ERROR (expected $EXPECTED but got $RESULT): $*"  1>&2
        return 1
    fi
}
