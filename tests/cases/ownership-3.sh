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

[[ -e "$CARNET_PATH" ]] || {
    fatal "'$CARNET_PATH' is not an executable!"
}

testing_logic() {
    export CARNET_UNSTABLE_RSA_BITS="1024"
    export CARNET_PUBLISHER_NAME="TEST NAME"
    export CARNET_PUBLISHER_EMAIL="TEST_EMAIL"
    export CARNET_PUBLISHER_ORG="ORGANIZATION"
    export CARNET_PUBLISHER_COUNTRY="KW"
    
    -- "[LINENO:$LINENO]" "Agree to EULA for new user setup at the same time"
    ACTIVE_USER="ORIGINAL_OWNER"
    run "0" "$CARNET_PATH" --carnet:config-dir="../configs/$ACTIVE_USER" enable "eula-agreement"  
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER new crate"
    ACTIVE_USER="ORIGINAL_OWNER" 
    run "0" "$CARNET_PATH" --carnet:config-dir="../configs/$ACTIVE_USER" new "lib1" --lib
    
    cd "lib1"
    
    run "0" "$CARNET_PATH" --config-dir="../../configs/$ACTIVE_USER" edit
    
    run "0" "$CARNET_PATH" --config-dir="../../configs/$ACTIVE_USER" test
    
    run "0" "$CARNET_PATH" --config-dir="../../configs/$ACTIVE_USER" seal
    
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" new "vendor/sublib1" --lib
    
    cd "vendor/sublib1"
    
    run "0" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" seal
    run "0" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" test
    echo "pub fn add(a: usize, b: usize) -> usize { a + b } " > "src/lib.rs"
    echo "#[test] fn add_test() { assert_eq!(add(1,2), 3); } " >> "src/lib.rs"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" test
    run "0" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" edit
    run "0" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" test
    run "0" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" done
    run "0" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" seal
    cd "../.."
    
    run "0" "$CARNET_PATH" --config-dir="../../configs/$ACTIVE_USER" test
    echo "sublib1 = { path=\"vendor/sublib1\" }" >> "Cargo.toml"
    cat > "src/lib.rs" <<DD
    extern crate sublib1;
    #[test]
    fn testing_submodules() {
        assert_eq!(sublib1::add(1,2), 3);
    }
DD
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" done
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" verify 
    
    
    -- "[LINENO:$LINENO]" "Agree to EULA for new user setup at the same time"
    ACTIVE_USER="USER"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" enable "eula-agreement"  
    
    ACTIVE_USER="USER" 
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test < <(printf "yes\n")
    
    cd "vendor/sublib1"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" verify < <(printf "no\n")
    run "0" "$CARNET_PATH" --carnet:config-dir="../../../../configs/$ACTIVE_USER" verify < <(printf "yes\n")
    cd ".."
}

test_environment testing_logic   "Ownership of subcrates" "-"
