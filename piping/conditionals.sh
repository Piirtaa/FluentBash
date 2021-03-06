#!/bin/bash
#summary:  fluent conditional functions.  will echo back stdin if the condition is met and return 0.
#tags: conditionals

#load loader first.  
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh

#description: echoes pipe to stdout if stdin contains $1
#usage:  echo abc | ifContains b | ...will echo abc
ifContains()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		if [[ "$STDIN" == *"$1"* ]]; then
			#debecho ifContains "$STDIN" contains "$1"	
			echo "$STDIN"
			return 0
		else
			#debecho ifContains "$STDIN" does not contain "$1"	
			return 1
		fi
	fi	
}
readonly -f ifContains
#debugFlagOn ifContains

#description: echoes pipe to stdout if stdin does not contain $1
#usage:  echo abc | ifNotContains d | ...will echo abc
ifNotContains()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		if [[ "$STDIN" == *"$1"* ]]; then
			#debecho ifNotContains "$STDIN" does not contain "$1"	
			return 1
		else
			#debecho ifNotContains "$STDIN" contains "$1"	
			echo "$STDIN"
			return 0
		fi
	fi	
}
readonly -f ifNotContains
#debugFlagOn ifNotContains

#description: echoes pipe to stdout if stdin contains each arg
#usage:  echo abc | ifContainsAll b a c | ...will echo abc
ifContainsAll()
{
	local STDIN EACH
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		for EACH in "$@"; do
 			if [[ "$STDIN" != *"$EACH"* ]]; then
				return 1
			fi
		done
		echo "$STDIN"
		return 0
	fi	
}
readonly -f ifContainsAll
#debugFlagOn ifContainsAll

#description: echoes pipe to stdout if stdin does not contain each arg
#usage:  echo abc | ifContainsNone d e | ...will echo abc
ifContainsNone()
{
	local STDIN EACH
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		for EACH in "$@"; do
 			if [[ "$STDIN" == *"$EACH"* ]]; then
				return 1
			fi
		done
		echo "$STDIN"
		return 0
	fi	
}
readonly -f ifContainsNone
#debugFlagOn ifContainsNone

#description: echoes pipe to stdout if stdin equals $1
#usage:  echo abc | ifEquals abc | ...will echo abc
ifEquals()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		if [[ "$STDIN" == "$1" ]]; then
			echo "$STDIN"
			return 0
		else
			return 1
		fi
	fi	
}
readonly -f ifEquals
#debugFlagOn ifEquals

#description: echoes pipe to stdout if stdin not equals $1
#usage:  echo abc | ifNotEquals dafd | ...will echo abc
ifNotEquals()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		if [[ "$STDIN" == "$1" ]]; then
			return 1
		else
			echo "$STDIN"
			return 0
		fi
	fi	
}
readonly -f ifNotEquals
#debugFlagOn ifNotEquals

#description: echoes pipe to stdout if stdin length equals $1
#usage:  echo abc | ifLengthOf 3 | ...will echo abc
ifLengthOf()
{
	local STDIN LEN
	STDIN=$(getStdIn)
	#LEN=$(echo "$STDIN" | getLength)
	LEN=$(getLength < <(echo "$STDIN"))
	#LEN=$(getLength <<< "$STDIN")
	
	if [[ "$LEN" == "$1" ]]; then
		echo "$STDIN"
		return 0
	fi
	return 1
}
readonly -f ifLengthOf
#debugFlagOn ifLengthOf

#description: echoes stdin if stdin starts with $1
#usage:  echo abc | ifStartsWith ab | ...will echo abc
ifStartsWith()
{
	local STDIN
	STDIN=$(getStdIn)
	#debecho ifStartsWith stdin "$STDIN"
	if [[ -z "$STDIN" ]]; then
		#debecho ifStartsWith stdin is empty
		return 1
	else
		if [[ "$STDIN" == "$1"* ]]; then
			#debecho ifStartsWith stdin contains "$1"
			echo "$STDIN"
			return 0
		else
			#debecho ifStartsWith stdin does not contain "$1"
			return 1
		fi
	fi	
}
readonly -f ifStartsWith
#debugFlagOn ifStartsWith

#description: echoes stdin if stdin does not start with $1
#usage:  echo abc | ifNotStartsWith cd | ...will echo abc
ifNotStartsWith()
{
	local STDIN
	STDIN=$(getStdIn)
	#debecho ifNotStartsWith stdin "$STDIN"
	if [[ -z "$STDIN" ]]; then
		#debecho ifNotStartsWith stdin is empty
		return 1
	else
		if [[ "$STDIN" == "$1"* ]]; then
			#debecho ifNotStartsWith stdin contains "$1"
			return 1
		else
			#debecho ifNotStartsWith stdin does not contain "$1"
			echo "$STDIN"
			return 0
		fi
	fi	
}
readonly -f ifNotStartsWith
#debugFlagOn ifNotStartsWith

#description: echoes stdin if stdin ends with $1
#usage:  echo abc | ifEndsWith abc | ...will echo abc
ifEndsWith()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		if [[ "$STDIN" == *"$1" ]]; then
			echo "$STDIN"
			return 0
		else
			return 1
		fi
	fi	
}
readonly -f ifEndsWith
#debugFlagOn ifEndsWith

#description: echoes stdin if stdin does not start with $1
#usage:  echo abc | ifNotStartsWith cd | ...will echo abc
ifNotEndsWith()
{
	local STDIN
	STDIN=$(getStdIn)
	#debecho ifNotEndsWith stdin "$STDIN"
	if [[ -z "$STDIN" ]]; then
		#debecho ifNotEndsWith stdin is empty
		return 1
	else
		if [[ "$STDIN" == *"$1" ]]; then
			#debecho ifNotEndsWith stdin contains "$1"
			return 1
		else
			#debecho ifNotEndsWith stdin does not contain "$1"
			echo "$STDIN"
			return 0
		fi
	fi	
}
readonly -f ifNotEndsWith
#debugFlagOn ifNotEndsWith

#description: echoes stdin if args are equal
#usage:  echo blah | command | ifArgsEqual a a | keep on going with output of command
ifArgsEqual()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ "$1" != "$2" ]]; then
		#debecho ifArgsEqual error.  not equal "$1" "$2" 
		return 1
	else
		echo "$STDIN"
		return 0
	fi
}
readonly -f ifArgsEqual
#debugFlagOn ifArgsEqual

#description:  echoes stdin if stdin has $1 lines
#usage:  echo $LINES | ifNumberOfLinesEquals 5 | getLine 5 
ifNumberOfLinesEquals()
{
	local STDIN COUNT
	STDIN=$(getStdIn)
	#debecho ifNumberOfLinesEquals stdin "$STDIN"
	#COUNT=$(echo "$STDIN" | getLineCount)
	COUNT=$(getLineCount < <(echo "$STDIN"))
	#COUNT=$(getLineCount <<< "$STDIN")
	#debecho ifNumberOfLinesEquals count "$COUNT"
	#debecho ifNumberOfLinesEquals arg1 "$1"
	
	if [[ "$1" != "$COUNT" ]]; then
		return 1
	else
		echo "$STDIN"
		return 0
	fi
}
readonly -f ifNumberOfLinesEquals
#debugFlagOn ifNumberOfLinesEquals

#description: echoes stdin if stdin has more than $1 lines
#usage:  echo $LINES | ifNumberOfLinesGreaterThan 5 | getLine 5 
ifNumberOfLinesGreaterThan()
{
	local STDIN COUNT
	STDIN=$(getStdIn)
	#COUNT=$(echo "$STDIN" | getLineCount)
	COUNT=$(getLineCount < <(echo "$STDIN"))
	#COUNT=$(getLineCount <<< "$STDIN")
	
	if (( "$COUNT" > "$1" )); then
		echo "$STDIN"
		return 0
	else
		return 1
	fi
}
readonly -f ifNumberOfLinesGreaterThan
#debugFlagOn ifNumberOfLinesGreaterThan

#description: echoes stdin if stdin has less than $1 lines
#usage:  echo $LINES | ifNumberOfLinesLessThan 5 | appendLine newLine 
ifNumberOfLinesLessThan()
{
	local STDIN COUNT
	STDIN=$(getStdIn)
	#COUNT=$(echo "$STDIN" | getLineCount)
	COUNT=$(getLineCount < <(echo "$STDIN"))
	#COUNT=$(getLineCount <<< "$STDIN")
	
	if (( "$COUNT" < "$1" )); then
		echo "$STDIN"
		return 0
	else
		return 1
	fi
}
readonly -f ifNumberOfLinesLessThan
#debugFlagOn ifNumberOfLinesLessThan

#description:  runs data thru a list of filter functions (provided by a variable) and echoes it back out if it passes all of them.
#usage:  echo $data | filter filterVarName
filter()
{
	local STDIN VARNAME FILTER RV LIST EACH
	STDIN=$(getStdIn)
	#debecho filter stdin "$STDIN"
	VARNAME="$1"
	FILTER=${!VARNAME}
	#debecho filter filter "$FILTER"

	IFS=$'\n' read -d '' -r -a LIST <<< "$FILTER"
	for EACH in "${LIST[@]}"
	do
		#debecho filter each "$EACH"
		echo "$STDIN" | makeCall "$EACH" 
		RV=$?
		if [[ "$RV" != 0 ]] ; then
			#debecho filter fails on "$EACH" 
			return 1
		fi
	done

	echo "$STDIN"
	#debecho filter succeeds output is "$STDIN"
	return 0			
}
readonly -f filter
#debugFlagOn filter

