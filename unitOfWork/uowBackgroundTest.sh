#!/bin/bash

#tests the background job behaviour for a unit of work

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/uow.sh

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


#construct a  unit of work
UOW=$(workCreate)

#register variables
FNHISTORY="functionsRun"
UOW=$(echo "$UOW" |  workSetVar FNHISTORY)

#register files
echo "initial history" > functionHistoryFile
UOW=$(echo "$UOW" |  workSetFile functionHistoryFile)

#define strategies
canInit1() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
canInit2() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
init() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
canRun1() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
canRun2() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
run() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
canStop1() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
canStop2() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
stop() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
canDispose1() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0 ; }
canDispose2() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  return 0  ; }
dispose() {	FNHISTORY=$(echo "$FNHISTORY" | append " ""${FUNCNAME[0]}" ) ; echo "${FUNCNAME[0]}" >> functionHistoryFile ;  cp functionHistoryFile historyFile ; return 0 ; }

#register strategies

UOW=$(echo "$UOW" | workAddCanInitStrategy canInit1 | workAddCanInitStrategy canInit2 | workSetInitStrategy init )
UOW=$(echo "$UOW" | workAddCanStartStrategy canRun1 | workAddCanStartStrategy canRun2 | workSetStartStrategy run )
UOW=$(echo "$UOW" | workAddCanStopStrategy canStop1 | workAddCanStopStrategy canStop2 | workSetStopStrategy stop )
UOW=$(echo "$UOW" | workAddCanDisposeStrategy canDispose1 | workAddCanDisposeStrategy canDispose2 | workSetDisposeStrategy dispose)

#we set the triggers so that the start is immediate and the end is 2 mins after this

STARTMIN=$(date +%M)
ENDMIN=$(( STARTMIN + 2 ))
if (( "$ENDMIN" >= 59 )); then
	ENDMIN=$(( ENDMIN - 59 ))
fi

UOW=$(echo "$UOW" |  workSetVar STARTMIN)
UOW=$(echo "$UOW" |  workSetVar ENDMIN)

startTrigger()
{
	return 0
}
stopTrigger()
{
	local CURRENTMIN=$(date +%M)
	if [[ "$CURRENTMIN" -ge 59 ]] ; then
		CURRENTMIN=$(( CURRENTMIN - 59 ))
	fi
	
	if [[ "$CURRENTMIN" -gt "$ENDMIN" ]] ; then
		return 0
	else
		return 1
	fi
}
poll()
{
	local CURRENTMIN=$(date +%M)
	if [[ "$CURRENTMIN" -ge 59 ]] ; then
		CURRENTMIN=$(( CURRENTMIN - 59 ))
	fi
	echo "CURRENTMIN is ${CURRENTMIN}" >> functionHistoryFile
}
UOW=$(echo "$UOW" | workSetStartTriggerStrategy startTrigger | workSetStopTriggerStrategy stopTrigger | workSetPollingStrategy poll)
echo "$UOW" > workfile
workWatch workfile 60 

