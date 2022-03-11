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
#  		workIsStopTriggered - conditional logic.  returns bool.  if true, stop is attempted.	 polled when state is:running
#		environment - contains all of the function definitions in existence during the composition of the gram.  this includes the workflow functions described below.
#		
#	we have functions  to process the unit of work which are fixed in implementation and boilerplate the workflow.		
#		start() { if canInit* -> initStrategy;  if canStart* -> startStrategy;  with state guards}
#		stop() { if canStop* -> stopStrategy;  if canDispose* -> disposeStrategy;  with state guards}
#		watchTriggers {  polling job that looks for trigger conditions.  }
#
#	since we are modelling out an object paradigm we pipe our object state in via stdin, to functions that work on the instance, and return it, fluently.
#  	
#		



#UoWGRAM construction methods ----------------------

#description returns an empty uow datagram
#usage:  UOW=$(workCreate)
workCreate()
{
	local -A HASH
	HASH[state]=pending
	#HASH[environment]="$(declare -f)"
	local GRAM=$(getKeyValueGram HASH) ; 
	echo "$GRAM"
	return 0
}	

#UoWGRAM variable primitives ----------------------
#description:  adds a variable to the gram
#usage: varName=value; echo $GRAM | workSetVar varName
workSetVar()
{
	local VARNAME="$1"	
	if [[ -z "$VARNAME" ]]; then
		debecho workSetVar no var provided
		return 1	
	fi

	local KEY="_VAR_""$VARNAME"
	local VAL RV
	VAL="${!VARNAME}"
	RV=$? #test for invalid indirection
	if [[ "$RV" != 0 ]]; then
		debecho workSetVar invalid indirection "$VARNAME"		
		return 1		
	fi	

	local GRAM=$(getStdIn)
	GRAM=$(echo "$GRAM" | kvgSet "$KEY" "$VAL")
	RV=$?
	if [[ "$RV" != 0 ]]; then
		debecho workSetVar error kvgSet "$KEY" "$VAL"		
		return 1		
	fi	

	#pipe it back out
	echo "$GRAM"
	return 0
}

readonly -f workSetVar
#debugFlagOn workSetVar

#description:  loads a variable in current scope from the gram. 
#usage: workEmergeVar varName <<< "$GRAM"
workEmergeVar()
{
	local VARNAME="$1"	
	if [[ -z "$VARNAME" ]]; then
		debecho workEmergeVar no var provided
		return 1	
	fi

	local GRAM=$(getStdIn)
	local KEY="_VAR_""$VARNAME"
	local VAL=$(echo "$GRAM" | kvgGet "$KEY") 
	debecho workEmergeVar evaling "$VARNAME" "$VAL"
	eval $VARNAME="'""$VAL""'"
	return 0
}
readonly -f workEmergeVar
#debugFlagOn workEmergeVar

#description:  loads all vars in current scope from the gram. 
#usage: workEmergeAllVars <<< "$GRAM"
workEmergeAllVars()
{
	local GRAM KEYS LIST EACH
	GRAM=$(getStdIn)
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_VAR_" | doEachLine getAfter "_VAR_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		workEmergeVar "$EACH" <<< "$GRAM"
	done
	return 0
}
readonly -f workEmergeAllVars
#debugFlagOn workEmergeAllVars

#description:  persists all vars in current scope back to the gram. 
#usage: GRAM=$(echo "$GRAM" | workPersistAllVars)
workPersistAllVars()
{
	local GRAM KEYS LIST EACH
	GRAM=$(getStdIn)
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_VAR_" | doEachLine getAfter "_VAR_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		debecho workPersistAllVars persisting var "$EACH" "${!EACH}"	
		GRAM=$(echo "$GRAM" | workSetVar "$EACH")
	done
	echo "$GRAM"
	return 0
}
readonly -f workPersistAllVars
#debugFlagOn workPersistAllVars

workDumpAllVars()
{
	local GRAM KEYS LIST EACH
	GRAM=$(getStdIn)
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_VAR_" | doEachLine getAfter "_VAR_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		debecho workDumpAllVars persisting var "$EACH" "${!EACH}"	
	done
	return 0
}
readonly -f workDumpAllVars
#debugFlagOn workDumpAllVars

#UoWGRAM file primitives ----------------------

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
	GRAM=$(echo "$GRAM" | kvgSet "$KEY" "$VAL")

	#pipe it back out
	echo "$GRAM"
	return 0
}
readonly -f workSetFile
#debugFlagOn workSetFile

#description:  writes a file from the gram
#usage: workEmergeFile fileName <<< "$GRAM"
#usage: echo "$GRAM" | workEmergeFile fileName
workEmergeFile()
{
	local FILENAME="$1"	
	if [[ -z "$FILENAME" ]]; then
		debecho workEmergeFile no file provided
		return 1	
	fi

	local GRAM=$(getStdIn)
	local KEY="_FILE_""$FILENAME"
	local VAL=$(echo "$GRAM" | kvgGet "$KEY") 
	echo "$VAL" > "$FILENAME"	
	return 0
}
readonly -f workEmergeFile
#debugFlagOn workEmergeFile

#description:  writes all files registered with the gram
#usage: workEmergeAllFiles <<< "$GRAM"
workEmergeAllFiles()
{
	local GRAM KEYS LIST EACH
	GRAM=$(getStdIn)
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_FILE_" | doEachLine getAfter "_FILE_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		workEmergeFile "$EACH" <<< "$GRAM"
	done
	return 0
}
readonly -f workEmergeAllFiles
#debugFlagOn workEmergeAllFiles

#description:  writes all files back to the gram
#usage: GRAM=$(echo "$GRAM" | workPersistAllFiles) 
workPersistAllFiles()
{
	local GRAM KEYS LIST EACH
	GRAM=$(getStdIn)
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_FILE_" | doEachLine getAfter "_FILE_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		GRAM=$(echo "$GRAM" | workSetFile "$EACH")
	done
	echo "$GRAM"
	return 0
}
readonly -f workPersistAllFiles
#debugFlagOn workPersistAllFiles

#description:  removes all files registered with the gram
#usage: workRemoveAllFiles <<< "$GRAM"
workRemoveAllFiles()
{
	local GRAM KEYS LIST EACH
	GRAM=$(getStdIn)
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_FILE_" | doEachLine getAfter "_FILE_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		rm "$EACH"
	done
	return 0
}
readonly -f workRemoveAllFiles
#debugFlagOn workRemoveAllFiles


#UoWGRAM function primitives ----------------------

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
	debecho workSetFunction gram "$GRAM"

	local KEY="_FN_""$FNNAME"
	debecho workSetFunction key "$KEY"

	local VAL=$(declare -f "$FNNAME")	
	debecho workSetFunction val "$VAL"

	GRAM=$(echo "$GRAM" | kvgSet "$KEY" "$VAL")

	#pipe it back out
	echo "$GRAM"
	return 0
}
readonly -f workSetFunction
#debugFlagOn workSetFunction

#description:  creates/sets a function in current scope from the gram
#usage: workEmergeFunction fnName <<< "$GRAM"
workEmergeFunction()
{
	local FNNAME="$1"	
	if [[ -z "$FNNAME" ]]; then
		debecho workEmergeFunction no var provided
		return 1	
	fi
	
	local GRAM=$(getStdIn)
	local KEY="_FN_""$FNNAME"
	local VAL=$(echo "$GRAM" | kvgGet "$KEY") 
	
	#if the function already exists 
	if [[ $(type -t "$FNNAME") == function ]]; then
		
		#are they the same definitions?  then skip
		local CURRENTFNDEF=$(declare -f "$FNNAME")	
		
		if [[ "$CURRENTFNDEF" == "$VAL" ]] ; then
			return 0
		fi
		
		#not the same so load it up
		eval "$VAL"		
	else
		eval "$VAL"
	fi
	
	return 0
}
readonly -f workEmergeFunction
#debugFlagOn workEmergeFunction

#description:  loads all functions in current scope from the gram. 
#usage: workEmergeAllFunctions <<< "$GRAM"
workEmergeAllFunctions()
{
	local GRAM KEYS LIST EACH
	GRAM=$(getStdIn)
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_FN_" | doEachLine getAfter "_FN_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		workEmergeFunction "$EACH" <<< "$GRAM"
	done
	return 0
}
readonly -f workEmergeAllFunctions
#debugFlagOn workEmergeAllFunctions

#UoWGRAM state change ---------------------------

#description:  changes the state of the gram to the next slot
#usage:	echo $GRAM | workChangeState expectedCurrent
workChangeState()
{
	local GRAM EXPECTED STATE
	GRAM=$(getStdIn)
	EXPECTED="$1"
	STATE=$(echo "$GRAM" | kvgGet state)
	
	if [[ "$STATE" != "$EXPECTED" ]] ; then
		debecho workChangeState unexpected transition.  expected: "$EXPECTED"  current: "$STATE"
		return 1	
	fi
	
	#one-way sequence
	#pending initialized running stopped disposed
	case "$STATE" in
		pending)
	    	debecho workChangeState changed to initialized
	  		GRAM=$(echo "$GRAM" | kvgSet state initialized )
	   	;;
		initialized)
	    	debecho workChangeState changed to running
	  		GRAM=$(echo "$GRAM" | kvgSet state running )
	   	;;
		running)
	    	debecho workChangeState changed to stopped
	  		GRAM=$(echo "$GRAM" | kvgSet state stopped )
	   	;;
		stopped)
	    	debecho workChangeState changed to disposed
	  		GRAM=$(echo "$GRAM" | kvgSet state disposed )
	   	;;
		*)
	    	debecho workChangeState no change
	    	return 1
	    	;;
	esac	
	echo "$GRAM"
	return 0
}
readonly -f workChangeState
#debugFlagOn workChangeState
#UoWGRAM strategy builders ----------------------

#description:  add init function to the gram
#usage:  echo $GRAM | workSetInitStrategy fnName arg1 arg2
workSetInitStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet init "$@"	
	
}
readonly -f workSetInitStrategy
#debugFlagOn workSetInitStrategy

#description:  add start function to the gram
#usage:  echo $GRAM | workSetStartStrategy fnName
workSetStartStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet start "$@"
}
readonly -f workSetStartStrategy
#debugFlagOn workSetStartStrategy

#description:  add stop function to the gram
#usage:  echo $GRAM | workSetStopStrategy fnName
workSetStopStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet stop "$@"
}
readonly -f workSetStopStrategy
#debugFlagOn workSetStopStrategy

#description:  add dispose function to the gram
#usage:  echo $GRAM | workSetDisposeStrategy fnName
workSetDisposeStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet dispose "$@"
}
readonly -f workSetDisposeStrategy
#debugFlagOn workSetDisposeStrategy

#description:  add canInit function to the gram
#usage:  echo $GRAM | workAddCanInitStrategy fnName
workAddCanInitStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet canInit"$1" "$@"
}
readonly -f workAddCanInitStrategy
#debugFlagOn workAddCanInitStrategy

#description:  add canStart function to the gram
#usage:  echo $GRAM | workAddCanStartStrategy fnName
workAddCanStartStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet canStart"$1" "$@"	
}
readonly -f workAddCanStartStrategy
#debugFlagOn workAddCanStartStrategy

#description:  add canStop function to the gram
#usage:  echo $GRAM | workAddCanStopStrategy fnName
workAddCanStopStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet canStop"$1" "$@"	
}
readonly -f workAddCanStopStrategy
#debugFlagOn workAddCanStopStrategy

#description:  add canDispose function to the gram
#usage:  echo $GRAM | workAddCanDisposeStrategy fnName
workAddCanDisposeStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet canDispose"$1" "$@"	
}
readonly -f workAddCanDisposeStrategy
#debugFlagOn workAddCanDisposeStrategy

#description:  add start trigger to the gram
#usage:  echo $GRAM | workSetStartTriggerStrategy fnName
workSetStartTriggerStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet startTrigger "$@"	
}
readonly -f workSetStartTriggerStrategy
#debugFlagOn workSetStartTriggerStrategy

#description:  add stop trigger to the gram
#usage:  echo $GRAM | workSetStopTriggerStrategy fnName
workSetStopTriggerStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet stopTrigger "$@"	
}
readonly -f workSetStopTriggerStrategy
#debugFlagOn workSetStopTriggerStrategy

#description:  add polling strategy to the gram
#usage:  echo $GRAM | workSetPollingStrategy fnName
workSetPollingStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet poll "$@"	
}
readonly -f workSetPollingStrategy
#debugFlagOn workSetPollingStrategy


#boilerplate public functions ---------------------------

#description:  public start method for a unit of work
#usage: echo $GRAM | workStart
workStart()
{
	local GRAM=$(getStdIn)
	#debecho workStart gram "$GRAM"
	
	#get state
	local STATE=$(echo "$GRAM" | kvgGet state)
	debecho workStart state "$STATE"
			
	#state transition guard check
	local GUARDCHECK=$(echo "pending initialized" | doEach " " ifEquals "$STATE")
	debecho workStart guardcheck "$GUARDCHECK"
	
	if [[ "$STATE" != "$GUARDCHECK" ]]; then
		debecho workStart cannot start from state "$STATE"
		return 1  
	fi		

	#emerge the environment
	#local ENVIRON=$(echo "$GRAM" | kvgGet environment)
	#eval "$ENVIRON" &>/dev/null	#hide any declaration errors
		
	#emerge all functions, vars and files
	#debecho workStart emerging vars
	workEmergeAllVars <<< "$GRAM"

	#debecho workStart emerging functions 
	workEmergeAllFunctions <<< "$GRAM"

	#debecho workStart emerging files
	workEmergeAllFiles <<< "$GRAM"	
		
	#get all keys
	local KEYS LIST EACH RV VAL
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	debecho workStart keys "$KEYS"
		
	#canInit preconditions
	if [[ "$STATE" == pending ]]; then

		debecho workStart canInit begins
		#get all "canInit" entries
		local INITKEYS=$(echo "$KEYS" | doEachLine ifStartsWith "canInit" | doEachLine getAfter "canInit" )
		debecho workStart canInitKeys "$INITKEYS"
		IFS=$'\n' read -d '' -r -a LIST <<< "$INITKEYS"
		for EACH in "${LIST[@]}"
		do
			VAL=$(echo "$GRAM" | kvgGet "$EACH") 
			#run the function
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart init precondition fail "$VAL"
				return 1
			fi
			debecho workStart init precondition success "$VAL"
			
			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"				
		done
		debecho workStart canInit ends
	fi
	
	#init strategy
	if [[ "$STATE" == pending ]]; then
		debecho workStart init begins
		VAL=$(echo "$GRAM" | kvgGet "init") 
		debecho workStart val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			#eval the logic
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart init fail
				return 1
			fi
			debecho workStart init success
			
			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"
		fi

		#change state
		GRAM=$(echo "$GRAM" | workChangeState pending)
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workStart state change error
			return 1
		else
			STATE=initialized		
			#debecho workStart new gram "$GRAM"
		fi
		debecho workStart init ends
	fi

	#canStart preconditions
	if [[ "$STATE" == initialized ]]; then
		debecho workStart canStart begins
		#get all "canStart" entries
		local STARTKEYS=$(echo "$KEYS" | doEachLine ifStartsWith "canStart" | doEachLine getAfter "canStart" )
		debecho workStart canStartKeys "$STARTKEYS"
		IFS=$'\n' read -d '' -r -a LIST <<< "$STARTKEYS"
		for EACH in "${LIST[@]}"
		do
			VAL=$(echo "$GRAM" | kvgGet "$EACH") 
			#run the function
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart start precondition fail "$VAL"
				return 1
			fi
			debecho workStart start precondition success "$VAL"

			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"
		done
		debecho workStart canStart ends
	fi
	
	#start strategy
	if [[ "$STATE" == initialized ]]; then
		debecho workStart start begins
		VAL=$(echo "$GRAM" | kvgGet "start") 
		debecho workStart val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			#eval the logic
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart start fail
				return 1
			fi
			debecho workStart start success
			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"
		fi

		#change state
		GRAM=$(echo "$GRAM" | workChangeState initialized)
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workStart state change error
			return 1
		else
			STATE=running		
			#debecho workStart new gram "$GRAM"
		fi
		debecho workStart start ends
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

	#get state
	local STATE=$(echo "$GRAM" | kvgGet state)
			
	#state transition guard check
	local GUARDCHECK=$(echo "initialized running stopped" | doEach " " ifEquals "$STATE")
	if [[ "$STATE" != "$GUARDCHECK" ]]; then
		debecho workStop cannot stop from state "$STATE"
		return 1  
	fi		

	#emerge the environment
	#local ENVIRON=$(echo "$GRAM" | kvgGet environment)
	#eval "$ENVIRON" &>/dev/null	#hide any declaration errors

	#emerge all functions, vars and files
	#debecho workStop emerging vars
	workEmergeAllVars <<< "$GRAM"

	local KEYS LIST EACH RV VAL	
	#get all keys
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)

	#if stopping from initialized, we transition to the disposing case
	#the assumption is any initialization actions are cleared up in disposal
	#and any running actions are cleared up in stopping
	if [[ "$STATE" == initialized ]]; then	
		#we bypass running and stopping
		debecho workStop transitioning from initialized to stopped begins
		#change state
		GRAM=$(echo "$GRAM" | workChangeState initialized | workChangeState running )
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workStop state change error
			return 1
		else
			STATE=stopped		
			#debecho workStop new gram "$GRAM"
		fi
		debecho workStop transitioning from initialized to stopped ends
	fi
		
	#canStop preconditions
	if [[ "$STATE" == running ]]; then
		debecho workStop canStop begins
		#get all "canStop" entries
		local CANSTOPKEYS=$(echo "$KEYS" | doEachLine ifStartsWith "canStop" | doEachLine getAfter "canStop" )
		debecho workStop canStopKeys "$CANSTOPKEYS"
		IFS=$'\n' read -d '' -r -a LIST <<< "$CANSTOPKEYS"
		for EACH in "${LIST[@]}"
		do
			VAL=$(echo "$GRAM" | kvgGet "$EACH") 
			#run the function
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStop stop precondition fail "$VAL"
				return 1
			fi
			debecho workStop stop precondition success "$VAL"
			
			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"
		done
		debecho workStop canStop ends
	fi
	
	#stop strategy
	if [[ "$STATE" == running ]]; then
		debecho workStop stop begins
		VAL=$(echo "$GRAM" | kvgGet "stop") 
		debecho workStop val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			#eval the logic
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStop stop fail
				return 1
			fi
			debecho workStop stop success
			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"
		fi

		#change state
		GRAM=$(echo "$GRAM" | workChangeState running)
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workStop state change error
			return 1
		else
			STATE=stopped		
			#debecho workStop new gram "$GRAM"
		fi
		debecho workStop stop ends
	fi

	#dispose strategy
	if [[ "$STATE" == stopped ]]; then
		#canDispose preconditions
		debecho workStop canDispose begins
		#get all "canDispose" entries
		local CANDISPOSEKEYS=$(echo "$KEYS" |  doEachLine ifStartsWith "canDispose" | doEachLine getAfter "canDispose" )
		debecho workStop canDisposeKeys "$CANDISPOSEKEYS"
		IFS=$'\n' read -d '' -r -a LIST <<< "$CANDISPOSEKEYS"
		for EACH in "${LIST[@]}"
		do
			VAL=$(echo "$GRAM" | kvgGet "$EACH") 
			#run the function
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStop dispose precondition fail "$VAL"
				return 1
			fi
			debecho workStop dispose precondition success "$VAL"
			
			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"
		done
		debecho workStop canDispose ends
	fi

	if [[ "$STATE" == stopped ]]; then
		debecho workStop dispose begins
		VAL=$(echo "$GRAM" | kvgGet "dispose") 
		debecho workStop val "$VAL"
			
		if [[ ! -z "$VAL" ]]; then
			#eval the logic
			eval "$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStop dispose fail
				return 1
			fi
			debecho workStop dispose success
			
			#persist any variable and file changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
			GRAM=$(echo "$GRAM" | workPersistAllFiles)
			workEmergeAllVars <<< "$GRAM"
		fi

		#clear up files		
		$(echo "$GRAM" | workRemoveAllFiles)
	
		#change state
		GRAM=$(echo "$GRAM" | workChangeState stopped)
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workStop state change error
			return 1
		else
			STATE=disposed		
			#debecho workStop new gram "$GRAM"
		fi
		debecho workStop dispose ends
	fi

	echo "$GRAM"
	return 0	
}
readonly -f workStop
#debugFlagOn workStop

#boilerplate trigger and polling functions ---------------------------

#description:  tests the start trigger condition 
#usage:  echo "$GRAM" | workIsStartTriggered
workIsStartTriggered()
{
	local GRAM VAL RV
	GRAM=$(getStdIn)

	VAL=$(echo "$GRAM" | kvgGet "startTrigger") 
	debecho workIsStartTriggered val "$VAL"
		
	if [[ ! -z "$VAL" ]]; then
		#eval the logic
		eval "$VAL"
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workIsStartTriggered start is not triggered
			return 1
		fi

		#start is triggered
		debecho workIsStartTriggered start is triggered
		return 0
	fi
	
	return 1
}
readonly -f workIsStartTriggered
#debugFlagOn workIsStartTriggered

#description:  tests the stop trigger condition and runs the stop if true
#usage:  echo "$GRAM" | workIsStopTriggered
workIsStopTriggered()
{
	local GRAM VAL RV
	GRAM=$(getStdIn)

	VAL=$(echo "$GRAM" | kvgGet "stopTrigger") 
	debecho workIsStopTriggered val "$VAL"
		
	if [[ ! -z "$VAL" ]]; then
		#eval the logic
		eval "$VAL"
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workIsStopTriggered stop is not triggered
			return 1
		fi

		#stop is triggered
		debecho workIsStopTriggered stop is triggered
		return 0
	fi

	return 1
}
readonly -f workIsStopTriggered
#debugFlagOn workIsStopTriggered

#description:  runs the polling strategy
#usage:  echo "$GRAM" | workPoll
workPoll()
{
	local GRAM VAL RV
	GRAM=$(getStdIn)

	VAL=$(echo "$GRAM" | kvgGet "poll") 
	debecho workPoll val "$VAL"
		
	if [[ ! -z "$VAL" ]]; then
		#eval the logic
		debecho workPoll doing poll strategy
		eval "$VAL"
	fi

	return 0
}
readonly -f workPoll
#debugFlagOn workPoll

#description:  does a polling watch for conditions on a job.  the gram must be stored in a file
#usage:  workWatch gramFileName intervalSeconds (optional.  default 60)
workWatch()
{
	local FILENAME="$1"	
	if [[ -z "$FILENAME" ]]; then
		debecho workWatch no file provided
		return 1	
	fi
	
	if [[ ! -f "$FILENAME" ]]; then
		debecho workWatch "$FILENAME" does not exist
		return 1  
	fi		
	
	local INTERVAL=${2:-60}

	#loop
	local BREAKCONDITION=false	
	while [[ "$BREAKCONDITION" == false ]] ;
	do
		#load up the gram		
		debecho workWatch loading uow file "$FILENAME"

		local GRAM=$(cat "$FILENAME")
		if [[ -z "$GRAM" ]] ; then
			break		
		fi
		
		local STATE=$(echo "$GRAM" | kvgGet state)
		debecho workWatch state "$STATE"
		#echo "$GRAM" | workDumpAllVars
		
		#state transition guard check
		local STARTGUARDCHECK
		STARTGUARDCHECK=$(echo "pending initialized" | doEach " " ifEquals "$STATE")
		if [[ "$STATE" == "$STARTGUARDCHECK" ]]; then
			debecho workWatch evaluating start trigger
			local RV			
			$(echo "$GRAM" | workIsStartTriggered) 
			RV=$?
			if [[ "$RV" == 0 ]] ; then
				debecho workWatch starting
				#IMPORTANT NOTE:  the following operation will WAIT for the workStart operation to complete.
				#The $(...) command substitution mechanism waits for EOF on the pipe that the subshell's stdout is connected to.
				# So even if you background a command in the subshell, the main shell will still wait for it to finish and close its stdout.
				# To avoid waiting for this, you need to redirect its output away from the pipe.
				# Thus any strategies in the UoW that are backgrounded MUST redirect output or the following call will wait indefinitely.
				GRAM=$(echo "$GRAM" | workStart )
				RV=$?
				if [[ "$RV" == 0 ]] ; then
					workEmergeAllVars <<< "$GRAM"  #note: anytime we are in a subshell that will mutate the gram we need to reemerge the vars
					debecho workWatch persisting uow file "$FILENAME"
					echo "$GRAM" > "$FILENAME" 
				fi
			fi
		else
			local STOPGUARDCHECK
			STOPGUARDCHECK=$(echo "initialized running stopped" | doEach " " ifEquals "$STATE")
			if [[ "$STATE" == "$STOPGUARDCHECK" ]]; then
				debecho workWatch evaluating stop trigger
				local RV			
				$(echo "$GRAM" | workIsStopTriggered) 
				RV=$?
				if [[ "$RV" == 0 ]] ; then
					debecho workWatch stopping
					#IMPORTANT NOTE:  the following operation will WAIT for the workStart operation to complete.
					#The $(...) command substitution mechanism waits for EOF on the pipe that the subshell's stdout is connected to.
					# So even if you background a command in the subshell, the main shell will still wait for it to finish and close its stdout.
					# To avoid waiting for this, you need to redirect its output away from the pipe.
					# Thus any strategies in the UoW that are backgrounded MUST redirect output or the following call will wait indefinitely.
					GRAM=$(echo "$GRAM" | workStop)
					RV=$?
					if [[ "$RV" == 0 ]] ; then
						workEmergeAllVars <<< "$GRAM"  #note: anytime we are in a subshell that will mutate the gram we need to reemerge the vars
						debecho workWatch persisting uow file "$FILENAME"
						echo "$GRAM" > "$FILENAME"
					fi 
				fi
			fi	
		fi		
		
		#reload state.  if it is disposed we exit the loop
		STATE=$(echo "$GRAM" | kvgGet state)
		if [[ "$STATE" == disposed ]] ; then
			BREAKCONDITION=true
		else
			#do the polling job
			echo "$GRAM" | workPoll 
	   	sleep $INTERVAL;
		fi
	done

}
readonly -f workWatch
#debugFlagOn workWatch

