#!/bin/bash

#tests triggers

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/trigger.sh

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

#define a series of steps
touch testFile


#step 1
beforeStep1()
{
	echo "before step1" >> testFile
}
step1Trigger()
{
	echo "step 1 triggered" >> testFile
	return 0
}
afterStep1()
{
	echo "after step1" >> testFile
	return 0
}
#debugFlagOn kvgSet
#debugFlagOn workIsStartTriggered
#debugFlagOn workIsStopTriggered
#debugFlagOn workWatch

createTrigger step1 step1Trigger | doBeforeTrigger beforeStep1  | doAfterTrigger afterStep1 > /dev/null


echo activating trigger
activateTrigger step1 5
echo cleanup
cat testFile
rm testFile
rm step1 


echo next test

createTrigger step1 step1Trigger | doBeforeTrigger beforeStep1 | doAfterTrigger afterStep1 > /dev/null


#step 2
beforeStep2()
{
	echo "before step2" >> testFile
}
step2Trigger()
{
	echo "step 2 triggered" >> testFile
	return 0
}
afterStep2()
{
	echo "after step2" >> testFile
	return 0
}
createTrigger step2 step2Trigger | doBeforeTrigger beforeStep2 | doAfterTrigger afterStep2 > /dev/null

#link step1 to step2
chainTriggers step1 step2 10

#fire it off
echo activating trigger
activateTrigger step1 5
echo cleanup
cat testFile
rm testFile
rm step1 
rm step2
