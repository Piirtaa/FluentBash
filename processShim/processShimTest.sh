#!/bin/bash

#load loader first
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript processShim/processShim.sh

SANDBOX=$(getScriptPath jsSandbox/sandbox_spidermonkey.js) 


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
startShim myREPL "$SANDBOX" repl

#test that the temp files used by the shim exist
TESTCASE 'ls callShimmyREPL.sh=callShimmyREPL.sh'
	[ "$(ls callShimmyREPL.sh)" == "callShimmyREPL.sh" ]
	RESULT	

TESTCASE 'ls myREPL.log=myREPL.log'
	[ "$(ls myREPL.log)" == "myREPL.log" ]
	RESULT	
	
TESTCASE 'ls myREPLOUT=myREPLOUT'
	[ "$(ls myREPLOUT)" == "myREPLOUT" ]
	RESULT	
	
TESTCASE 'ls myREPLIN=myREPLIN'
	[ "$(ls myREPLIN)" == "myREPLIN" ]
	RESULT	
	
TESTCASE 'ls disposemyREPL.sh=disposemyREPL.sh'
	[ "$(ls disposemyREPL.sh)" == "disposemyREPL.sh" ]
	RESULT					

#test the actual repl
TESTCASE 'callShim myREPL < <(echo "var a=1;")=undefined'
	[ "$(callShim myREPL < <(echo "var a=1;"))" == "undefined" ]
	RESULT	

TESTCASE 'callShim myREPL < <(echo "a++;")=1'
	[ "$(callShim myREPL < <(echo "a++;"))" == "1" ]
	RESULT	

TESTCASE 'callShim myREPL < <(echo "a++;")=2'
	[ "$(callShim myREPL < <(echo "a++;"))" == "2" ]
	RESULT	

TESTCASE 'callShim myREPL < <(echo "a")=3'
	[ "$(callShim myREPL < <(echo "a"))" == "3" ]
	RESULT	

stopShim myREPL 

#test that the temp files used by the shim are gone
TESTCASE 'ls callShimmyREPL.sh='
	[ "$(ls callShimmyREPL.sh)" == "" ]
	RESULT	

TESTCASE 'ls myREPL.log='
	[ "$(ls myREPL.log)" == "" ]
	RESULT	
	
TESTCASE 'ls myREPLOUT='
	[ "$(ls myREPLOUT)" == "" ]
	RESULT	
	
TESTCASE 'ls myREPLIN='
	[ "$(ls myREPLIN)" == "" ]
	RESULT	

TESTCASE 'ls disposemyREPL.sh='
	[ "$(ls disposemyREPL.sh)" == "" ]
	RESULT		
	

#simple test
#callShim myREPL < <(echo "var a=1;")
#callShim myREPL < <(echo "a++;")
#callShim myREPL < <(echo "a")



#exit

#more perfy test
#startMediator myREPL "$SANDBOX" repl
#sendInput myREPL silent < <(echo "var a=1;")
#for ((I=0 ; I< 10 ; I++)); do
#	sendInput myREPL silent < <(echo "a++;")
#done
#sendInput myREPL < <(echo "a")
#stopMediator myREPL

