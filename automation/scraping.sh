#!/bin/bash
#summary:  scraping functions
#tags: scraping

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript automation/x11automation.sh

#description:  given an attribute name, extracts the value.  eg. .... myAttr="xyz" ....
#usage:  echo $html | extractAttributeValues myAttr
extractAttributeValues()
{
	local ATTR STDIN GREP
	ATTR="$1"
	STDIN=$(getStdIn)
	
	#'data-lpage="\K[^"]+'
	GREP=$ATTR='"''\K[^''"']+
	#debecho extractAttributeValues grep "$GREP"
	#debecho extractAttributeValues wanted 'data-lpage="\K[^"]+'
	echo "$STDIN" | grep -oP "$GREP"
	
	return 0
}
#debugFlagOn extractAttributeValues

#description:  parses urls
#usage:  echo $html | extractURLS 
extractURLS()
{
	local LIST STDIN
	STDIN=$(getStdIn)
	LIST=$(echo "$STDIN" | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | sort -u)
	
	echo "$LIST"
	return 0
}
#debugFlagOn extractURLS

#reads stdin as lines and then iterates and echoes lines that aren't contained by other lines. input has to be presorted
#usage:  echo $manylines | filterOutIfNextLineContains
filterOutIfNextLineContains()
{
	local STDIN LIST LAST EACH FILTERED  
	STDIN=$(getStdIn) 
	IFS=$'\n' read -d '' -r -a LIST <<< "$STDIN"
	for EACH in "${LIST[@]}"
	do
		if [[ -z "$LAST" ]]; then
			LAST="$EACH"		
		else
			FILTERED=$(echo "$FILTERED" ; echo "$EACH" | ifContains "$LAST" > /dev/null && echo "$LAST" )
			LAST="$EACH"		
		fi	
	done

	for EACH in "${LIST[@]}"
	do
		echo "$FILTERED" | ifNotContains "$EACH" > /dev/null && echo "$EACH"
	done
	
	return 0
}
readonly -f filterOutIfNextLineContains
#debugFlagOn filterOutIfNextLineContains
