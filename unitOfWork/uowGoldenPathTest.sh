#!/bin/bash

#tests the "golden path" (ie. everything works perfectly) for a unit of work

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

echo "$UOW" > pendingGram.txt

#test the construction of the gram
TESTCASE 'UOW | kvgGet state=pending'
	[ "$(echo "$UOW" | kvgGet state )" == "pending" ]
	RESULT	

TESTCASE 'UOW | kvgGet _VAR_FNHISTORY=functionsRun'
	[ "$(echo "$UOW" | kvgGet _VAR_FNHISTORY )" == "functionsRun" ]
	RESULT	

TESTCASE 'UOW | kvgGet _FILE_functionHistoryFile=initial history'
	[ "$(echo "$UOW" | kvgGet _FILE_functionHistoryFile )" == "initial history" ]
	RESULT	

TESTCASE 'UOW | kvgGet init=init'
	[ "$(echo "$UOW" | kvgGet init )" == "init" ]
	RESULT	

TESTCASE 'UOW | kvgGet canInitcanInit1=canInit1'
	[ "$(echo "$UOW" | kvgGet canInitcanInit1 )" == "canInit1" ]
	RESULT	

TESTCASE 'UOW | kvgGet canInitcanInit2=canInit2'
	[ "$(echo "$UOW" | kvgGet canInitcanInit2 )" == "canInit2" ]
	RESULT	

TESTCASE 'UOW | kvgGet start=run'
	[ "$(echo "$UOW" | kvgGet start )" == "run" ]
	RESULT	

TESTCASE 'UOW | kvgGet canStartcanRun1=canRun1'
	[ "$(echo "$UOW" | kvgGet canStartcanRun1 )" == "canRun1" ]
	RESULT	

TESTCASE 'UOW | kvgGet canStartcanRun2=canRun2'
	[ "$(echo "$UOW" | kvgGet canStartcanRun2 )" == "canRun2" ]
	RESULT	

TESTCASE 'UOW | kvgGet stop=stop'
	[ "$(echo "$UOW" | kvgGet stop )" == "stop" ]
	RESULT	

TESTCASE 'UOW | kvgGet canStopcanStop1=canStop1'
	[ "$(echo "$UOW" | kvgGet canStopcanStop1 )" == "canStop1" ]
	RESULT	

TESTCASE 'UOW | kvgGet canStopcanStop2=canStop2'
	[ "$(echo "$UOW" | kvgGet canStopcanStop2 )" == "canStop2" ]
	RESULT	

TESTCASE 'UOW | kvgGet dispose=dispose'
	[ "$(echo "$UOW" | kvgGet dispose )" == "dispose" ]
	RESULT	

TESTCASE 'UOW | kvgGet canDisposecanDispose1=canDispose1'
	[ "$(echo "$UOW" | kvgGet canDisposecanDispose1 )" == "canDispose1" ]
	RESULT	

TESTCASE 'UOW | kvgGet canDisposecanDispose2=canDispose2'
	[ "$(echo "$UOW" | kvgGet canDisposecanDispose2 )" == "canDispose2" ]
	RESULT

#test the start flow
UOW=$(echo "$UOW" | workStart ) 

TESTCASE 'UOW | kvgGet _VAR_FNHISTORY | ifContainsAll canInit2 canInit1 init canRun2 canRun1 run '
	[ "$(echo "$UOW" | kvgGet _VAR_FNHISTORY | ifContainsAll canInit2 canInit1 init canRun2 canRun1 run )"  ]
	RESULT	

TESTCASE 'UOW | kvgGet _FILE_functionHistoryFile | ifContainsAll canInit2 canInit1 init canRun2 canRun1 run '
	[ "$(echo "$UOW" | kvgGet _FILE_functionHistoryFile | ifContainsAll canInit2 canInit1 init canRun2 canRun1 run )"  ]
	RESULT	

TESTCASE 'UOW | kvgGet state=running'
	[ "$(echo "$UOW" | kvgGet state )" == "running" ]
	RESULT
	
echo "$UOW" > startedGram.txt

UOW=$(echo "$UOW" | workStop ) 

TESTCASE 'UOW | kvgGet _VAR_FNHISTORY | ifContainsAll canStop2 canStop1 stop canDispose2 canDispose1 dispose '
	[ "$(echo "$UOW" | kvgGet _VAR_FNHISTORY | ifContainsAll canStop2 canStop1 stop canDispose2 canDispose1 dispose )"  ]
	RESULT	

TESTCASE 'UOW | kvgGet _FILE_functionHistoryFile | ifContainsAll canStop2 canStop1 stop canDispose2 canDispose1 dispose '
	[ "$(echo "$UOW" | kvgGet _FILE_functionHistoryFile | ifContainsAll canStop2 canStop1 stop canDispose2 canDispose1 dispose )"  ]
	RESULT	

TESTCASE 'UOW | kvgGet state=disposed'
	[ "$(echo "$UOW" | kvgGet state )" == "disposed" ]
	RESULT
	
echo "$UOW" > disposedGram.txt

