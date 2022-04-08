#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
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

TESTCASE 'echo line1 | appendLine line2 | appendLine line3 | ./stringsUtil.js lengthEncode = le_23_line1_NL_line2_NL_line3'
	[ "$(echo line1 | appendLine line2 | appendLine line3 | ./stringsUtil.js lengthEncode)" == "le_23_line1_NL_line2_NL_line3" ]
	RESULT

DATA=$(echo line1 | appendLine line2 | appendLine line3)

TESTCASE 'echo line1 | appendLine line2 | appendLine line3 | ./stringsUtil.js lengthEncode | ./stringsUtil.js lengthDecode = DATA'
	[ "$(echo line1 | appendLine line2 | appendLine line3 | ./stringsUtil.js lengthEncode | ./stringsUtil.js lengthDecode )" == "$DATA" ]
	RESULT

#now with bash wrapper
	
TESTCASE 'echo line1 | appendLine line2 | appendLine line3 | lengthEncode | lengthDecode = DATA'
	[ "$(echo line1 | appendLine line2 | appendLine line3 | lengthEncode | lengthDecode )" == "$DATA" ]
	RESULT

TESTCASE 'echo line1 | appendLine line2 | appendLine line3 | lengthEncode = le_23_line1_NL_line2_NL_line3'
	[ "$(echo line1 | appendLine line2 | appendLine line3 | lengthEncode)" == "le_23_line1_NL_line2_NL_line3" ]
	RESULT

#try the js stuff
echo word1.word2.word3.word4 | ./stringsUtil.js handle '()=>{let data=getStdInLines().join("");  let arr=data.split("."); let dump = lengthEncodeLines(arr); return dump;}'
echo word1.word2.word3.word4 | runJS '()=>{let data=getStdInLines().join("");  let arr=data.split("."); let dump = lengthEncodeLines(arr); return dump;}'


#perf	
function slowLoop()
{
	local -a list
	local I COUNT EACH
	COUNT=1000
	I=0
	while ((I < "$COUNT" ))
	do
		I=$((I + 1))
		list+=("key""$I""$DATA") 
	done
	
	for EACH in "${list[@]}"
	do
		./stringsUtil.js lengthEncode  < <(echo "$EACH") 		
	done > dump.txt
	
	cat dump.txt | getLineCount
	rm dump.txt
}
time slowLoop

function fastLoop()
{
	local COUNT JS
	COUNT=1000
	JS='()=>{var data=getStdInLines(); var dump=[]; for (var i=0; i<'"$COUNT"'; i++){var arr=data.slice(0);arr[0]="key" + i.toString() + arr[0]; dump.push(lengthEncodeLines(arr));} return dump;}'
	echo "$DATA" | runJS "$JS" > dump.txt
	
	cat dump.txt | getLineCount
	rm dump.txt	
}
time fastLoop




	
