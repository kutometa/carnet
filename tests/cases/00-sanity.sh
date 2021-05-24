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

environment_one() {
    set -euH
    set -o pipefail
    export CARNET_UNSTABLE_RSA_BITS="1024"
    export CARNET_PUBLISHER_NAME="TEST NAME"
    export CARNET_PUBLISHER_EMAIL="TEST_EMAIL"
    export CARNET_PUBLISHER_ORG="ORGANIZATION"
    export CARNET_PUBLISHER_COUNTRY="KW"
    
    -- "[LINENO:$LINENO]" "Agree to EULA and set up new user at the same time"
    ACTIVE_USER="userA" 
    run "0" "$CARNET_PATH" --carnet:config-dir="../configs/$ACTIVE_USER" enable "eula-agreement"  
    
    -- "[LINENO:$LINENO]" "Construct a new cate through carnet"
    ACTIVE_USER="userA" 
    run "0" "$CARNET_PATH" --carnet:config-dir="../configs/$ACTIVE_USER" new "lib1" --lib
    
    -- "[LINENO:$LINENO]" "Cargo fails because the crate already exists"
    ACTIVE_USER="userA"
    run "101" "$CARNET_PATH" --carnet:config-dir="../configs/$ACTIVE_USER" new "lib1" --lib
    
    cd "lib1"
    
    -- "[LINENO:$LINENO]" "Carnet fails because it isn't sealed yet"
    ACTIVE_USER="userA"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    
    -- "[LINENO:$LINENO]" "Seal the crate"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    
    -- "[LINENO:$LINENO]" "Verify the crate explicitly"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" verify
    
    -- "[LINENO:$LINENO]" "Edit src/lib.rs"
    echo "#[test] fn new_testing_function() { assert_eq!(9,9); } " >> "src/lib.rs"
    
    -- "[LINENO:$LINENO]" "Carnet fails because the change wasn't signed. The user must sign it or start a dev session"
    ACTIVE_USER="userA"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "Seal the crate"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    
    -- "[LINENO:$LINENO]" "Run tests which should pass"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "Edit src/lib.rs again"
    echo "#[test] fn new_testing_function_2() { assert_eq!(9,9); } " >> "src/lib.rs"
    
    -- "[LINENO:$LINENO]" "Tests should fail again"
    ACTIVE_USER="userA"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "This time start a dev session"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --config-dir="../../configs/$ACTIVE_USER" edit
    
    -- "[LINENO:$LINENO]" "Then run tests which should work"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "Set dev duration to 2 seconds"
    echo "2" > "../../configs/$ACTIVE_USER/session.duration"
    
    -- "[LINENO:$LINENO]" "Then run tests which should still work provided it runs withing 1 second of the last test"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "Sleep 2.6 seconds"
    sleep 2.6
    
    -- "[LINENO:$LINENO]" "Run tests again which should fail because dev session has expired"
    ACTIVE_USER="userA"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "Seal changes"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    
    -- "[LINENO:$LINENO]" "Test one more time.."
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "Agree to EULA for new user 'userB' and set up new user at the same time"
    ACTIVE_USER="userB"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" enable "eula-agreement"  
    
    -- "[LINENO:$LINENO]" "Test with new user 'userB' which should propmt the user to trust the new crate. we will decline first"
    ACTIVE_USER="userB"
    set +o pipefail
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test   < <(echo "no" )
    
    -- "[LINENO:$LINENO]" "Test with new user 'userB', but this time we accept"
    ACTIVE_USER="userB"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test  < <( echo "yes" )
    
    -- "[LINENO:$LINENO]" "UserB attempts to add a new test and then runs the tests without signing the crate which should fail"
    ACTIVE_USER="userB"
    echo "#[test] fn new_testing_function_3() { assert_eq!(1,1); } " >> "src/lib.rs"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "UserB attempts to seal the crate but the user isn't an owner which should fail"
    ACTIVE_USER="userB"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    
    -- "[LINENO:$LINENO]" "UserB attempts to own the crate"
    ACTIVE_USER="userB"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" own
    
    -- "[LINENO:$LINENO]" "UserB attempts to test the crate again but it fails again because he hasn't sealed it yet.. bless"
    ACTIVE_USER="userB"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "So he seals it and then runs the tests"
    ACTIVE_USER="userB"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    
    -- "[LINENO:$LINENO]" "Now comes USER-A wanting to work on his crate, but he's in for a big suprise"
    ACTIVE_USER="userA"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "Upon diffing the changes, A decided to trust B"
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    
    -- "[LINENO:$LINENO]" "Agree to EULA for new user 'userB' and set up new user at the same time"
    ACTIVE_USER="userC"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" enable "eula-agreement"  
    
    -- "[LINENO:$LINENO]" "But what's this! In comes C, steathely adding his key to the whitelist directory, will he succeed? Let's find out..."
    ACTIVE_USER="userC"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test   < <(echo "yes" ) # To generate the pub key for C
    C_CERT="../../configs/$ACTIVE_USER/identity.cert"
    C_IDENT="$(sha384sum -- "$C_CERT" | cut -d ' ' -f 1 | head -c 20)"
    run "0" cp "../../configs/$ACTIVE_USER/identity.cert" ".carnet/owners/$C_IDENT.cert"
    
    
    #TODO make blacklisting a carnet action
    -- "[LINENO:$LINENO]" "UserA attempts to test his crate but finds C's key. He doesn't take kindly to this and removes it." 
    ACTIVE_USER="userA"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    ACTIVE_USER="userB"
    run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" verify
    
    run "0" rm ".carnet/owners/$C_IDENT.cert" 
    ACTIVE_USER="userA"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    ACTIVE_USER="userB"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" verify
    
    # -- "Being the compuslive tester that C is, he was estatic about the prospect of inserting tons of useless tests into the project"
    # ACTIVE_USER="userC"
    # run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" own
    # echo "// Useless tests were clipped for A's benift" > "src/useless.rs" # He isn't a very good rust developer and forgot to add the module to lib.rs. 
     
    # # First verification works because the blacklisted key isn't been copied into the cache until the crate is varified
    # # this is currently an implementation detail and might be changed in the future
    # run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    # run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" seal
    
    
    # -- "verification fails for userA and userB"
    # ACTIVE_USER="userA"
    # run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" verify
    # ACTIVE_USER="userB"
    # run "107" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" verify
    
    
}

test_environment environment_one "Basic Sanity" "Random tests with no rhyme or methodology behind them." 
