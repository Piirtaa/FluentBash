#!/bin/bash
#summary:  fluent list functions
#tags: list

#load loader first.  
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

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
	local STDIN DELIM ITEM RV LIST
	STDIN=$(getStdIn) 
	DELIM=${2:-' '}
	
	if [[ "$STDIN" == *"$DELIM"* ]]; then
		#debecho getArrayItem "$STDIN" contains delim "$DELIM"
		IFS="$DELIM" read -r -a LIST <<< "$STDIN"
		ITEM="${LIST["$1"]}"
		RV=$?
	else
		#debecho getArrayItem "$STDIN" does not contain delim "$DELIM"
		ITEM="$STDIN"
		RV=0	
	fi
	
	echo "$ITEM"
	#debecho getArrayItem ITEM="$ITEM"
	return "$RV"
}
readonly -f getArrayItem
#debugFlagOn getArrayItem

#usage:  echo "a:b c:d e f" | getArrayItemsAsLines :
#  		echo "a b c" | getArrayItemsAsLines 
getArrayItemsAsLines()
{
	local STDIN DELIM ITEM RV LIST EACH
	STDIN=$(getStdIn) 
	DELIM=${1:-' '}
	
	if [[ "$STDIN" == *"$DELIM"* ]]; then
		#debecho getArrayItemsAsLines "$STDIN" contains delim "$DELIM"
		IFS="$DELIM" read -r -a LIST <<< "$STDIN"
		
		for EACH in "${LIST[@]}"
		do
			#debecho getArrayItemsAsLines each "$EACH"
			echo "$EACH"
		done
		
		RV=0
	else
		#debecho getArrayItemsAsLines "$STDIN" does not contain delim "$DELIM"
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
	local STDIN
	STDIN=$(getStdIn) 
	#echo $STDIN | getArrayItem 0 "$1"
	#getArrayItem 0 "$1" <<< $STDIN
	getArrayItem 0 "$1" < <(echo $STDIN)
}
readonly -f getFirstArrayItem
#debugFlagOn getFirstArrayItem

#usage: echo a b c | getFirstArrayItem 		#to get next, space delimiter
#							getFirstArrayItem :	#to get next, : delimiter
getFirstArrayItemRemainder()
{
	local STDIN ITEM ITEMLEN DELIMLEN LEN REM RV
	STDIN=$(getStdIn) 
	#ITEM=$(echo "$STDIN" | getFirstArrayItem "$1")
	ITEM=$(getFirstArrayItem "$1" < <(echo "$STDIN"))
	#ITEM=$(getFirstArrayItem "$1" <<< "$STDIN")
	#debecho getFirstArrayItemRemainder item "$ITEM"
	#ITEMLEN=$(echo "$ITEM" | getLength)
	ITEMLEN=$(getLength < <(echo "$ITEM"))
	#ITEMLEN=$(getLength <<< echo "$ITEM")
	#DELIMLEN=$(echo "$1" | getLength)
	DELIMLEN=$(getLength < <(echo "$1"))
	#DELIMLEN=$(getLength <<< echo "$1")
	LEN=$((ITEMLEN + DELIMLEN))
	#debecho getFirstArrayItemRemainder len "$LEN"
	#REM=$(echo "$STDIN" | getSubstring "$LEN")
	REM=$(getSubstring "$LEN" < <(echo "$STDIN"))
	#REM=$(getSubstring "$LEN" <<< echo "$STDIN")
	#debecho getFirstArrayItemRemainder remainder "$REM"
	
	RV=$?
	echo "$REM"
	return "$RV"
}
readonly -f getFirstArrayItemRemainder
#debugFlagOn getFirstArrayItemRemainder

#splits stdin into an array (using $1 as the delim) and then performs a function ($2+) on each item (piped into the function)
#usage:  echo "a:b c:d e f" | doEach : echo 
doEach()
{
	local STDIN DELIM ITEM RV LIST EACH 
	STDIN=$(getStdIn) 
	#debecho doEach stdin "$STDIN"
	DELIM=${1:-' '}
	#debecho doEach delim "$DELIM"
	shift
	
	if [[ "$STDIN" == *"$DELIM"* ]]; then
		#debecho doEach "$STDIN" contains delim "$DELIM"
		IFS="$DELIM" read -r -a LIST <<< "$STDIN"
		
		for EACH in "${LIST[@]}"
		do
			#debecho doEach each "$EACH"
			#echo "$EACH" | makeCall "$@"
			#makeCall "$@" <<< "$EACH"
			makeCall "$@" < <(echo "$EACH")			
		done
		
		RV=0
	else
		#debecho doEach "$STDIN" does not contain delim "$DELIM"
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
	local STDIN LIST EACH
	STDIN=$(getStdIn) 

	IFS=$'\n' read -d '' -r -a LIST <<< "$STDIN"
	
	for EACH in "${LIST[@]}"
	do
		#debecho doEachLine each "$EACH"
		#echo "$EACH" | makeCall "$@"
		#makeCall "$@" <<< "$EACH"	
		makeCall "$@" < <(echo "$EACH")		
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
	local STDIN FILE
	STDIN=$(getStdIn)
	#debecho appendToFile stdin "$STDIN"
	FILE="$1"
	#debecho appendToFile file "$FILE"

	$(echo "$STDIN"  >> "$FILE" )  

}
readonly -f appendToFile
#debugFlagOn appendToFile

#joins two lists together of the same length, side by side
#usage:  echo mylist | sideJoinLists myotherlistVarName joinString 
sideJoinLists()
{
	local STDIN VARNAME LIST2 JOINER LEN ARR1 ARR2 ITEM1 ITEM2
	STDIN=$(getStdIn)
	VARNAME="$1"
	LIST2=${!VARNAME}
	JOINER="$2"
	
	#ensure they are the same length
	LEN=$(echo "$STDIN" | getLineCount)
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
#debugFlagOn sideJoinLists
