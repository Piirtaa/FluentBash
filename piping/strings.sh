#!/bin/bash
#summary:  fluent string functions
#tags: strings, string manipulation

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh


#returns length of whatever was piped in
getLength()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		echo 0
	else
		echo ${#STDIN} 		
	fi	
	return 0
}
readonly -f getLength
#debugFlagOn getLength

#usage:  echo abc | getSubString startPos length
getSubstring()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		return 1
	else
		if [[ -z "$2" ]]; then
			echo ${STDIN:$1}
			return $?
		else
			echo ${STDIN:$1:$2}
			return $?
		fi
	fi	
}
readonly -f getSubstring
#debugFlagOn getSubstring

#usage: echo abcdef | getIndexOf cd
getIndexOf()
{
	local STDIN SEARCH LEN POS STRING RV

	STDIN=$(getStdIn)
	SEARCH="$1"
	LEN="${#STDIN}"
       
	# strip the first substring and everything beyond
	STRING="${STDIN%%"$SEARCH"*}"
	RV=$?
	
	if [[ "$RV" == 0 ]]; then
		# the position is calculated
		POS=${#STRING}
 		echo "$POS"
 		return 0	
	fi
	
	return 1
}

#usage: echo abcdef | getBefore cd
getBefore()
{	
	local STDIN SEARCH POS RV
	STDIN=$(getStdIn)
	SEARCH="$1"
	POS=$(echo "$STDIN" | getIndexOf "$SEARCH")
	RV=$?
	if [[ "$RV" == 0 ]]; then
		echo "${STDIN:0:$POS}"
		return 0	
	fi
	return 1
	
	#old way	
	#local MATCH="${STDIN%$SEARCH*}"
	#echo "$MATCH"
}
readonly -f getBefore
#debugFlagOn getBefore

#usage: echo abcdef | getAfter cd
getAfter()
{
	local STDIN SEARCH POS RV LEN
	STDIN=$(getStdIn)
	SEARCH="$1"
	POS=$(echo "$STDIN" | getIndexOf "$SEARCH")
	RV=$?
	if [[ "$RV" == 0 ]]; then
		LEN="${#SEARCH}"
		POS=$((POS + LEN))
		echo "${STDIN:$POS}"
		return 0	
	fi
	return 1
	
	#local STDIN=$(getStdIn)
	#local SEARCH="$1"
	#local MATCH=${STDIN#*$SEARCH}
	#echo "$MATCH"
}
readonly -f getAfter
#debugFlagOn getAfter

getLineCount()
{
	local STDIN LINECOUNT
	STDIN=$(getStdIn)
	LINECOUNT=$(echo "$STDIN" | wc -l)
	echo "$LINECOUNT"
}
readonly -f getLineCount
#debugFlagOn getLineCount
 
#usage echo $RESULT | getLine 1
getLine()
{
	local STDIN LINECOUNT LINE
	STDIN=$(getStdIn)
	debecho getLine stdin "$STDIN"
	debecho getLine line number "$1"
	
	LINECOUNT=$(echo "$STDIN" | getLineCount)
	if (( "$1" <= "$LINECOUNT" )); then
		LINE=$(echo "$STDIN" | head -n "$1" | tail -1)
		debecho getLine line "$LINE"
		echo "$LINE"
	fi
}
readonly -f getLine
#debugFlagOn getLine


#usage echo $RESULT | getLinesBelow 3
getLinesBelow()
{
	local STDIN POS
	STDIN=$(getStdIn)
	declare -i POS; POS="$1" ; ((POS+=1))
	debecho getLinesBelow pos "$POS"
	echo "$STDIN" | tail -n +"$POS" 
}
readonly -f getLinesBelow
#debugFlagOn getLinesBelow

#usage echo $RESULT | getLinesAbove 3
getLinesAbove()
{
	local STDIN POST
	STDIN=$(getStdIn)
	declare -i POS; POS="$1" ; ((POS-=1))
	debecho getLinesAbove pos "$POS"
	echo "$STDIN" | head -n +"$POS" 
}
readonly -f getLinesAbove
#debugFlagOn getLinesAbove

#usage:  echo something | prepend prefix
prepend()
{
	local STDIN
	STDIN=$(getStdIn)
	echo "$@$STDIN" 
}
readonly -f prepend
#debugFlagOn prepend

#usage:  echo something | append suffix
append()
{
	local STDIN
	STDIN=$(getStdIn)
	echo "$STDIN$@" 
}
readonly -f append
#debugFlagOn append

#usage:  echo something | prependLine topline
prependLine()
{
	local STDIN
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		echo "$@"
	else
		echo "$@"
		echo "$STDIN" 
	fi
}
readonly -f prependLine
#debugFlagOn prependLine

#usage:  echo something | appendLine bottomline
appendLine()
{
	local STDIN OUTPUT
	STDIN=$(getStdIn)
	debecho appendLine stdin "$STDIN"
	
	OUTPUT="$STDIN"
	debecho appendLine appending "$@"
	if [[ -z "$OUTPUT" ]]; then
		OUTPUT="$@"
	else
		OUTPUT=$(echo "$OUTPUT"; echo "$@")		
	fi
	
	debecho appendLine output "$OUTPUT"
	echo "$OUTPUT"
}
readonly -f appendLine
#debugFlagOn appendLine



#usage:  echo something | replaceLine 4 newline
replaceLine()
{
	local STDIN LINENUMBER ABOVE BELOW NEWLINE
	STDIN=$(getStdIn)
	debecho replaceLine stdin "$STDIN"
	LINENUMBER="$1"
	debecho replaceLine linenumber "$LINENUMBER"
	shift
	
	ABOVE=$(echo "$STDIN" | getLinesAbove "$LINENUMBER" )
	debecho replaceLine above "$ABOVE"
	BELOW=$(echo "$STDIN" | getLinesBelow "$LINENUMBER" )
	debecho replaceLine below "$BELOW"	
	NEWLINE=$(echo "$@")
	debecho replaceLine newline "$NEWLINE"
	
	if [[ ! -z "$ABOVE" ]]; then
		echo "$ABOVE"
	fi
	echo "$NEWLINE"
	if [[ ! -z "$BELOW" ]]; then
		echo "$BELOW"
	fi
}
readonly -f replaceLine
#debugFlagOn replaceLine

#usage:  echo something | insertLine 2 newline
insertLine()
{
	local STDIN LINENUMBER ABOVE BELOW OUTPUT
	STDIN=$(getStdIn)
	debecho insertLine stdin "$STDIN"
	LINENUMBER="$1"
	debecho insertLine linenumber "$LINENUMBER"
	shift
	
	ABOVE=$(echo "$STDIN" | getLinesAbove "$LINENUMBER" )
	debecho insertLine above "$ABOVE"
	BELOW=$(echo "$STDIN" | getLinesBelow $((LINENUMBER -1)) )
	debecho insertLine below "$BELOW"
	
	OUTPUT="$ABOVE"
	
	if [[ -z "$OUTPUT" ]]; then
		OUTPUT="$@"
	else
		OUTPUT=$(echo "$OUTPUT" | appendLine "$@")
	fi
	if [[ ! -z "$BELOW" ]]; then
		OUTPUT=$(echo "$OUTPUT" | appendLine "$BELOW")
	fi
	debecho insertLine output "$OUTPUT"
	echo "$OUTPUT"
	
}
readonly -f insertLine
#debugFlagOn insertLine

#usage: echo something | removeLine 2
removeLine()
{
	local STDIN LINENUMBER ABOVE BELOW 
	STDIN=$(getStdIn)
	LINENUMBER="$1"
	shift
	
	ABOVE=$(echo "$STDIN" | getLinesAbove $((LINENUMBER )) )
	debecho removeLine above "$ABOVE"
	BELOW=$(echo "$STDIN" | getLinesBelow $((LINENUMBER)) )
	debecho removeLine below "$BELOW"
	
	if [[ ! -z "$ABOVE" ]]; then
		echo "$ABOVE"
	fi
	if [[ ! -z "$BELOW" ]]; then
		echo "$BELOW"
	fi
}
readonly -f removeLine
#debugFlagOn removeLine

#usage:  echo something | prependOnLine 1 prefix
prependOnLine()
{
	local STDIN LINENUMBER NEWLINE
	STDIN=$(getStdIn)
	debecho prependOnLine stdin "$STDIN"
	LINENUMBER="$1"
	debecho prependOnLine linenumber "$LINENUMBER"
	shift
	
	NEWLINE="$@"$(echo "$STDIN" | getLine "$LINENUMBER" )
	debecho prependOnLine newline "$NEWLINE"
	echo "$STDIN" | replaceLine "$LINENUMBER" "$NEWLINE"	
}
readonly -f prependOnLine
#debugFlagOn prependOnLine

#usage:  echo something | appendOnLine 1 suffix
appendOnLine()
{
	local STDIN LINENUMBER NEWLINE
	STDIN=$(getStdIn)
	debecho appendOnLine stdin "$STDIN"
	LINENUMBER="$1"
	debecho appendOnLine linenumber "$LINENUMBER"
	shift
	
	NEWLINE=$(echo "$STDIN" | getLine "$LINENUMBER" )"$@"
	debecho appendOnLine newline "$NEWLINE"
	echo "$STDIN" | replaceLine "$LINENUMBER" "$NEWLINE"	
}
readonly -f appendOnLine
#debugFlagOn appendOnLine

#is a fluent cat
#usage: echo fileName | dump
dump()
{
	local STDIN
	STDIN=$(getStdIn)
	cat "$STDIN"
}
readonly -f dump
