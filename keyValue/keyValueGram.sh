#!/bin/bash
#summary:  a keyvalue datagram
#tags: keyvalue, datagram

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh

#description:  dumps a keyvalue gram into an array
#usage:  declare -A HASH ; readKeyValueGram HASH <<< "$GRAM".  does not work with piped input
readKeyValueGram()
{
	local STDIN=$(getStdIn) 
	debecho readKeyValueGram stdin "$STDIN"
	if [[ -z "$1" ]]; then
		debecho readKeyValueGram no array provided
		return 1	
	fi
	
	local -n RETURNHASH=$1 #uses nameref bash 4.3+
		#below doesn't work in 4.3 but is supposed to work on earlier versions of bash		
		#local arrayname=$1
  		#local tmp=$arrayname[@]
  		#local RETURNHASH=( "${!tmp}" )
	
	LEN=$(echo "$STDIN" | getLineCount)
	debecho readKeyValueGram len "$LEN"
		
	IFS=$'\n' read -d '' -r -a ARR <<< "$STDIN"
	#iterate over each line
	for ((i = 0 ; i < "$LEN" ; i++)); do
		LINE="${ARR[$i]}"
		debecho readKeyValueGram line "$LINE"
	
		#keys have the form "_KEY_length_name"
		COUNT_KEY=$(echo "$LINE" | ifStartsWith "_KEY_" | getAfter "_KEY_" )
		debecho readKeyValueGram countkey "$COUNT_KEY"
		
		if [[ ! -z "$COUNT_KEY" ]]; then 
			KEY=$(echo "$COUNT_KEY" | getBefore "_" )
			COUNT=$(echo "$COUNT_KEY" | getAfter "_" )
			debecho readKeyValueGram count "$COUNT"
			debecho readKeyValueGram key "$KEY"

			if [[ "$COUNT" == 0 ]] ; then
				debecho readKeyValueGram key "$KEY" val  
				RETURNHASH["$KEY"]=""				
			else
				#start reading value at next line
				i=$((i + 1))
				VAL="${ARR[$i]}"
				COUNT=$((COUNT - 1))
				for ((j=0; j < "$COUNT" ; j++)); do
					i=$((i + 1))
					VAL=$(echo "$VAL" | appendLine "${ARR[$i]}" )
				done	
				debecho readKeyValueGram key "$KEY" val "$VAL"  
				RETURNHASH["$KEY"]="$VAL"		
			fi
		fi
	done
}
readonly -f readKeyValueGram
#debugFlagOn readKeyValueGram

#description:  dumps the contents of an associative array
#usage:  dumpHash varName
dumpHash()
{
	local -n MYHASH=$1 #uses nameref bash 4.3+
	for K in "${!MYHASH[@]}"; do echo $K --- ${MYHASH[$K]}; done
}
readonly -f dumpHash

#description:  returns the datagram of an associative array
#usage:  getKeyValueGram hashName
getKeyValueGram()
{
	local -n MYHASH=$1 #uses nameref bash 4.3+
	for EACH in "${!MYHASH[@]}"; do
		local VAL="${MYHASH[$EACH]}"
		if [[ -z "$VAL" ]]; then
			echo "_KEY_""$EACH""_0"
		else
			local LEN=$(echo "$VAL" | getLineCount)		
			echo "_KEY_""$EACH""_""$LEN"
			echo "$VAL"
		fi	
	done
}
readonly -f getKeyValueGram
#debugFlagOn getKeyValueGram



