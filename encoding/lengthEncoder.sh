#!/bin/bash
#summary:  length encoding prepends strings with length information
#tags: strings, string encoding

#load loader first.  
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh
loadScript piping/strings.sh

#this script is identical in behaviour to the lengthEncoder class in jsSandbox/sandboxLib.js

#format:  le_lengthOfText_actualText

#usage:  echo $data | le_isIndicated
le_isIndicated()
{
	local STDIN
	STDIN=$(getStdIn)

	local LEN
	LEN=$(echo "$STDIN" | ifStartsWith "le_" | getAfter "le_" | getBefore "_")
	
	[ "$LEN" -ge 0 ] 2>/dev/null && return 0
	
	return 1
}

#usage:  echo $data | le_getExpectedLength
le_getExpectedLength()
{
	local STDIN
	STDIN=$(getStdIn)
	
	echo "$STDIN" | le_isIndicated > /dev/null || return 1
	
	echo "$STDIN" | getAfter "le_" | getBefore "_"
	return 0
}

#usage:  echo $data | le_getValue
le_getValue()
{
	local STDIN
	STDIN=$(getStdIn)
	
	echo "$STDIN" | le_isIndicated > /dev/null || return 1
	
	echo "$STDIN" | getAfter "le_" | getAfter "_"
	return 0
}


#usage:  echo $data | le_isValid
le_isValid()
{
	local STDIN
	STDIN=$(getStdIn)
	
	echo "$STDIN" | le_isIndicated > /dev/null || return 1
	
	local LEN VAL
	LEN=$(echo "$STDIN" | le_getExpectedLength)
	VAL=$(echo "$STDIN" | le_getValue)
	
	if [[ "$LEN" == "0" ]]; then
		if [[ -z "$VAL" ]]; then
			return 0
		fi		
		return 1
	else
		[ "$LEN" -eq "${#VAL}" ] 2> /dev/null && return 0 
		return 1
	fi
	
}


#usage:  echo $data | le_decode
le_decode()
{
	local STDIN
	STDIN=$(getStdIn)
	
	echo "$STDIN" | le_isValid > /dev/null || return 1

	echo "$STDIN" | le_getValue 
	return 0
}

#usage:  echo $data | le_encode
le_encode()
{
	local STDIN
	STDIN=$(getStdIn)
	
	echo "$STDIN" | le_isValid > /dev/null && { echo "$STDIN" ; return 0; }; 
	
	if [[ -z "$STDIN" ]]; then
		echo "le_0_"
	else
		local LEN
		LEN=$(getLength < <(echo "$STDIN"))
		echo "le_""$LEN""_""$STDIN"	
	fi	
	
	return 0
}
