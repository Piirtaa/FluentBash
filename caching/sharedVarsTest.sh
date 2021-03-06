#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript caching/sharedVars.sh


OK()      { echo -e "[\e[01;32m  OK  \e[0m]"; }
FAILED()  { echo -e "[\e[01;31mFAILED\e[0m]"; }
RESULT()  { [ $? == 0 ] && OK || FAILED; }

TEST_COUNT=0

# Usage: TESTCASE [description string]
function TESTCASE() {
    ((TEST_COUNT++))
	printf "%3s %-50s" "$TEST_COUNT" "$1"
}

echo
echo RUN ALL TEST CASES:
echo ===================

rm dumpfile

TESTCASE 'set var in a subshell and load it in the parent shell'
	$(BOB="i'm bob";  shareVar dumpfile BOB;)
	doUpdate dumpfile		
	[ "$BOB" == "i'm bob" ]
	RESULT

TESTCASE 'remove var in a subshell and load it in the parent shell'
	unset BOB	
	$(unshareVar dumpfile BOB;)
	doUpdate dumpfile		
	[ "$BOB" == "" ]
	RESULT
