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


TESTCASE 'a b c | getArrayItem 0=a'
	[ "$(echo "a b c" | getArrayItem 0)" == "a" ]
	RESULT	

TESTCASE 'a b c | getArrayItem 1=b'
	[ "$(echo "a b c" | getArrayItem 1)" == "b" ]
	RESULT	

TESTCASE 'a b c | getArrayItem 4='
	[ "$(echo "a b c" | getArrayItem 4)" == "" ]
	RESULT	

TESTCASE 'a b c | getFirstArrayItem =a'
	[ "$(echo "a b c" | getFirstArrayItem )" == "a" ]
	RESULT	

TESTCASE 'a b c | getFirstArrayItemRemainder =b c'
	[ "$(echo "a b c" | getFirstArrayItemRemainder )" == "b c" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItem 0 ,=a'
	[ "$(echo "a,b,c" | getArrayItem 0 ,)" == "a" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItem 1 ,=b'
	[ "$(echo "a,b,c" | getArrayItem 1 ,)" == "b" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItem 4 ,='
	[ "$(echo "a,b,c" | getArrayItem 4 ,)" == "" ]
	RESULT	

TESTCASE 'a,b,c | getFirstArrayItem , =a'
	[ "$(echo "a,b,c" | getFirstArrayItem , )" == "a" ]
	RESULT	

TESTCASE 'a,b,c | getFirstArrayItemRemainder , =b,c'
	[ "$(echo "a,b,c" | getFirstArrayItemRemainder , )" == "b,c" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItemsAsLines , | getLine 1 =a'
	[ "$(echo "a,b,c" | getArrayItemsAsLines , | getLine 1 =a)" == "a" ]
	RESULT	

TESTCASE 'a,b,c | getArrayItemsAsLines , | getLine 2 =b'
	[ "$(echo "a,b,c" | getArrayItemsAsLines , | getLine 2 =b)" == "b" ]
	RESULT	
	
TESTCASE 'a,b,c | getArrayItemsAsLines , | getLine 3 =c'
	[ "$(echo "a,b,c" | getArrayItemsAsLines , | getLine 3 =c)" == "c" ]
	RESULT	

#operate on a list item by item and accumulate the result
TESTCASE 'A dog,A cat,B cat,C cat |  doEach , appendToFile derp | cat derp | getLine 1 ; rm derp ="A dog"'
	[ "$(echo "A dog,A cat,B cat,C cat" | doEach , appendToFile derp | touch derp; cat derp  | getLine 1 ; rm derp )" == "A dog" ]
	RESULT

#now let's try to filter the list in line
TESTCASE 'A dog,B cat,A cat,C cat |  doEach , ifContains A | appendToFile derp | cat derp | getLine 2 ; rm derp ="A cat"'
	[ "$(echo "A dog,A cat,B cat,C cat" | doEach , ifContains A | appendToFile derp | touch derp; cat derp  | getLine 2 ; rm derp )" == "A cat" ]
	RESULT

#echo "a,b,c,ad" | getArrayItemsAsLines , | doEachLine ifContains a | appendToFile derp | touch derp; cat derp | getLine 2 ; rm derp

TESTCASE 'a,b,c,ad | getArrayItemsAsLines , | doEachLine ifContains a | appendToFile derp | touch derp; cat derp | getLine 2 ; rm derp = ad'
	[ "$(echo "a,b,c,ad" | getArrayItemsAsLines , | doEachLine ifContains a | appendToFile derp | touch derp; cat derp | getLine 2 ; rm derp )" == "ad" ]
	RESULT	


	