#!/usr/bin/env bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#set debecho flags
#debugFlagOn loadScript

#load dependencies.  
loadScript $BASH_DIR/../caching/keyValueStoreDispose.sh
loadScript $BASH_DIR/../caching/keyValueStoreCreate.sh
loadScript $BASH_DIR/../caching/keyValueStore.sh


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


TESTCASE 'call getKV for non-exist key should return empty'
	getKV name
	[ $? != 0 ]
	RESULT

TESTCASE 'setKV then getKV a variable'
	setKV name "Tom"
	[ "$(getKV name)" == "Tom" ]
	RESULT

TESTCASE 'setKV then setKV again with different value'
	setKV name "Tom"
	setKV name "Jerry"
	[ "$(getKV name)" == "Jerry" ]
	RESULT

TESTCASE 'setKV with different value'
	setKV bob joe
	[ "$(getKV bob)" == "joe" ]
	RESULT

