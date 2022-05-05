#!/bin/bash

#load loader first
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader


#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh
loadScript piping/jsSandbox.sh

function generateGram1()
{
	local LEVELS=5000
	local BRANCHES=5
	local GRAM L B KEYPATH DATA BRANCHPATH
	GRAM=""
	KEYPATH=""
	for ((L = 0 ; L < "$LEVELS" ; L++)); do
		KEYPATH="$KEYPATH"_"level""$L"
		DATA="level""$L""data"
		GRAM=$(echo "$GRAM" | ./bookGram.js add "$KEYPATH" "$DATA")
		
		for ((B = 0; B < "$BRANCHES"; B++)); do
			BRANCHPATH="$KEYPATH""branch""$B"
			DATA="branch""$B""data"
			DATA=$(echo "$DATA" | appendLine "$DATA" | appendLine "$DATA")
			GRAM=$(echo "$GRAM" | ./bookGram.js add "$BRANCHPATH" "$DATA")		
		done
		
		GRAM=$(echo "$GRAM" | ./bookGram.js remove "$BRANCHPATH" "$DATA")		
		
		
	done
	echo "$GRAM"
}

time generateGram1

#MYGRAM=$(generateGram)
#echo raw gram
#echo
#echo "$MYGRAM"
#echo
#echo formatted gram
#echo
#echo "$MYGRAM" | ./bookGram.js format "{0} {1}"
#echo
#echo emerged
#echo
#echo "$MYGRAM" | ./bookGram.js emerge
#echo
#echo emerged formatted
#echo
#echo "$MYGRAM" | ./bookGram.js emerge | ./bookGram.js format "key: {0}"
#echo "$MYGRAM" | ./bookGram.js emerge | ./bookGram.js format "data: {1}"
#echo
#echo "$MYGRAM" | ./bookGram.js emerge _level0_level1 | ./bookGram.js format "{0} {1}"
#echo
#echo query
#echo "$MYGRAM" | ./bookGram.js query level3 | ./bookGram.js format "{0} {1}"
#echo getExactValues
#echo "$MYGRAM" | ./bookGram.js getExactValues _level0_level1 

exit

