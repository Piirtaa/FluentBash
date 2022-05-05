#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript encoding/lengthEncoder.sh


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

DATA=$(echo line1 | appendLine line2 | appendLine line3)
#echo "$DATA"

LEN=$(echo "$DATA" | getLength)
#echo "$LEN"

EDATA=$(echo "$DATA" | le_encode)
#echo "$EDATA"

#test the js stuff
TESTCASE 'echo "$EDATA" | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);} = true'
	[ "$(echo "$EDATA" | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);}')" == "true" ]
	RESULT

#echo "$EDATA" | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);}'

TESTCASE 'echo "adsfadf" | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);} = false'
	[ "$(echo "adfadf" | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);}')" == "false" ]
	RESULT

TESTCASE 'echo "$EDATA" | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isValid(data);} = true'
	[ "$(echo "$EDATA" | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isValid(data);}')" == "true" ]
	RESULT

TESTCASE 'echo "$EDATA" | getSubstring 0 10 | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);} = true'
	[ "$(echo "$EDATA" | getSubstring 0 10 | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);}')" == "true" ]
	RESULT

TESTCASE 'echo "$EDATA" | getSubstring 0 10 | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isValid(data);} = false'
	[ "$(echo "$EDATA" | getSubstring 0 10 | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isValid(data);}')" == "false" ]
	RESULT

TESTCASE 'echo "$EDATA" | getSubstring 0 23 | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);} = true'
	[ "$(echo "$EDATA" | getSubstring 0 23 | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isIndicated(data);}')" == "true" ]
	RESULT

TESTCASE 'echo "$EDATA" | getSubstring 0 23 | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isValid(data);} = true'
	[ "$(echo "$EDATA" | getSubstring 0 23 | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.isValid(data);}')" == "true" ]
	RESULT

TESTCASE 'echo "$EDATA"  | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.getValue(data);} = $DATA'
	[ "$(echo "$EDATA"  | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.getValue(data);}')" == "$DATA" ]
	RESULT

TESTCASE 'echo "$EDATA"  | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.decode(data);} = $DATA'
	[ "$(echo "$EDATA"  | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.decode(data);}')" == "$DATA" ]
	RESULT	
	
TESTCASE 'echo "$EDATA"  | ../jsSandbox/sandbox_spidermonkey.js ()=>{let data=getStdInLines().join("\n");  return lengthEncoder.getExpectedLength(data);} = $LEN'
	[ "$(echo "$EDATA"  | ../jsSandbox/sandbox_spidermonkey.js '()=>{let data=getStdInLines().join("\n");  return lengthEncoder.getExpectedLength(data);}')" == "$LEN" ]
	RESULT
	




#perf	
#function slowLoop()
#{
#	local -a list
#	local I COUNT EACH
#	COUNT=1000
#	I=0
#	while ((I < "$COUNT" ))
#	do
#		I=$((I + 1))
#		list+=("key""$I""$DATA") 
#	done
#	
#	for EACH in "${list[@]}"
#	do
#		./stringsUtil.js lengthEncode  < <(echo "$EACH") 		
#	done > dump.txt
#	
#	cat dump.txt | getLineCount
#	rm dump.txt
#}
#time slowLoop

#function fastLoop()
#{
#	local COUNT JS
#	COUNT=1000
#	JS='()=>{var data=getStdInLines(); var dump=[]; for (var i=0; i<'"$COUNT"'; i++){var arr=data.slice(0);arr[0]="key" + i.toString() + arr[0]; dump.push(lengthEncodeLines(arr));} return dump;}'
#	echo "$DATA" | runJS "$JS" > dump.txt
#	
#	cat dump.txt | getLineCount
#	rm dump.txt	
#}
#time fastLoop


	
