#!/bin/bash
#summary:  fluent piping functions
#tags: pipes

#load loader first.  
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#description:  returns standard in
#usage:  STDIN=$(getStdIn)
getStdIn()
{
	local STDIN
	STDIN=""
	if [[ -p /dev/stdin ]]; then
		#debecho getStdIn stdin exists
		STDIN="$(cat -)"
	else
		#debecho getStdIn stdin does not exist
		return 1	
	fi
	echo "$STDIN"
	#debecho getStdIn STDIN="$STDIN"
	return 0
}
readonly -f getStdIn
#        ^^^ -f typeset functions readonly to prevent overwriting and notify of duplicate lib calls
#debugFlagOn getStdIn

#description:  returns whether the 1st argument is a function (either user-defined or builtin)
#usage: isFunction myfunc
isFunction() 
{
	local RES
	RES=$(type -t "$1") 
	if [[ "$RES" == function ]] || [[ "$RES" == builtin ]]; then
		return 0
	else
		return 1
	fi
}
readonly -f isFunction

#description:  returns whether the 1st arg is a user defined function
#usage: isUserDefinedFunction myfunc
isUserDefinedFunction() 
{
	local RES
	RES=$(type -t "$1") 
	if [[ "$RES" == function ]] ; then
		return 0
	else
		return 1
	fi
}
readonly -f isUserDefinedFunction


#description: helper function to dynamically execute some stuff 
#usage: echo $somedata | makeCall myCmd arg1 arg2
#usage: echo $somedata | "makeCall myCmd arg1 arg2 | nextCmd argA argB"
makeCall()
{
	local STDIN COMMAND LIST INPUT RV EACH RESULT CALL
	STDIN=$(getStdIn)
	#debecho makeCall stdin "$STDIN"
	COMMAND="$@"
	#debecho makeCall command "$COMMAND"
	
	#split into separate calls if has pipes		
	if [[ "$COMMAND" == *"|"* ]]; then
		#is a chained set of commands
	
		#debecho makeCall "$COMMAND" contains pipes.  splitting into separate commands
		IFS="|" read -r -a LIST <<< "$COMMAND"
		
		INPUT="$STDIN"
		for EACH in "${LIST[@]}"
		do
			#debecho makeCall each "$EACH"
			
			#recurse
			#note we do not quote each.  since we have already split, chained calls into makeCall do not have quote protection
			
			#INPUT=$(echo "$INPUT" | makeCall $EACH ) 
			#INPUT=$(makeCall $EACH <<< "$INPUT") 
			INPUT=$(makeCall $EACH < <(echo "$INPUT"))
			RV=$?
			#debecho makeCall rv "$RV"
			#debecho makeCall result "$INPUT"
			
			if [[ "$RV" != 0 ]] ; then
				return 1
			fi
		done
		
		echo "$INPUT"	
		#debecho makeCall compound result "$INPUT"	
		return 0
	else
		#is a standalone command
		CALL="$1"
		#debecho makeCall call "$CALL"
		isFunction "$CALL" || { debecho makeCall invalid function call "$@" ; return 1 ; }
	
		#RESULT=$(echo "$STDIN" | "$@" )	
		#RESULT=$("$@" <<< "$STDIN")	
		RESULT=$("$@" < <(echo "$STDIN"))  #note we are quoting all of the arguments
		RV=$?
		#debecho makeCall rv "$RV"
		#debecho makeCall result "$RESULT"
	
		if [[ "$RV" == 0 ]] ; then
			echo "$RESULT"
			return 0
		else
			return 1		
		fi
	fi
}
readonly -f makeCall
#debugFlagOn makeCall

#description:  sends stdin to the function passed in the args, and then echoes stdin back again, so we can have a fluent kind of flow
#usage: echo "$data" | doFlowThruCall myFunc arg1 arg2 arg3 | doSomethingElseWithOriginalData  
doFlowThruCall()
{
	local STDIN RESULT
	STDIN=$(getStdIn)
	#debecho doFlowThruCall stdin "$STDIN"
	#debecho doFlowThruCall cmd "$@"
	
	#RESULT=$(echo "$STDIN" | makeCall "$@" )	
	#RESULT=$(makeCall "$@" <<< "$STDIN")
	RESULT=$(makeCall "$@" < <(echo "$STDIN"))	
	#debecho doFlowThruCall result "$RESULT"
	echo "$STDIN"
}
readonly -f doFlowThruCall
#debugFlagOn doFlowThruCall

#description: sends stdin to the function passed in the args, and then echoes stdin.  just like doFlowThruCall but with the call being done in the background
#usage: echo "$data" | doBackgroundFlowThruCall myFunc arg1 arg2 arg3 | doSomethingElseWithOriginalData  
doBackgroundFlowThruCall()
{
	local STDIN RESULT
	STDIN=$(getStdIn)
	#debecho doBackgroundFlowThruCall stdin "$STDIN"
	#debecho doBackgroundFlowThruCall cmd "$@"
	RESULT=$(echo "$STDIN" | makeCall "$@" & )	
	#debecho doBackgroundFlowThruCall result "$RESULT"
	echo "$STDIN"
}
readonly -f doBackgroundFlowThruCall
#debugFlagOn doBackgroundFlowThruCall

#DIFFERENT CALL FORMATS############################################################################

#description.  converts a standard function call into a piped function call.  useful for converting "functions that accept stdin" into functions with arguments
#usage: pipeFirstArgToRemainder stdIn functionCall args
pipeFirstArgToRemainder()
{
	local STDIN
	STDIN="$1"
	shift
	echo "$STDIN" | $@
}
readonly -f pipeFirstArgToRemainder
#debugFlagOn pipeFirstArgToRemainder

#description: takes stdin and uses it as the last argument in the provided command
#usage:  echo $arg3 | stdInAsLastArg myCmd arg1 arg2
stdInAsLastArg()
{
	local STDIN COMMAND
	STDIN=$(getStdIn)
	COMMAND="$@"
	echo "$($COMMAND $STDIN)"
}
readonly -f stdInAsLastArg
#debugFlagOn stdInAsLastArg
