#!/bin/bash

#load loader first
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript jsSandbox/jsWrapper.sh

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

#start the shim to the repl
initREPL myREPL

TESTCASE 'callREPL myREPL < <(echo "var a=1;")=undefined'
	[ "$(callREPL myREPL < <(echo "var a=1;"))" == "undefined" ]
	RESULT	

TESTCASE 'callREPL myREPL < <(echo "a++;")=1'
	[ "$(callREPL myREPL < <(echo "a++;"))" == "1" ]
	RESULT	

TESTCASE 'callREPL myREPL < <(echo "a++;")=2'
	[ "$(callREPL myREPL < <(echo "a++;"))" == "2" ]
	RESULT	

TESTCASE 'callREPL myREPL < <(echo "a")=3'
	[ "$(callREPL myREPL < <(echo "a"))" == "3" ]
	RESULT	

disposeREPL myREPL 

initLEREPL myREPL

TESTCASE 'callREPL myREPL < <(echo "var a=1;")=undefined'
	[ "$(callREPL myREPL < <(echo "var a=1;"))" == "undefined" ]
	RESULT	

TESTCASE 'callREPL myREPL < <(echo "a++;")=1'
	[ "$(callREPL myREPL < <(echo "a++;"))" == "1" ]
	RESULT	

TESTCASE 'callREPL myREPL < <(echo "a++;")=2'
	[ "$(callREPL myREPL < <(echo "a++;"))" == "2" ]
	RESULT	

TESTCASE 'callREPL myREPL < <(echo "a")=3'
	[ "$(callREPL myREPL < <(echo "a"))" == "3" ]
	RESULT	

disposeREPL myREPL 




#more perfy test
#startMediator myREPL "$SANDBOX" repl
#sendInput myREPL silent < <(echo "var a=1;")
#for ((I=0 ; I< 10 ; I++)); do
#	sendInput myREPL silent < <(echo "a++;")
#done
#sendInput myREPL < <(echo "a")
#stopMediator myREPL

