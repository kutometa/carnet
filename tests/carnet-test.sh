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

source "common.sh"

    
if ! CARNET_PATH=$(which "${CARNET_PATH:-$(realpath ../carnet)}"); then
    fatal "Could not find carnet on this path"
else
    step "BINARY" "found carnet executable at '$CARNET_PATH'. Set CARNET_PATH to override."
fi
    
export CARNET_PATH


run_case() {
    if [[ -f "$1" ]]; then
        RESULT=0
        # bash -- "$1" 2>/dev/null || RESULT="$?"
        bash -- "$1" || RESULT="$?"
        if [[ "$RESULT" != 0 ]]; then
            fatal "Test case '$1' has failed. set FAIL_SHELL to yes to drop into a shell inside the test's env."
        else
            step "PASS" "Test case '$1' has passed."
        fi
    else
        fatal "Test case '$1' is not a file."
    fi
}



if [[ "${1-}" ]]; then
    step "STARTING UP" "running test 'cases/$1.sh'.."
    if [[ -f "cases/$1.sh" ]]; then
        run_case "cases/$1.sh"
    else    
        fatal "Test cases/$1.sh does not exist"
    fi
else
    step "STARTING UP"  "running all tests in 'cases/'.."
    for case in "cases/"*; do
        case_name="$(basename "$case")"
        if [[ "${case_name::12}" == "0000-ignored" ]] && [[ "${TEST_IGNORED-}" == "" ]]; then
            step "ignored" "$case_name"
        else
            run_case "$case"
        fi
    done
fi





step "DONE" "all tests have passed."
