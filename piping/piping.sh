#!/bin/bash
#summary:  fluent piping functions
#tags: pipes

#warning when chaining pipes together.  they are each kicked off in parallel but wait for input from the piping process.  

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#returns standard in
#usage:  stdin=$(getStdIn)
getStdIn()
{
	local STDIN=""
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
#        ^^^ -f declare functions readonly to prevent overwriting and notify of duplicate lib calls
#debugFlagOn getStdIn

fn_exists() 
{
	RES=$(type -t "$1") 
	if [[ "$RES" == function ]] || [[ "$RES" == builtin ]]; then
		return 0
	else
		return 1
	fi
}
readonly -f fn_exists

#helper function to dynamically execute some stuff 
makeCall()
{
	local STDIN=$(getStdIn)
	debecho makeCall stdin "$STDIN"
	local COMMAND="$@"
	debecho makeCall command "$COMMAND"
	
	#split into separate calls if has pipes		
	if [[ "$COMMAND" == *"|"* ]]; then
		debecho makeCall "$COMMAND" contains pipes.  splitting into separate commands
		IFS="|" read -r -a LIST <<< "$COMMAND"
		
		local INPUT="$STDIN"
		local RV		
		for EACH in "${LIST[@]}"
		do
			debecho makeCall each "$EACH"
			#recurse
			#note we do not quote each.  since we have already split, chained calls into makeCall do not have quote protection
			INPUT=$(echo "$INPUT" | makeCall $EACH ) 
			RV=$?
			debecho makeCall rv "$RV"
			debecho makeCall result "$INPUT"
			
			if [[ "$RV" != 0 ]] ; then
				return 1
			fi
		done
		
		echo "$INPUT"	
		debecho makeCall compound result "$INPUT"	
		return 0
	else
		local RESULT
		local RV
		local CALL="$1"
		debecho makeCall call "$CALL"
		fn_exists "$CALL" || { debecho makeCall invalid function call "$@" ; return 1 ; }
	
		RESULT=$(echo "$STDIN" | "$@" )	
		RV=$?
		debecho makeCall rv "$RV"
		debecho makeCall result "$RESULT"
	
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

#sends stdin to the function passed in the args, and then echoes stdin.  
#usage: echo "$data" | doJob myFunc arg1 arg2 arg3 | doSomethingElseWithOriginalData  
doJob()
{
	local STDIN=$(getStdIn)
	#debecho doJob stdin "$STDIN"
	#debecho doJob cmd "$@"
	RESULT=$(echo "$STDIN" | makeCall "$@" )	
	#debecho doJob result "$RESULT"
	echo "$STDIN"
}
readonly -f doJob
#debugFlagOn doJob

#sends stdin to the function passed in the args, and then echoes stdin.  
#usage: echo "$data" | doBackgroundJob myFunc arg1 arg2 arg3 | doSomethingElseWithOriginalData  
doBackgroundJob()
{
	local STDIN=$(getStdIn)
	#debecho doBackgroundJob stdin "$STDIN"
	#debecho doBackgroundJob cmd "$@"
	RESULT=$(echo "$STDIN" | makeCall "$@" & )	
	#debecho doBackgroundJob result "$RESULT"
	echo "$STDIN"
}
readonly -f doBackgroundJob
#debugFlagOn doBackgroundJob


#implements a pipe as a function call
#useful for converting "functions that accept stdin" into functions with arguments
#usage: pipeTo stdIn functionCall args
pipeTo()
{
	local STDIN="$1"
	shift
	echo "$STDIN" | $@
}
readonly -f pipeTo
#debugFlagOn pipeTo

runAsLastArg()
{
	local STDIN=$(getStdIn)
	local COMMAND="$@"
	echo "$($COMMAND $STDIN)"
}
readonly -f runAsLastArg
#debugFlagOn runAsLastArg
