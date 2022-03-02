#!/bin/bash
#summary:  uow functions
#tags: unit of work, uow, task, job, orchestration, bot, automation

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript keyValue/keyValueGram.sh

#	General Idea:  
#		we want a model to perform a task that is self-contained and portable.  
#		-that can be used much like a "service".  
#		-that carries its own state.  is persistent.
#		-that can react to conditions
#		-that the current state of a job can be serialized and moved to another environment for continued execution   
#		-that knows how to initialize itself	
#		-that knows how to clean itself up after it is done
#		-that can be easily cloned, forked, parallelized
#		-that tracks its own resource usage
#		-that has no dependencies other than bash and the system libraries it uses (ie. provisioning) 
#		-that has hooks that allow it to be orchestrated with other agents
#		-is human readable
#
#		we are essentially modelling a reactive, persistent, class instance that has service-y idioms.  in bash. cos why not.   
#
#	we use a keyvaluegram as the underlying store/layout
#		in this gram we store 3 types of things:  variables, functions, files
#			each type are keyed differently to as to be identifiable, and have different validations in their getter/setters
#			each type are gettable by name
#	
#	we use reserved keys to point to the functions and state we are using in our workflow
#		state - pending|initialized|running|stopped|disposed.  states only move in one direction, towards disposed.
#		initStrategy - the logic for initialization.  after, state goes pending->initialized.  
#		startStrategy - start logic.  initialized->running
#		stopStrategy - stop logic.  running-> stopped
#		disposeStrategy - dispose logic.  stopped->disposed
#		state transition conditions:	
#			all state transitions have conditional hooks attached to them.  these must be met before the transition logic can be run.
#			the naming convention for these hooks is can{stateTrans}Whatever. eg. canInit, canStart, canStop, canDispose
#	   	there can be more than one condition per transition.  they are processed in the datagram sequence. they are not polled, but 
#			executed when the state transition is attempted.
#		event triggers 
#			isStartTriggered - conditional logic. returns bool.  if true, start is attempted.  polled when state is:pending or initialized   
#  		isStopTriggered - conditional logic.  returns bool.  if true, stop is attempted.	 polled when state is:running
#		environment - contains all of the function definitions in existence during the composition of the gram.  this includes the workflow functions described below.
#		
#	we have functions  to process the unit of work which are fixed in implementation and boilerplate the workflow.		
#		start() { if canInit* -> initStrategy;  if canStart* -> startStrategy;  with state guards}
#		stop() { if canStop* -> stopStrategy;  if canDispose* -> disposeStrategy;  with state guards}
#		watchTriggers {  polling job that looks for trigger conditions.  }
#
#	since we are modelling out an object paradigm we pipe our object state in via stdin, to functions that work on the instance, and return it.  so we are also fluent.
	

declare -r workReservedKeys="state processes initStrategy startStrategy stopStrategy disposeStrategy" 
declare -r workStartStates="pending initialized"
declare -r workStopStates="initialized running"

#UoWGRAM construction methods ----------------------

#description returns an empty uow datagram
#usage:  UOW=$(workCreate)
workCreate()
{
	local -A HASH
	HASH[state]=pending
	HASH[environment]="$(declare -f)"
	local GRAM=$(getKeyValueGram HASH) ; 
	echo "$GRAM"
}	

#description:  adds a variable to the gram
#usage: varName=value; echo $GRAM | workSetVar varName
workSetVar()
{
	local VARNAME="$1"	
	if [[ -z "$VARNAME" ]]; then
		debecho workSetVar no var provided
		return 1	
	fi

	local GRAM=$(getStdIn)
	local KEY="_VAR_""$VARNAME"
	local VAL="${!VARNAME}"
	GRAM=$(kvgSet "$KEY" "$VAL")

	#pipe it back out
	echo "$GRAM"
	return 0
}
readonly -f workSetVar
#debugFlagon workSetVar

#description:  loads a variable in current scope from the gram. and echoes value of it
#usage: workGetVar varName <<< "$GRAM"
workGetVar()
{
	local VARNAME="$1"	
	if [[ -z "$VARNAME" ]]; then
		debecho workGetVar no var provided
		return 1	
	fi

	local GRAM=$(getStdIn)
	local KEY="_VAR_""$VARNAME"
	local VAL=$(echo "$GRAM" | kvgGet "$KEY") 
	eval "$VARNAME"="$VAL"
	echo "$VAL"
	return 0
}
readonly -f workGetVar
#debugFlagon workGetVar

#description:  adds a file to the gram
#usage: echo $GRAM | workSetFile fileName
workSetFile()
{
	local FILENAME="$1"	
	if [[ -z "$FILENAME" ]]; then
		debecho workSetFile no file provided
		return 1	
	fi
	if [[ ! -f "$FILENAME" ]]; then
		debecho workSetFile "$FILENAME" does not exist
		return 1  
	fi		

	local GRAM=$(getStdIn)
	local KEY="_FILE_""$FILENAME"
	local VAL=$(cat "$FILENAME")
	GRAM=$(kvgSet "$KEY" "$VAL")

	#pipe it back out
	echo "$GRAM"
	return 0
}
readonly -f workSetFile
#debugFlagon workSetFile

#description:  writes a file from the gram
#usage: workGetFile fileName <<< "$GRAM"
#usage: echo "$GRAM" | workGetFile fileName
workGetFile()
{
	local FILENAME="$1"	
	if [[ -z "$FILENAME" ]]; then
		debecho workGetVar no var provided
		return 1	
	fi

	local GRAM=$(getStdIn)
	local KEY="_FILE_""$VARNAME"
	local VAL=$(echo "$GRAM" | kvgGet "$KEY") 
	echo "$VAL" > "$FILENAME"	
	return 0
}
readonly -f workGetFile
#debugFlagon workGetFile

#description:  add a function to the gram
#usage:  echo $GRAM | workSetFunction fnName
workSetFunction()
{
	local FNNAME="$1"
	if [[ -z "$FNNAME" ]]; then
		debecho workSetFunction no functionName provided
		return 1
	fi

	#test if the fnName is a function
	if [[ $(type -t "$FNNAME") != function ]]; then
		debecho workSetFunction not a function "$FNNAME"
		return 1
	fi
	
	local GRAM=$(getStdIn)
	local KEY="_FN_""$FNNAME"
	local VAL=$(declare -f "$FNNAME")	
	GRAM=$(kvgSet "$KEY" "$VAL")

	#pipe it back out
	echo "$GRAM"
	return 0
}
readonly -f workSetFunction
#debugFlagOn workSetFunction

#description:  creates/sets a function in current scope from the gram
#usage: workGetFunction fnName <<< "$GRAM"
workGetFunction()
{
	local FNNAME="$1"	
	if [[ -z "$FNNAME" ]]; then
		debecho workGetFunction no var provided
		return 1	
	fi
	
	local GRAM=$(getStdIn)
	local KEY="_VAR_""$VARNAME"
	local VAL=$(echo "$GRAM" | kvgGet "$KEY") 
	eval "$VAL"
	return 0
}
readonly -f workGetFunction
#debugFlagon workGetFunction


#description:  add init function to the gram
#usage:  echo $GRAM | workSetInitStrategy fnName
workSetInitStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction init "$1"	
}
readonly -f workSetInitStrategy
#debugFlagOn workSetInitStrategy

workGetInitStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workGetFunction init "$1"	

}
#description:  add start function to the gram
#usage:  echo $GRAM | workSetStartStrategy fnName
workSetStartStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction start "$1"	
}
readonly -f workSetStartStrategy
#debugFlagOn workSetStartStrategy

#description:  add stop function to the gram
#usage:  echo $GRAM | workSetStopStrategy fnName
workSetStopStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction stop "$1"	
}
readonly -f workSetStopStrategy
#debugFlagOn workSetStopStrategy

#description:  add dispose function to the gram
#usage:  echo $GRAM | workSetDisposeStrategy fnName
workSetDisposeStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction dispose "$1"	
}
readonly -f workSetDisposeStrategy
#debugFlagOn workSetDisposeStrategy

#description:  add canInit function to the gram
#usage:  echo $GRAM | workAddCanInitStrategy fnName
workAddCanInitStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction canInit"$1" "$1"	
}
readonly -f workAddCanInitStrategy
#debugFlagOn workAddCanInitStrategy

#description:  add canStart function to the gram
#usage:  echo $GRAM | workAddCanStartStrategy fnName
workAddCanStartStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction canStart"$1" "$1"	
}
readonly -f workAddCanStartStrategy
#debugFlagOn workAddCanStartStrategy

#description:  add canStop function to the gram
#usage:  echo $GRAM | workAddCanStopStrategy fnName
workAddCanStopStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction canStop"$1" "$1"	
}
readonly -f workAddCanStopStrategy
#debugFlagOn workAddCanStopStrategy

#description:  add canDispose function to the gram
#usage:  echo $GRAM | workAddCanDisposeStrategy fnName
workAddCanDisposeStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction canDispose"$1" "$1"	
}
readonly -f workAddCanDisposeStrategy
#debugFlagOn workAddCanDisposeStrategy


#boilerplate public functions ---------------------------

#description:  public start method for a unit of work
#usage: echo $GRAM | workStart
workStart()
{
	local GRAM=$(getStdIn)
	#convert the gram into a hash
	local -A HASH
	readKeyValueGram HASH <<< "$GRAM"

	#get state
	STATE="${HASH[state]}"
	
	#state transition guard check
	local GUARDCHECK
	GUARDCHECK=$(echo "$workStartStates" | doEach ifEquals "$STATE")
	if [[ ! -z "$GUARDCHECK" ]]; then
		debecho workStart cannot start from state "$STATE"
		return 1  
	fi		

	#reload the environment
	ENVIRON="${HASH[environment]}"
	eval "$ENVIRON" &>/dev/null	#hide any declaration errors
	
	#canInit preconditions
	if [[ "$STATE" == initialized ]]; then
		debecho workStart canInit begins
		#get all "canInit" entries	
		for EACH in "${!HASH[canInit*]}"; do
			debecho workStart each "$EACH"
			local VAL="${HASH[$EACH]}"
			debecho workStart val "$VAL"
			
			if [[ ! -z "$VAL" ]]; then
				continue
			else
				#eval the logic
				GRAM=$(echo "$GRAM" | "$VAL")
				RV=$?
				if [[ "$RV" != 0 ]]; then
					#kack
					debecho workStart init precondition fail "$EACH"
					return 1
				fi
			fi		
		done
	fi
	
	#init strategy
	if [[ "$STATE" == pending ]]; then
		debecho workStart init begins
		local VAL="${HASH[initStrategy]}"
		debecho workStart val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			continue
		else
			#eval the logic
			GRAM=$(echo "$GRAM" | "$VAL")
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart init fail
				return 1
			fi
		fi

		#reupdate HASH based on the output GRAM
		readKeyValueGram HASH <<< "$GRAM"
		HASH[state]=initialized
		STATE=initialized		
		GRAM=$(getKeyValueGram HASH)
	fi

	#canStart preconditions
	if [[ "$STATE" == initialized ]]; then
		debecho workStart canStart begins
		#get all "canStart" entries	
		for EACH in "${!HASH[canStart*]}"; do
			debecho workStart each "$EACH"
			local VAL="${HASH[$EACH]}"
			debecho workStart val "$VAL"
			
			if [[ ! -z "$VAL" ]]; then
				continue
			else
				#eval the logic
				GRAM=$(echo "$GRAM" | "$VAL")
				RV=$?
				if [[ "$RV" != 0 ]]; then
					#kack
					debecho workStart start precondition fail "$EACH"
					return 1
				fi
			fi		
		done
	fi
	
	#start strategy
	if [[ "$STATE" == initialized ]]; then
		debecho workStart start begins
		local VAL="${HASH[startStrategy]}"
		debecho workStart val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			continue
		else
			#eval the logic
			GRAM=$(echo "$GRAM" | "$VAL")
			RV=$?
			
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart start fail
				return 1
			fi
		fi

		#reupdate HASH based on the output GRAM
		readKeyValueGram HASH <<< "$GRAM"
		HASH[state]=running
		STATE=running		
		GRAM=$(getKeyValueGram HASH)
	fi

	echo "$GRAM"
	return 0	
}
readonly -f workStart
#debugFlagOn workStart

#description:  public stop method for a unit of work
#usage: echo $GRAM | workStop
workStop()
{
	local GRAM=$(getStdIn)
	#convert the gram into a hash
	local -A HASH
	readKeyValueGram HASH <<< "$GRAM"

	#get state
	STATE="${HASH[state]}"
	
	#state transition guard check
	local GUARDCHECK
	GUARDCHECK=$(echo "$workStopStates" | doEach ifEquals "$STATE")
	if [[ ! -z "$GUARDCHECK" ]]; then
		debecho workStop cannot stop from state "$STATE"
		return 1  
	fi		

	#reload the environment
	ENVIRON="${HASH[environment]}"
	eval "$ENVIRON" &>/dev/null	#hide any declaration errors
	
	#canStop preconditions
	if [[ "$STATE" == running ]]; then
		debecho workStop canStop begins
		#get all "canInit" entries	
		for EACH in "${!HASH[canStop*]}"; do
			debecho workStop each "$EACH"
			local VAL="${HASH[$EACH]}"
			debecho workStop val "$VAL"
			
			if [[ ! -z "$VAL" ]]; then
				continue
			else
				#eval the logic
				GRAM=$(echo "$GRAM" | "$VAL")
				RV=$?
				if [[ "$RV" != 0 ]]; then
					#kack
					debecho workStop stopping precondition fail "$EACH"
					return 1
				fi
			fi		
		done
	fi
	
	#stop strategy
	if [[ "$STATE" == running ]]; then
		debecho workStop stop begins
		local VAL="${HASH[stopStrategy]}"
		debecho workStop val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			continue
		else
			#eval the logic
			GRAM=$(echo "$GRAM" | "$VAL")
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStop stop fail
				return 1
			fi
		fi
		#reupdate HASH based on the output GRAM
		readKeyValueGram HASH <<< "$GRAM"
		HASH[state]=stopped
		STATE=stopped		
		GRAM=$(getKeyValueGram HASH)
	fi

	#canDispose preconditions
	if [[ "$STATE" == stopped ]]; then
		debecho workStop canDispose begins
		#get all "canDispose" entries	
		for EACH in "${!HASH[canDispose*]}"; do
			debecho workStop each "$EACH"
			local VAL="${HASH[$EACH]}"
			debecho workStop val "$VAL"
			
			if [[ ! -z "$VAL" ]]; then
				continue
			else
				#eval the logic
				GRAM=$(echo "$GRAM" | "$VAL")
				RV=$?
				if [[ "$RV" != 0 ]]; then
					#kack
					debecho workStop dispose precondition fail "$EACH"
					return 1
				fi
			fi		
		done
	fi
	
	#dispose strategy
	if [[ "$STATE" == stopped ]]; then
		debecho workStop dispose begins
		local VAL="${HASH[disposeStrategy]}"
		debecho workStop val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			continue
		else
			#eval the logic
			GRAM=$(echo "$GRAM" | "$VAL")
			RV=$?
			
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStop dispose fail
				return 1
			fi
		fi

		#reupdate HASH based on the output GRAM
		readKeyValueGram HASH <<< "$GRAM"
		HASH[state]=disposed
		STATE=disposed		
		GRAM=$(getKeyValueGram HASH)
	fi

	echo "$GRAM"
	return 0	
}
readonly -f workStop
#debugFlagOn workStop

#tests
UOW=$(workCreate)

MYVAR1=a 
MYVAR2=b 

UOW=$(echo "$UOW" | workSetVar MYVAR1)
UOW=$(echo "$UOW" | workSetVar MYVAR2)


