#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh


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



TESTCASE 'abc | ifContains b=abc'
	[ "$(echo "abc" | ifContains b)" == "abc" ]
	RESULT	

TESTCASE 'abc | ifContains d='
	[ "$(echo "abc" | ifContains d)" == "" ]
	RESULT	

TESTCASE 'abc | ifEquals abc=abc'
	[ "$(echo "abc" | ifEquals abc)" == "abc" ]
	RESULT	

TESTCASE 'abc | ifEquals bc='
	[ "$(echo "abc" | ifEquals bc)" == "" ]
	RESULT	

TESTCASE 'abc | ifArgsEqual 1 1=abc'
	[ "$(echo "abc" | ifArgsEqual 1 1)" == "abc" ]
	RESULT	

TESTCASE 'abc | ifArgsEqual 1 2=abc'
	[ "$(echo "abc" | ifArgsEqual 1 2)" == "" ]
	RESULT	

TESTCASE 'abc | ifLengthOf 3=abc'
	[ "$(echo "abc" | ifLengthOf 3)" == "abc" ]
	RESULT	

TESTCASE 'abc | ifLengthOf 2=abc'
	[ "$(echo "abc" | ifLengthOf 2)" == "" ]
	RESULT	

TESTCASE 'abc | ifStartsWith a=abc'
	[ "$(echo "abc" | ifStartsWith a)" == "abc" ]
	RESULT	

TESTCASE 'abc | ifStartsWith d='
	[ "$(echo "abc" | ifStartsWith d)" == "" ]
	RESULT	
	
TESTCASE 'abc | ifEndsWith c=abc'
	[ "$(echo "abc" | ifEndsWith c)" == "abc" ]
	RESULT	

TESTCASE 'abc | ifEndsWith a='
	[ "$(echo "abc" | ifEndsWith a)" == "" ]
	RESULT	

TESTCASE 'abc | ifArgsEqual a a=abc'
	[ "$(echo "abc" | ifArgsEqual a a)" == "abc" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItemsAsLines , | ifNumberOfLinesEquals 3 | getLine 1=a'
	[ "$(echo "a,b,c" | getArrayItemsAsLines , | ifNumberOfLinesEquals 3 | getLine 1 )" == "a" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItemsAsLines , | ifNumberOfLinesGreaterThan 2 | getLine 1=a'
	[ "$(echo "a,b,c" | getArrayItemsAsLines , | ifNumberOfLinesGreaterThan 2 | getLine 1 )" == "a" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItemsAsLines , | ifNumberOfLinesLessThan 4 | getLine 1=a'
	[ "$(echo "a,b,c" | getArrayItemsAsLines , | ifNumberOfLinesLessThan 4 | getLine 1 )" == "a" ]
	RESULT	


#test a filter expression
TESTCASE '$DATA | filter FILTER '
	DATA=$( echo line1 | appendLine line2 | appendLine line3 | appendLine line13 )
	FILTER=$( echo "getLine 1 | ifEndsWith 1" | appendLine "getLine 2 | ifStartsWith line" | appendLine "getLine 3 | ifContains 3" )  
	[ "$(echo $DATA | filter FILTER )" ]
	RESULT	
