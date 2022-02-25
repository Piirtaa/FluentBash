#!/usr/bin/env bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript $BASH_DIR/../piping/piping.sh



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



TESTCASE 'abc | getStdIn = abc'
	[ "$(echo "abc" | getStdIn)" == "abc" ]
	RESULT

TESTCASE 'pipeTo a cat | getStdIn = a'
	[ "$(pipeTo a cat | getStdIn)" == "a" ]
	RESULT

job()
{
	STDIN=$(getStdIn)
	$(debecho job "$STDIN  $@")
}
#debugFlagOn job 


backgroundjob()
{
	STDIN=$(getStdIn)
	$(debecho backgroundjob "$STDIN  $@")
}
#debugFlagOn backgroundjob 

TESTCASE 'abc | doJob job 2 3 = abc'
	[ "$(echo "abc" | doJob job 2 3 )" == "abc" ]
	RESULT

TESTCASE 'abc | doBackgroundJob backgroundjob 2 3 = abc'
	[ "$(echo "abc" | doBackgroundJob backgroundjob 2 3 )" == "abc" ]
	RESULT