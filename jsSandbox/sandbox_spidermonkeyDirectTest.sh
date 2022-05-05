#!/bin/bash

#load loader first
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

loadScript piping/piping.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh
loadScript piping/strings.sh

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

SANDBOX=$(getScriptPath jsSandbox/sandbox_spidermonkey.js) 


TESTCASE 'echo "adsfadf" | "$SANDBOX" ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);} = false'
	[ "$(echo "adfadf" | "$SANDBOX" '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);}')" == "false" ]
	RESULT
	
#test the js itself
OUTPUT=$(echo '()=>{var c=6; c++; console.log(c);}' | "$SANDBOX" piped)

TESTCASE 'echo "$OUTPUT" | getLine 1  = 7'
	[ "$(echo "$OUTPUT" | getLine 1)" == "7" ]
	RESULT

TESTCASE 'echo "$OUTPUT" | getLine 2  = undefined'
	[ "$(echo "$OUTPUT" | getLine 2)" == "undefined" ]
	RESULT

OUTPUT=$(echo '()=>{var c=6; c++; console.log(c); return c;}' | "$SANDBOX" piped)

TESTCASE 'echo "$OUTPUT" | getLine 1  = 7'
	[ "$(echo "$OUTPUT" | getLine 1)" == "7" ]
	RESULT

TESTCASE 'echo "$OUTPUT" | getLine 2  = 7'
	[ "$(echo "$OUTPUT" | getLine 2)" == "7" ]
	RESULT	

OUTPUT=$(echo word1.word2.word3.word4 | "$SANDBOX" '()=>{let data=getStdInLines().join("");  let arr=data.split("."); return arr;}')
echo "$OUTPUT"

TESTCASE 'echo "$OUTPUT"   = word1,word2,word3,word4'
	[ "$(echo "$OUTPUT" | getLine 1)" == "word1,word2,word3,word4" ]
	RESULT

exit

#TODO:  complete perf testing

#perf test for string functions
COUNT=1000

#this function causes an "allocation size overflow" with spidermonkey
function perfStrings1()
{
	./jsSandbox_spidermonkey.sh start myInstance
	./jsSandbox_spidermonkey.sh run myInstance < <(echo "var a='asldkfjadlfkjadlfkjadsflkj';")
		
	local I 
	for ((I = 0 ; I < "$COUNT" ; I++)); do
		#we're appending lines to a string
		./jsSandbox_spidermonkey.sh run myInstance silent < <(echo "a = [a,a].join();") 
	done
	./jsSandbox_spidermonkey.sh run myInstance < <(echo "a")
	./jsSandbox_spidermonkey.sh stop myInstance
}

#time perfStrings1

function perfStrings2()
{
	startJSRepl myInstance
	runJSInRepl myInstance < <(echo "var a='a';")
	local I 
	for ((I = 0 ; I < "$COUNT" ; I++)); do
		#we're appending lines to a string
		runJSInRepl myInstance silent < <(echo "a = a + a;") 
	done
	#runJSInRepl myInstance < <(echo "a")
	stopJSRepl myInstance
}
#time perfStrings2
