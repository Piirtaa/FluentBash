#!/bin/bash
#lib that provides some stdin functions

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

source $BASH_DIR/../piping/piping.sh #first thing we load is the script loader
source $BASH_DIR/../piping/strings.sh #first thing we load is the script loader
source $BASH_DIR/../piping/lists.sh #first thing we load is the script loader


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
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		if [[ "$STDIN" == "$1"* ]]; then
			echo "$STDIN"
			return 0
		else
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