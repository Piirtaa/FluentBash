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
_KEY_0_a
_KEY_2_b
line1
line2
_KEY_1_c
line b
_KEY_3_d
1
2
3
_KEY_2_e
1
2
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

TESTCASE 'kvgGet'
	[ "$(echo "$GRAM" | kvgGet d | getLine 3)" == "3" ]
	RESULT	

TESTCASE 'kvgGet'
	[ "$(echo "$GRAM" | kvgGet b | getLine 1)" == "line1" ]
	RESULT	
	
TESTCASE 'kvgGet'
	[ "$(echo "$GRAM" | kvgGet a )" == "" ]
	RESULT	

TESTCASE 'kvgGet'
	[ "$(echo "$GRAM" | kvgGet c )" == "line b" ]
	RESULT	
	
TESTCASE 'round trip2'
	[ "$(GRAM=$(kvgSet keyA valueA) ; echo "$GRAM" | kvgGet keyA )" == "valueA" ]
	RESULT	

TESTCASE 'round trip3'
	[ "$(GRAM=$(kvgSet keyA valueA) ; GRAM=$(echo "$GRAM" | kvgSet keyA valueB) ; echo "$GRAM" | kvgGet keyA )" == "valueB" ]
	RESULT	


#echo "$GRAM" | kvgGetAllKeys
	
#echo original gram "$GRAM"
#echo reading
#declare -A HASH ; readKeyValueGram HASH <<< "$GRAM"
#echo dumping
#getKeyValueGram HASH


