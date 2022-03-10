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
createTrigger step1 step1Trigger beforeStep1 afterStep1


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
createTrigger step2 step2Trigger beforeStep2 afterStep2

#link step1 to step2
chainTriggers step1 step2 20

#fire it off
activateTrigger step1 20

sleep 40

cat testFile
rm testFile
