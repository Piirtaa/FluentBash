#!/bin/bash
#summary:  fluent conditional functions
#tags: conditionals

#lib that provides some stdin functions

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh

#echoes pipe to stdout if stdin contains $1
#usage:  echo abc | ifContains b | ...will echo abc
ifContains()
{
	local STDIN=$(getStdIn)
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

ifNotContains()
{
	local STDIN=$(getStdIn)
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

#echoes pipe to stdout if stdin contains each arg
#usage:  echo abc | ifContainsAll b a c | ...will echo abc
ifContainsAll()
{
	local STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		local EACH
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

ifContainsNone()
{
	local STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		local EACH
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

#echoes pipe to stdout if stdin equals $1
#usage:  echo abc | ifEquals abc | ...will echo abc
ifEquals()
{
	local STDIN=$(getStdIn)
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

#echoes pipe to stdout if stdin equals $1
#usage:  echo abc | ifLengthOf 3 | ...will echo abc
ifLengthOf()
{
	local STDIN=$(getStdIn)
	local LEN=$(echo "$STDIN" | getLength)
	
	if [[ "$LEN" == "$1" ]]; then
		echo "$STDIN"
		return 0
	fi
	return 1
}
readonly -f ifLengthOf
#debugFlagOn ifLengthOf

#usage:  echo abc | ifStartsWith ab | ...will echo abc
ifStartsWith()
{
	local STDIN=$(getStdIn)
	debecho ifStartsWith stdin "$STDIN"
	if [[ -z "$STDIN" ]]; then
		debecho ifStartsWith stdin is empty
		return 1
	else
		if [[ "$STDIN" == "$1"* ]]; then
			debecho ifStartsWith stdin contains "$1"
			echo "$STDIN"
			return 0
		else
			debecho ifStartsWith stdin does not contain "$1"
			return 1
		fi
	fi	
}
readonly -f ifStartsWith
#debugFlagOn ifStartsWith

#usage:  echo abc | ifEndsWith abc | ...will echo abc
ifEndsWith()
{
	local STDIN=$(getStdIn)
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

#usage:  echo blah | command | ifArgsEqual a a | keep on going with output of command
ifArgsEqual()
{
	#grab stdin
	local STDIN=$(getStdIn)
	if [[ "$1" != "$2" ]]; then
		debecho ifArgsEqual error.  not equal "$1" "$2" 
		return 1
	else
		echo "$STDIN"
		return 0
	fi
}
readonly -f ifArgsEqual
#debugFlagOn ifArgsEqual

#usage:  echo $LINES | ifNumberOfLinesEquals 5 | getLine 5 
ifNumberOfLinesEquals()
{
	#grab stdin
	local STDIN=$(getStdIn)
	debecho ifNumberOfLinesEquals stdin "$STDIN"
	local COUNT=$(echo "$STDIN" | getLineCount)
	debecho ifNumberOfLinesEquals count "$COUNT"
	debecho ifNumberOfLinesEquals arg1 "$1"
	
	if [[ "$1" != "$COUNT" ]]; then
		return 1
	else
		echo "$STDIN"
		return 0
	fi
}
readonly -f ifNumberOfLinesEquals
#debugFlagOn ifNumberOfLinesEquals

#usage:  echo $LINES | ifNumberOfLinesGreaterThan 5 | getLine 5 
ifNumberOfLinesGreaterThan()
{
	#grab stdin
	local STDIN=$(getStdIn)
	local COUNT=$(echo "$STDIN" | getLineCount)
	
	if (( "$COUNT" > "$1" )); then
		echo "$STDIN"
		return 0
	else
		return 1
	fi
}
readonly -f ifNumberOfLinesGreaterThan
#debugFlagOn ifNumberOfLinesGreaterThan

#usage:  echo $LINES | ifNumberOfLinesLessThan 5 | appendLine newLine 
ifNumberOfLinesLessThan()
{
	#grab stdin
	local STDIN=$(getStdIn)
	local COUNT=$(echo "$STDIN" | getLineCount)
	
	if (( "$COUNT" < "$1" )); then
		echo "$STDIN"
		return 0
	else
		return 1
	fi
}
readonly -f ifNumberOfLinesLessThan
#debugFlagOn ifNumberOfLinesLessThan

#description:  runs data thru a list of filters and echoes it back out if it passes all of them
#usage:  echo $data | filter filterVarName
filter()
{
	#grab stdin
	local STDIN=$(getStdIn)
	debecho filter stdin "$STDIN"
	local VARNAME="$1"
	local FILTER=${!VARNAME}
	debecho filter filter "$FILTER"

	local RV	
	IFS=$'\n' read -d '' -r -a LIST <<< "$FILTER"
	for EACH in "${LIST[@]}"
	do
		debecho filter each "$EACH"
		echo "$STDIN" | makeCall "$EACH" 
		RV=$?
		if [[ "$RV" != 0 ]] ; then
			debecho filter fails on "$EACH" 
			return 1
		fi
	done

	echo "$STDIN"
	debecho filter succeeds output is "$STDIN"
	return 0			
}
readonly -f filter
#debugFlagOn filter

