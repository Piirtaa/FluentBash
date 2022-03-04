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
#	since we are modelling out an object paradigm we pipe our object state in via stdin, to functions that work on the instance, and return it, fluently.
#  	
#		

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
	#HASH[environment]="$(declare -f)"
	local GRAM=$(getKeyValueGram HASH) ; 
	echo "$GRAM"
	return 0
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

	local KEY="_VAR_""$VARNAME"
	local VAL
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
debugFlagOn workEmergeVar

#description:  loads all vars in current scope from the gram. 
#usage: workEmergeAllVars <<< "$GRAM"
workEmergeAllVars()
{
	local GRAM=$(getStdIn)
	local KEYS=$(echo "$GRAM" | kvgGetAllKeys)
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
	local GRAM=$(getStdIn)
	local KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	KEYS=$(echo "$KEYS" | doEachLine ifStartsWith "_VAR_" | doEachLine getAfter "_VAR_" )
		
	IFS=$'\n' read -d '' -r -a LIST <<< "$KEYS"
	for EACH in "${LIST[@]}"
	do
		GRAM=$(echo "$GRAM" | workSetVar "$EACH")
	done
	echo "$GRAM"
	return 0
}
readonly -f workPersistAllVars
#debugFlagOn workPersistAllVars


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

#description:  loads all vars in current scope from the gram. 
#usage: workEmergeAllFiles <<< "$GRAM"
workEmergeAllFiles()
{
	local GRAM=$(getStdIn)
	local KEYS=$(echo "$GRAM" | kvgGetAllKeys)
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
	eval "$VAL"
	return 0
}
readonly -f workEmergeFunction
#debugFlagOn workEmergeFunction

#description:  loads all functions in current scope from the gram. 
#usage: workEmergeAllFunctions <<< "$GRAM"
workEmergeAllFunctions()
{
	local GRAM=$(getStdIn)
	local KEYS=$(echo "$GRAM" | kvgGetAllKeys)
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

#description:  add init function to the gram
#usage:  echo $GRAM | workSetInitStrategy fnName
workSetInitStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet init "$1"	
	
}
readonly -f workSetInitStrategy
#debugFlagOn workSetInitStrategy

#description:  add start function to the gram
#usage:  echo $GRAM | workSetStartStrategy fnName
workSetStartStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet start "$1"
}
readonly -f workSetStartStrategy
#debugFlagOn workSetStartStrategy

#description:  add stop function to the gram
#usage:  echo $GRAM | workSetStopStrategy fnName
workSetStopStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet stop "$1"
}
readonly -f workSetStopStrategy
#debugFlagOn workSetStopStrategy

#description:  add dispose function to the gram
#usage:  echo $GRAM | workSetDisposeStrategy fnName
workSetDisposeStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet dispose "$1"
}
readonly -f workSetDisposeStrategy
#debugFlagOn workSetDisposeStrategy

#description:  add canInit function to the gram
#usage:  echo $GRAM | workAddCanInitStrategy fnName
workAddCanInitStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1"	| kvgSet canInit"$1" "$1"
}
readonly -f workAddCanInitStrategy
#debugFlagOn workAddCanInitStrategy

#description:  add canStart function to the gram
#usage:  echo $GRAM | workAddCanStartStrategy fnName
workAddCanStartStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet canStart"$1" "$1"	
}
readonly -f workAddCanStartStrategy
#debugFlagOn workAddCanStartStrategy

#description:  add canStop function to the gram
#usage:  echo $GRAM | workAddCanStopStrategy fnName
workAddCanStopStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet canStop"$1" "$1"	
}
readonly -f workAddCanStopStrategy
#debugFlagOn workAddCanStopStrategy

#description:  add canDispose function to the gram
#usage:  echo $GRAM | workAddCanDisposeStrategy fnName
workAddCanDisposeStrategy()
{
	local GRAM=$(getStdIn)
	echo "$GRAM" | workSetFunction "$1" | kvgSet canDispose"$1" "$1"	
}
readonly -f workAddCanDisposeStrategy
#debugFlagOn workAddCanDisposeStrategy



#boilerplate public functions ---------------------------

#description:  public start method for a unit of work
#usage: echo $GRAM | workStart
workStart()
{
	local GRAM=$(getStdIn)
	debecho workStart gram "$GRAM"
	
	#get state
	STATE=$(echo "$GRAM" | kvgGet state)
	debecho workStart state "$STATE"
			
	#state transition guard check
	local GUARDCHECK
	GUARDCHECK=$(echo "$workStartStates" | doEach ifEquals "$STATE")
	if [[ ! -z "$GUARDCHECK" ]]; then
		debecho workStart cannot start from state "$STATE"
		return 1  
	fi		

	#emerge the environment
	ENVIRON=$(echo "$GRAM" | kvgGet environment)
	eval "$ENVIRON" &>/dev/null	#hide any declaration errors

	#emerge all functions and vars
	debecho workStart emerging functions 
	workEmergeAllFunctions <<< "$GRAM"
	debecho workStart emerging vars
	workEmergeAllVars <<< "$GRAM"
	
	#get all keys
	local KEYS=$(echo "$GRAM" | kvgGetAllKeys)
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
			#run the function
			eval "$EACH"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart init precondition fail "$EACH"
				return 1
			fi
			#persist any variable changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
		done
	fi
	
	#init strategy
	if [[ "$STATE" == pending ]]; then
		debecho workStart init begins
		local VAL=$(echo "$GRAM" | kvgGet "init") 
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
			#persist any variable changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
		fi

		#reupdate HASH based on the output GRAM
		GRAM=$(echo "$GRAM" | kvgSet state initialized)
		STATE=initialized		
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
			#run the function
			eval "$EACH"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStart start precondition fail "$EACH"
				return 1
			fi
			#persist any variable changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
		done
	fi
	
	#start strategy
	if [[ "$STATE" == initialized ]]; then
		debecho workStart start begins
		local VAL=$(echo "$GRAM" | kvgGet "start") 
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
			#persist any variable changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
		fi

		#reupdate HASH based on the output GRAM
		GRAM=$(echo "$GRAM" | kvgSet state running)
		STATE=running		
	fi

	echo "$GRAM"
	return 0	
}
readonly -f workStart
debugFlagOn workStart

#description:  public stop method for a unit of work
#usage: echo $GRAM | workStop
workStop()
{
	local GRAM=$(getStdIn)

	#get state
	STATE=$(echo "$GRAM" | kvgGet state)
			
	#state transition guard check
	local GUARDCHECK
	GUARDCHECK=$(echo "$workStopStates" | doEach ifEquals "$STATE")
	if [[ ! -z "$GUARDCHECK" ]]; then
		debecho workStop cannot stop from state "$STATE"
		return 1  
	fi		

	#emerge the environment
	ENVIRON=$(echo "$GRAM" | kvgGet environment)
	eval "$ENVIRON" &>/dev/null	#hide any declaration errors

	#emerge all functions and vars
	workEmergeAllFunctions <<< "$GRAM"
	workEmergeAllVars <<< "$GRAM"
	
	#get all keys
	local KEYS=$(echo "$GRAM" | kvgGetAllKeys)
		
	#canStop preconditions
	if [[ "$STATE" == running ]]; then
		debecho workStop canStop begins
		#get all "canStop" entries
		local CANSTOPKEYS=$(echo "$KEYS" | doEachLine ifStartsWith "canStop" | doEachLine getAfter "canStop" )
		debecho workStop canStopKeys "$CANSTOPKEYS"
		IFS=$'\n' read -d '' -r -a LIST <<< "$CANSTOPKEYS"
		for EACH in "${LIST[@]}"
		do
			#run the function
			eval "$EACH"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho workStop stop precondition fail "$EACH"
				return 1
			fi
			#persist any variable changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
		done
	fi
	
	#stop strategy
	if [[ "$STATE" == running ]]; then
		debecho workStop stop begins
		local VAL=$(echo "$GRAM" | kvgGet "stop") 
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
			#persist any variable changes made in a strategy to the GRAM
			GRAM=$(echo "$GRAM" | workPersistAllVars)
		fi

		#reupdate HASH based on the output GRAM
		GRAM=$(echo "$GRAM" | kvgSet state stopped)
		STATE=stopped		
	fi

	#canDispose preconditions
	debecho workStop canDispose begins
	#get all "canDispose" entries
	local CANDISPOSEKEYS=$(echo "$KEYS" |  doEachLine ifStartsWith "canDispose" | doEachLine getAfter "canDispose" )
	debecho workStop canDisposeKeys "$CANDISPOSEKEYS"
	IFS=$'\n' read -d '' -r -a LIST <<< "$CANDISPOSEKEYS"
	for EACH in "${LIST[@]}"
	do
		#run the function
		eval "$EACH"
		RV=$?
		if [[ "$RV" != 0 ]]; then
			#kack
			debecho workStop dispose precondition fail "$EACH"
			return 1
		fi
		#persist any variable changes made in a strategy to the GRAM
		GRAM=$(echo "$GRAM" | workPersistAllVars)
	done

	debecho workStop dispose begins
	local VAL=$(echo "$GRAM" | kvgGet "dispose") 
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
		#persist any variable changes made in a strategy to the GRAM
		GRAM=$(echo "$GRAM" | workPersistAllVars)
	fi

	#reupdate HASH based on the output GRAM
	GRAM=$(echo "$GRAM" | kvgSet state disposed)
	STATE=disposed		

	echo "$GRAM"
	return 0	

}
readonly -f workStop
#debugFlagOn workStop



