#!/bin/bash

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


#construct a test unit of work
UOW=$(workCreate)
UOWVAR="this is an initial var"
canInitTest()
{
	debugFlagOn canInitTest 
	debecho canInitTest canInitTest
	debecho canInitTest uowvar "$UOWVAR"
	UOWVAR="canInitTest"
	debugFlagOff canInitTest
	return 0
}
UOW=$(echo "$UOW" | workAddCanInitStrategy canInitTest | workSetVar UOWVAR)


canNotInitTest()
{
	debugFlagOn canNotInitTest
	debecho canNotInitTest canNotInitTest
	debecho canNotInitTest uowvar "$UOWVAR"
	UOWVAR="canNotInitTest"
	debugFlagOff canNotInitTest
	return 1
}
#UOW=$(echo "$UOW" | workAddCanInitStrategy canNotInitTest)
initTest()
{
	debugFlagOn initTest
	debecho initTest initTest
	debecho initTest uowvar "$UOWVAR"
	UOWVAR="initTest"
	debugFlagOff initTest
	return 0
}
UOW=$(echo "$UOW" | workSetInitStrategy initTest)

canRunTest()
{
	debugFlagOn canRunTest
	debecho canRunTest canRunTest
	debecho canRunTest uowvar "$UOWVAR"
	UOWVAR="canRunTest"
	debugFlagOff canRunTest
	return 0
}
UOW=$(echo "$UOW" | workAddCanStartStrategy canRunTest)
canNotRunTest()
{
	debugFlagOn canNotRunTest
	debecho canNotRunTest canNotRunTest
	debecho canNotRunTest uowvar "$UOWVAR"
	UOWVAR="canNotRunTest"
	debugFlagOff canNotRunTest
	return 1
}
#UOW=$(echo "$UOW" | workAddCanStartStrategy canNotRunTest)
runTest()
{
	debugFlagOn runTest
	debecho runTest runTest
	debecho runTest uowvar "$UOWVAR"
	UOWVAR="runTest"
	debugFlagOff runTest
	return 0
}
UOW=$(echo "$UOW" | workSetStartStrategy runTest)
canStopTest()
{
	debugFlagOn canStopTest
	debecho canStopTest canStopTest
	debecho canStopTest uowvar "$UOWVAR"
	UOWVAR="canStopTest"
	debugFlagOff canStopTest
	return 0
}
UOW=$(echo "$UOW" | workAddCanStopStrategy canStopTest)
canNotStopTest()
{
	debugFlagOn canNotStopTest
	debecho canNotStopTest canNotStopTest
	debecho canNotStopTest uowvar "$UOWVAR"
	UOWVAR="canNotStopTest"
	debugFlagOff canNotStopTest
	return 1
}
#UOW=$(echo "$UOW" | workAddCanStopStrategy canNotStopTest)
stopTest()
{
	debugFlagOn stopTest
	debecho stopTest stopTest
	debecho stopTest uowvar "$UOWVAR"
	UOWVAR="stopTest"
	debugFlagOff stopTest
	return 0
}
UOW=$(echo "$UOW" | workSetStopStrategy stopTest)
canDisposeTest()
{
	debugFlagOn canDisposeTest
	debecho canDisposeTest canDisposeTest
	debecho canDisposeTest uowvar "$UOWVAR"
	UOWVAR="canDisposeTest"
	debugFlagOff canDisposeTest
	return 0
}
UOW=$(echo "$UOW" | workAddCanDisposeStrategy canDisposeTest)
canNotDisposeTest()
{
	debugFlagOn canNotDisposeTest
	debecho canNotDisposeTest canNotDisposeTest
	debecho canNotDisposeTest uowvar "$UOWVAR"
	UOWVAR="canNotDisposeTest"
	debugFlagOff canNotDisposeTest
	return 1
}
UOW=$(echo "$UOW" | workAddCanDisposeStrategy canNotDisposeTest)
disposeTest()
{
	debugFlagOn disposeTest
	debecho disposeTest disposeTest
	debecho disposeTest uowvar "$UOWVAR"
	UOWVAR="disposeTest"
	debugFlagOff disposeTest
	return 0
}
UOW=$(echo "$UOW" | workSetDisposeStrategy disposeTest)
UOW=$(echo "$UOW" | workStart ) 
UOW=$(echo "$UOW" | workStop ) 
echo "$UOW"

exit



#TESTCASE 'abc | ifContains b=abc'
#	[ "$(echo "abc" | ifContains b)" == "abc" ]
#	RESULT	

