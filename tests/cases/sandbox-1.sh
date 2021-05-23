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
    run "0" "$CARNET_PATH" --carnet:config-dir="../configs/$ACTIVE_USER" enable "eula-agreement"  < <(printf "yes\nyes\nyes\nyes\n")
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER new crate"
    ACTIVE_USER="ORIGINAL_OWNER" 
    run "0" "$CARNET_PATH" --carnet:config-dir="../configs/$ACTIVE_USER" new "lib1" --lib
    
    cd "lib1"
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER starts new dev session"
    ACTIVE_USER="ORIGINAL_OWNER" 
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" edit
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER test crate"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" test
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER checking filesystem sandbox, may take a while..."
    run "0" stat "/run/blkid/blkid.tab" > /dev/null
    run "1" stat "/run/blkid/blkid.tab.ne" > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run which stat
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run stat "/run/blkid/blkid.tab"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --unsandbox-filesystem stat "/run/blkid/blkid.tab" > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --disable-sandbox stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --ro-paths="/run/blkid/blkid.tab" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --ro-paths="/run/blkid" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --ro-paths="/run" stat "/run/blkid/blkid.tab" > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --rw-paths="/run/blkid/blkid.tab" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --rw-paths="/run/blkid" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --rw-paths="/run" stat "/run/blkid/blkid.tab" > /dev/null
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --rw-paths="/run" stat "/run/blkid/blkid.tab.ne" > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:ro-paths="/run/blkid/blkid.tab" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:ro-paths="/run/blkid" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:ro-paths="/run" stat "/run/blkid/blkid.tab" > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:rw-paths="/run/blkid/blkid.tab" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:rw-paths="/run/blkid" stat "/run/blkid/blkid.tab"  > /dev/null
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:rw-paths="/run" stat "/run/blkid/blkid.tab" > /dev/null
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:rw-paths="/run" stat "/run/blkid/blkid.tab.ne" > /dev/null
    
    TESTFILE="$(mktemp)" # messy
    echo "0" > "$TESTFILE"
    run "0" bash -c "[[ \$(cat '$TESTFILE') == '0' ]]"
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run bash -c "[[ \$(cat '$TESTFILE') == '0' ]]"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --unsandbox-filesystem bash -c "[[ \$(cat '$TESTFILE') == '0' ]]"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --unsandbox-filesystem bash -c "echo '1' >'$TESTFILE'"
    run "0" bash -c "[[ \$(cat '$TESTFILE') == '1' ]]"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --unsandbox-filesystem bash -c "[[ \$(cat '$TESTFILE') == '1' ]]"
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run bash -c "[[ \$(cat '$TESTFILE') == '1' ]]"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:ro-paths="$TESTFILE" bash -c "[[ \$(cat '$TESTFILE') == '1' ]]"
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:ro-paths="$TESTFILE" bash -c "echo '2' >'$TESTFILE'"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:ro-paths="$TESTFILE" bash -c "[[ \$(cat '$TESTFILE') == '1' ]]"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:rw-paths="$TESTFILE" bash -c "echo '2' >'$TESTFILE'"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --carnet:ro-paths="$TESTFILE" bash -c "[[ \$(cat '$TESTFILE') == '2' ]]"
    run "0" bash -c "[[ \$(cat '$TESTFILE') == '2' ]]"
    rm "$TESTFILE"
    
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER checking process sandboxing, may take a while..."
    # Racy but should pass on most systems most of the time 
    SLEEP_PID="---"
    start_sleep() {
        sleep 10d &
        SLEEP_PID="$!"
    }
    start_sleep
    run "0" test -d "/proc/$SLEEP_PID"
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run test -d "/proc/$SLEEP_PID"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --unsandbox-processes test -d "/proc/$SLEEP_PID"
    run "1" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run kill "$SLEEP_PID"
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --unsandbox-processes kill "$SLEEP_PID"
    
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER checking network sandbox, may take a while..."
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run which wget
    run "4" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run wget 'http://www.example.com'
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --unsandbox-network wget 'http://www.example.com'
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run --disable-sandbox wget 'http://www.example.com'
    
    
    -- "[LINENO:$LINENO]" "ORIGINAL_OWNER testing terminal/session isolation"
    # Federico Bento's poc:
    gcc -o "escape.bin" -x c - <<ESCAPE
#include <unistd.h>
#include <sys/ioctl.h>
#include <termios.h>

int main()
{
  char *c = "echo \"Escaped from sandbox!\"\n";
  while(*c) ioctl(0, TIOCSTI, c++);
  return 0;
}
ESCAPE
    # assumes an tty input buffer, so disabled 
    #run "0" ./escape.bin
    #read -r INJECTED; # Reads from terminal buffer. Don't type anyting.
    #run "0" test "$INJECTED" == "echo \"Escaped from sandbox!\""
    ACTIVE_USER="ORIGINAL_OWNER" 
    run "0" "$CARNET_PATH" --carnet:config-dir="../../configs/$ACTIVE_USER" sandbox-run ./escape.bin
    run "1" test -f "escaped"
}

test_environment testing_logic   "Testing the sandbox" "This preforms a few santiy tests to check that the sandbox is doing its job"
