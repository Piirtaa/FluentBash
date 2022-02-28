#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript keyValue/keyValueGram.sh


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

#create a test gram
read -r -d '' GRAM <<'EOF'
_KEY_a_0
_KEY_b_2
line1
line2
_KEY_c_1
line b
_KEY_d_3
1
2
3
EOF

TESTCASE 'declare -A testHash; readKeyValueGram testHash <<< GRAM ; ${testHash[a]} == "" } '
	[ "$(declare -A testHash; readKeyValueGram testHash <<< "$GRAM" ; echo ${testHash[a]} )" == "" ]
	RESULT	

TESTCASE 'declare -A testHash; readKeyValueGram testHash <<< GRAM ; ${testHash[c]} == "line b" } '
	[ "$(declare -A testHash; readKeyValueGram testHash <<< "$GRAM" ; echo ${testHash[c]} )" == "line b" ]
	RESULT	

TESTCASE 'declare -A testHash; readKeyValueGram testHash <<< GRAM ; echo "${testHash[d]}" | getLine 2 == "2" } '
	[ "$(declare -A testHash; readKeyValueGram testHash <<< "$GRAM" ; echo "${testHash[d]}" | getLine 2 )" == "2" ]
	RESULT	

TESTCASE 'declare -A testHash; readKeyValueGram testHash <<< GRAM ; echo "${testHash[d]}" | getLine 3 == "3" } '
	[ "$(declare -A testHash; readKeyValueGram testHash <<< "$GRAM" ; echo "${testHash[d]}" | getLine 3 )" == "3" ]
	RESULT	

TESTCASE 'round trip'
	[ "$(declare -A testHash; testHash[bob]="i am bob" ; GRAM=$(getKeyValueGram testHash) ; readKeyValueGram testHash2 <<< "$GRAM" ; echo "${testHash2[bob]}" )" == "i am bob" ]
	RESULT	
	
#echo original gram "$GRAM"
#echo reading
#declare -A HASH ; readKeyValueGram HASH <<< "$GRAM"
#echo dumping
#getKeyValueGram HASH


