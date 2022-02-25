#!/usr/bin/env bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript $BASH_DIR/../piping/piping.sh
loadScript $BASH_DIR/../piping/strings.sh



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




TESTCASE 'abc | getLength =3'
	[ "$(echo "abc" | getLength)" == "3" ]
	RESULT


TESTCASE 'abc | getSubstring 0=abc'
	[ "$(echo "abc" | getSubstring 0)" == "abc" ]
	RESULT


TESTCASE 'abc | getSubstring 1=bc'
	[ "$(echo "abc" | getSubstring 1)" == "bc" ]
	RESULT

TESTCASE 'abc | getSubstring 3='
	[ "$(echo "abc" | getSubstring 3)" == "" ]
	RESULT	

TESTCASE 'a | append b == ab'
	[ "$(echo "a" | append b)" == "ab" ]
	RESULT	

TESTCASE 'a | prepend b == ba'
	[ "$(echo "a" | prepend b)" == "ba" ]
	RESULT	

TESTCASE 'a | appendLine b | getLine 1 = a'
	[ "$(echo "a" | appendLine b | getLine 1 )" == "a" ]
	RESULT	
	
TESTCASE 'a | appendLine b | getLine 2 = b'
	[ "$(echo "a" | appendLine b | getLine 2 )" == "b" ]
	RESULT	

TESTCASE 'a | prependLine b | getLine 1 = b'
	[ "$(echo "a" | prependLine b | getLine 1 )" == "b" ]
	RESULT	
	
TESTCASE 'a | prependLine b | getLine 2 = a'
	[ "$(echo "a" | prependLine b | getLine 2 )" == "a" ]
	RESULT	
	
TESTCASE 'a | prependLine b | replaceLine 2 c | getLine 2 = c'
	[ "$(echo "a" | prependLine b | replaceLine 2 c | getLine 2 )" == "c" ]
	RESULT	
	
TESTCASE 'a | prependLine b | replaceLine 2 c | getLine 1 = b'
	[ "$(echo "a" | prependLine b | replaceLine 2 c | getLine 1 )" == "b" ]
	RESULT	

TESTCASE 'a | appendLine b | appendLine c | appendOnLine 2 d | getLine 2 = bd'
	[ "$(echo "a" | appendLine b | appendLine c | appendOnLine 2 d | getLine 2 )" == "bd" ]
	RESULT	

TESTCASE 'a | appendLine b | appendLine c | prependOnLine 2 d | getLine 2 = db'
	[ "$(echo "a" | appendLine b | appendLine c | prependOnLine 2 d | getLine 2 )" == "db" ]
	RESULT	

TESTCASE 'a | appendLine b | appendLine c | insertLine 2 d | getLine 1 = a'
	[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 1 )" == "a" ]
	RESULT	
TESTCASE 'a | appendLine b | appendLine c | insertLine 2 d | getLine 2 = d'
	[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 2 )" == "d" ]
	RESULT	
TESTCASE 'a | appendLine b | appendLine c | insertLine 2 d | getLine 3 = b'
	[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 3 )" == "b" ]
	RESULT	
TESTCASE 'a | appendLine b | appendLine c | insertLine 2 d | getLine 4 = c'
	[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 4 )" == "c" ]
	RESULT	

#need to test remove, replace
LIST=$(echo a | appendLine b | appendLine c | appendLine d | appendLine e | appendLine f);
TESTCASE 'LIST | insertLine 1 x | getLine 1 = x'
	[ "$(echo "$LIST" | insertLine 1 x | getLine 1 )" == "x" ]
	RESULT	

TESTCASE 'LIST | getLinesAbove 1 | getLine 1 = '
	[ "$(echo "$LIST" | getLinesAbove 1 | getLine 1 )" == "" ]
	RESULT	

TESTCASE 'LIST | getLinesAbove 0 | getLine 1 = '
	[ "$(echo "$LIST" | getLinesAbove 0 | getLine 1 )" == "" ]
	RESULT	

TESTCASE 'LIST | getLinesAbove 10 | getLine 1 = a'
	[ "$(echo "$LIST" | getLinesAbove 10 | getLine 1 )" == "a" ]
	RESULT	

TESTCASE 'LIST | getLinesBelow 1 | getLine 1 = '
	[ "$(echo "$LIST" | getLinesBelow 1 | getLine 1 )" == "b" ]
	RESULT	

TESTCASE 'LIST | getLinesBelow 0 | getLine 1 = '
	[ "$(echo "$LIST" | getLinesBelow 0 | getLine 1 )" == "a" ]
	RESULT	

TESTCASE 'LIST | replaceLine 1 x | getLine 1 = x'
	[ "$(echo "$LIST" | replaceLine 1 x | getLine 1 )" == "x" ]
	RESULT

TESTCASE 'LIST | removeLine 1  | getLine 1 = b'
	[ "$(echo "$LIST" | removeLine 1  | getLine 1 )" == "b" ]
	RESULT

TESTCASE 'LIST | replaceLine 3 x | getLine 3 = x'
	[ "$(echo "$LIST" | replaceLine 3 x | getLine 3 )" == "x" ]
	RESULT
			





