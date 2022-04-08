#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript sockets/socketServer.sh

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

#TESTCASE 'echo line1 | appendLine line2 | appendLine line3 | ./stringsUtil.js lengthEncode = le_23_line1_NL_line2_NL_line3'
#	[ "$(echo line1 | appendLine line2 | appendLine line3 | ./stringsUtil.js lengthEncode)" == "le_23_line1_NL_line2_NL_line3" ]
#	RESULT

echo starting server
startNCServer 8080 quit echo 

#echo starting client
#sendNCClient localhost 8080 hello world
