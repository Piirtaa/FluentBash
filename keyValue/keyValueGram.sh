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

#description:  returns the datagram of an associative array
#usage:  getKeyValueGram hashName
getKeyValueGram()
{
	local -n MYHASH=$1 #uses nameref bash 4.3+
	for EACH in "${!MYHASH[@]}"; do
		local VAL="${MYHASH[$EACH]}"
		
		#note:  we put the length first because it facilitates faster filtering of the raw datagram
		if [[ -z "$VAL" ]]; then
			echo "_KEY_0_""$EACH"
		else
			local LEN=$(echo "$VAL" | getLineCount)		
			echo "_KEY_""$LEN""_""$EACH"
			echo "$VAL"
		fi	
	done
}
readonly -f getKeyValueGram
#debugFlagOn getKeyValueGram

#description:  dumps a keyvalue gram into an array
#usage:  declare -A HASH ; readKeyValueGram HASH <<< "$GRAM".  does not work with piped input
readKeyValueGram()
{
	if [[ -z "$1" ]]; then
		debecho readKeyValueGram no array provided
		return 1	
	fi

	local STDIN=$(getStdIn) 
	debecho readKeyValueGram stdin "$STDIN"

	local -n RETURNHASH=$1 #uses nameref bash 4.3+
		#below doesn't work in 4.3 but is supposed to work on earlier versions of bash		
		#local arrayname=$1
  		#local tmp=$arrayname[@]
  		#local RETURNHASH=( "${!tmp}" )
	
	local LEN
	LEN=$(echo "$STDIN" | getLineCount)
	debecho readKeyValueGram len "$LEN"
	
	local ARR	
	IFS=$'\n' read -d '' -r -a ARR <<< "$STDIN"
	#iterate over each line
	for ((i = 0 ; i < "$LEN" ; i++)); do
		local LINE="${ARR[$i]}"
		debecho readKeyValueGram line "$LINE"
	
		#keys have the form "_KEY_numberOfLines_key"
		local COUNT_KEY=$(echo "$LINE" | ifStartsWith "_KEY_" | getAfter "_KEY_" )
		debecho readKeyValueGram countkey "$COUNT_KEY"
		
		if [[ ! -z "$COUNT_KEY" ]]; then
			local COUNT=$(echo "$COUNT_KEY" | getBefore "_" )
			local KEY=$(echo "$COUNT_KEY" | getAfter "_" )
			debecho readKeyValueGram count "$COUNT"
			debecho readKeyValueGram key "$KEY"
			
			if [[ "$COUNT" == 0 ]] ; then
				debecho readKeyValueGram key "$KEY" val  
				RETURNHASH["$KEY"]=""				
			else
				#start reading value at next line
				i=$((i + 1))
				local VAL="${ARR[$i]}"
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



#description:  sets an entry in the gram
#usage: echo $GRAM | kvgSet key value
kvgSet()
{
	local KEY="$1"	
	if [[ -z "$KEY" ]]; then
		debecho kvgSet no key provided
		return 1	
	fi
	local VAL="${@:2}"
	
	debecho kvgSet key "$KEY"
	debecho kvgSet val "$VAL"
			
	#convert the gram into a hash
	local GRAM=$(getStdIn)
	debecho kvgSet gram "$GRAM"
		
	local -A HASH
	readKeyValueGram HASH <<< "$GRAM"
	
	
	#write the kvp
	HASH["$KEY"]="$VAL"
	debecho kvgSet writing "$KEY" "$VAL"

	#convert it back into a gram
	GRAM=$(getKeyValueGram HASH) 
	debecho kvgSet gram "$GRAM"
	
	#pipe it back out
	echo "$GRAM"
	return 0
}
readonly -f kvgSet
#debugFlagOn kvgSet

#description:  gets an entry in the gram
#usage: echo $GRAM | kvgGet key
kvgGet()
{
	local KEY="$1"	
	if [[ -z "$KEY" ]]; then
		debecho kvgGet no key provided
		return 1	
	fi

	#convert the gram into a hash
	local GRAM VAL RV 	
	GRAM=$(getStdIn)
	
	local -A HASH
	readKeyValueGram HASH <<< "$GRAM"
	VAL="${HASH["$KEY"]}"
	RV=$?

	#look for a line that matches _KEY_*_myKey
	#local LINE
	#LINE=$(echo "$GRAM" | grep -n "^_KEY_.*""$KEY"'$')
	#RV=$?
	#debecho kvgGet found line "$LINE"	

	if [[ "$RV" == 0 ]]; then
	#	local LINENUM=$(echo "$LINE" | cut -d : -f 1 )
	#	local LEN=$(echo "$LINE" | getAfter "_" | getAfter "_" | getBefore "_" )
	 
	# 	if [[ "$LEN" > 0 ]]; then
	# 		debecho kvgGet linenum "$LINENUM"
	# 		debecho kvgGet len "$LEN"
		
			#get from linenum 
	#		VAL=$(echo "$GRAM" | getLinesBelow "$LINENUM" | getLinesAbove $(( LEN + 1 )) )
			#pipe it back out
	#		debecho kvgGet val "$VAL"
					
			echo "$VAL"
	# 	fi
	fi

	return "$RV"
}
readonly -f kvgGet
#debugFlagOn kvgGet

#description:  gets all keys, each as separate lines
#usage: echo $GRAM | kvgGetAllKeys 
kvgGetAllKeys()
{
	#convert the gram into a hash
	local GRAM=$(getStdIn)
	local LINES
	LINES=$(echo "$GRAM" | grep "^_KEY_")
	LINES=$(echo "$LINES" | doEachLine getAfter "_KEY" | doEachLine getAfter "_" | doEachLine getAfter "_" )
	RV=$?
	debecho kvgGetAllKeys found lines "$LINES"	
	echo "$LINES"
	return "$RV"
}
readonly -f kvgGetAllKeys
#debugFlagOn kvgGetAllKeys

