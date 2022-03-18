#!/bin/bash
#summary:  queries google 
#tags: automation google search

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript automation/firefox.sh
loadScript automation/scraping.sh

#description: searches google via ff automation
#usage:  searchGoogle query words
searchGoogle()
{
	local QUERY URL PID DUMPFILE WID GEO CONTENTS
	#DUMPFILE="$1"
	#shift
	QUERY=$(echo "$@" | tr [:space:] '+' )
	debecho searchGoogle query "$QUERY"	
	URL="https://www.google.com/search?client=firefox-b-e&q=$QUERY"
		
	firefox "$URL" >/dev/null
	PID="$!"
	
	sleep 5
	moveMouseToCentre
	sleep 0.5
	
	moveMouseRightHalfToEdge
	moveMouseRightHalfToEdge
	
	rightClickMouse
	sleep 0.5
	typeText v
	sleep 1
	#copy text
	ctrlKey a
	sleep 0.5
	ctrlKey c
	sleep 0.5
	
	#close both tabs	
	ctrlKey w 
	ctrlKey w	
	CONTENTS=$(pasteText)	
	
	debecho searchGoogle "$CONTENTS"
	echo "$CONTENTS" #> "$DUMPFILE"
			
	return 0
}
readonly -f searchGoogle
#debugFlagOn searchGoogle

#description:  returns a list of urls that aren't in the google domain
#usage:  cat dumpfile | parseSearchResultUrls
parseSearchResultUrls()
{
	local STDIN LIST1 LIST2
	STDIN=$(getStdIn)
	
	LIST1=$(echo "$STDIN" | extractAttributeValues data-lpage | uniq)
	LIST2=$(echo "$STDIN" | extractURLS | uniq)
	
	LIST1=$( echo "$LIST1"; echo "$LIST2" )
	LIST1=$(echo "$LIST1" | sort -u | doEachLine ifContainsNone "google" "gstatic.com" "w3.org" "schema.org" "ytimg" )
	
	echo "$LIST1" | filterOutIfNextLineContains

	return 0
}
readonly -f parseSearchResultUrls

