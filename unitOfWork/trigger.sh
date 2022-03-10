#!/bin/bash
#summary: trigger framework
#tags: trigger, reactive

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/uow.sh

#description:  a function that does nothing
#usage:  emptyFn
emptyFn()
{
	return 0
}
readonly -f emptyFn

#description: creates a trigger uow, writing a trigger file (a uow file) with the provided name (arg 1)
#usage:  createTrigger name triggerFn beforeFn afterFn
#usage:  			eg.	myName myTrigger emptyFn doSomethingAfter
createTrigger()
{
	local NAME SETUPFN TRIGGERFN POSTFN UOW
	NAME="${1:trigger}"
	TRIGGERFN="$2"
	BEFOREFN="$3"
	AFTERFN="$4"
	
	#construct a  unit of work
	UOW=$(workCreate)
	if [[ ! -z "$BEFOREFN" ]]; then
		UOW=$(echo "$UOW" | workSetInitStrategy "$BEFOREFN" )
	fi
	if [[ ! -z "$AFTERFN" ]]; then
		UOW=$(echo "$UOW" | workSetStopStrategy "$AFTERFN" )
	fi
	UOW=$(echo "$UOW" | workSetStartTriggerStrategy emptyFn | workSetStopTriggerStrategy "$TRIGGERFN" )
	
	echo "$UOW" > "$NAME"
	return 0	
}
readonly -f createTrigger

#description: activates a trigger
#usage:	activateTrigger myName pollingSecs
activateTrigger()
{
	local NAME INTERVALSECS
	NAME="$1"
	INTERVALSECS="${2:-60}"		

	#watch the trigger	
	workWatch "$NAME" "$INTERVALSECS"
}
readonly -f activateTrigger

#description: chains triggers together such that when the first completes the second is activated
#usage:	chainTriggers firstTriggerName secondTriggerName
chainTriggers()
{
	local TRIGGER1 TRIGGER2 UOW
	TRIGGER1="$1"
	TRIGGER2="$2"	
	
	if [[ ! -f "$TRIGGER1" ]]; then
		debecho chainTriggers "$TRIGGER1" does not exist
		return 1  
	fi		
	
	if [[ ! -f "$TRIGGER2" ]]; then
		debecho chainTriggers "$TRIGGER1" does not exist
		return 1  
	fi		

	UOW=$(cat "$TRIGGER1")
	UOW=$(echo "$UOW" | workSetDisposeStrategy activateTrigger "$TRIGGER2" 5 )
	echo "$UOW" > "$TRIGGER1"
}
readonly -f chainTriggers