#!/bin/bash
#summary:  fluent list functions
#tags: list

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/conditionals.sh


#retrieves an item from array by index.  where array is created by splitting stdin with supplied delimiter
#usage: echo a b c | getArrayItem 0 #to get first, space delimiter
#							getArrayItem -1 #to get last, space delimiter
#							getArrayItem 0 ":" #to get first, : delimiter
getArrayItem()
{
	local STDIN=$(getStdIn) 
	local DELIM=${2:-' '}
	local ITEM
	local RV
	
	if [[ "$STDIN" == *"$DELIM"* ]]; then
		debecho getArrayItem "$STDIN" contains delim "$DELIM"
		IFS="$DELIM" read -r -a LIST <<< "$STDIN"
		ITEM="${LIST["$1"]}"
		RV=$?
	else
		debecho getArrayItem "$STDIN" does not contain delim "$DELIM"
		ITEM="$STDIN"
		RV=0	
	fi
	
	echo "$ITEM"
	debecho getArrayItem ITEM="$ITEM"
	return "$RV"
}
readonly -f getArrayItem
#debugFlagOn getArrayItem

#usage:  echo "a:b c:d e f" | getArrayItemsAsLines :
#  		echo "a b c" | getArrayItemsAsLines 
getArrayItemsAsLines()
{
	local STDIN=$(getStdIn) 
	local DELIM=${1:-' '}
	local ITEM
	local RV
	
	if [[ "$STDIN" == *"$DELIM"* ]]; then
		debecho getArrayItemsAsLines "$STDIN" contains delim "$DELIM"
		IFS="$DELIM" read -r -a LIST <<< "$STDIN"
		
		for EACH in "${LIST[@]}"
		do
			debecho getArrayItemsAsLines each "$EACH"
			echo "$EACH"
		done
		
		RV=0
	else
		debecho getArrayItemsAsLines "$STDIN" does not contain delim "$DELIM"
		RV=1	
	fi
	
	return "$RV"
}
readonly -f getArrayItemsAsLines
#debugFlagOn getArrayItemsAsLines

#usage: echo a b c | getFirstArrayItem 		#to get next, space delimiter
#							getFirstArrayItem :	#to get next, : delimiter
getFirstArrayItem()
{
	local STDIN=$(getStdIn) 
	echo $STDIN | getArrayItem 0 "$1"
}
readonly -f getFirstArrayItem
#debugFlagOn getFirstArrayItem

#usage: echo a b c | getFirstArrayItem 		#to get next, space delimiter
#							getFirstArrayItem :	#to get next, : delimiter
getFirstArrayItemRemainder()
{
	local STDIN=$(getStdIn) 
	local ITEM=$(echo "$STDIN" | getFirstArrayItem "$1")
	debecho getFirstArrayItemRemainder item "$ITEM"
	local ITEMLEN=$(echo "$ITEM" | getLength)
	local DELIMLEN=$(echo "$1" | getLength)
	local LEN=$((ITEMLEN + DELIMLEN))
	debecho getFirstArrayItemRemainder len "$LEN"
	local REM=$(echo "$STDIN" | getSubstring "$LEN")
	debecho getFirstArrayItemRemainder remainder "$REM"
	
	local RV=$?
	echo "$REM"
	return "$RV"
}
readonly -f getFirstArrayItemRemainder
#debugFlagOn getFirstArrayItemRemainder

#splits stdin into an array (using $1 as the delim) and then performs a function ($2+) on each item (piped into the function)
#usage:  echo "a:b c:d e f" | doEach : echo 
doEach()
{
	local STDIN=$(getStdIn) 
	debecho doEach stdin "$STDIN"
	local DELIM=${1:-' '}
	debecho doEach delim "$DELIM"
			
	shift
	local ITEM
	local RV
	
	if [[ "$STDIN" == *"$DELIM"* ]]; then
		debecho doEach "$STDIN" contains delim "$DELIM"
		IFS="$DELIM" read -r -a LIST <<< "$STDIN"
		
		for EACH in "${LIST[@]}"
		do
			debecho doEach each "$EACH"
			echo "$EACH" | makeCall "$@"			
		done
		
		RV=0
	else
		debecho doEach "$STDIN" does not contain delim "$DELIM"
		RV=1	
	fi
	
	return "$RV"
}
readonly -f doEach
#debugFlagOn doEach

#reads stdin as lines and then performs a function ($2+) on each item (piped into the function)
#usage:  echo $manylines | doEachLine echo 
doEachLine()
{
	local STDIN=$(getStdIn) 

	IFS=$'\n' read -d '' -r -a LIST <<< "$STDIN"
	
	for EACH in "${LIST[@]}"
	do
		debecho doEachLine each "$EACH"
		echo "$EACH" | makeCall "$@"			
	done

	return 0
}
readonly -f doEachLine
#debugFlagOn doEachLine

#appends stdin to the provided file arg.  
#while this is a trivial operation to do in shell with redirection, having a helper function is useful during
#piped list iteration
#usage:  echo something | doEach , appendToFile fileName
appendToFile()
{
	local STDIN=$(getStdIn)
	debecho appendToFile stdin "$STDIN"
	local FILE="$1"
	debecho appendToFile file "$FILE"

	$(echo "$STDIN"  >> "$FILE" )  

}
readonly -f appendToFile
#debugFlagOn appendToFile

#joins two lists together of the same length, side by side
#usage:  echo mylist | sideJoinLists myotherlistVarName joinString 
sideJoinLists()
{
	local STDIN=$(getStdIn)
	local VARNAME="$1"
	local LIST2=${!VARNAME}
	local JOINER="$2"
	
	#ensure they are the same length
	local LEN=$(echo "$STDIN" | getLineCount)
	echo "$LIST2" | getLineCount | ifEquals "$LEN" > /dev/null || return 1
	
	#convert both lists to arrays
	IFS=$'\n' read -d '' -r -a ARR1 <<< "$STDIN"
	IFS=$'\n' read -d '' -r -a ARR2 <<< "$LIST2"
	
	#debecho sideJoinLists arr1 "${ARR1[*]}"
	
	for ((i = 0 ; i < "$LEN" ; i++)); do
		ITEM1="${ARR1[$i]}"
		ITEM2="${ARR2[$i]}"
  		echo "${ARR1[$i]}""$JOINER""${ARR2[$i]}"
 	done
 	return 0
}
readonly -f sideJoinLists
debugFlagOn sideJoinLists