#!/bin/bash
#summary:  persistent key value store
#tags: key value store, persistence, in memory data

#usage:  
#	keyValueStore.sh build #inits the store
#	keyValueStore.sh #loads the existing store

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh

#configuration of this subsystem
loadScript caching/keyValueStoreConfig.sh

#increments counter
_updateCounter()
{
	#create lock file with descriptor 200
	exec 200>"$COUNTER_LOCK" || exit 1

	#lock the descriptor	
	flock 200 || return 1
	
   # commands executed under lock are place here
	local CURRENT_INDEX=$(cat "$COUNTER_FILE")
	CURRENT_INDEX=$((CURRENT_INDEX+1))
	echo "$CURRENT_INDEX" > "$COUNTER_FILE"   

	#unlock the descriptor
	flock -u 200

	debecho _updateCounter "incremented index to " "$CURRENT_INDEX"
	
	#return it
	echo "$CURRENT_INDEX"
	return 0
}
readonly -f _updateCounter
#debugFlagOn _updateCounter

#finds the index for the provided key in the index file
_getKeyIndex()
{
	#NOTE:  the format of an entry in the index file is 2 lines.  the first has the length of the key.  the second is "key index" 

	local LEN=${#1}
	local INDEX=-1
	local LINELEN=0
	local ISHEADERLINE=true
	local SKIPNEXT=false
	
	#debecho _getKeyIndex looking for key "$1" of length "$LEN"
			
	while IFS= read -r LINE
	do
		#debecho _getKeyIndex on line \""$LINE"\"        

		#skip flag
		if [[ "$SKIPNEXT" == true ]]; then
			#debecho _getKeyIndex skipping        
      	SKIPNEXT=false
      	
      	#toggle 
      	if [[ "$ISHEADERLINE" == true ]]; then
				ISHEADERLINE=false      	
      	else
      		ISHEADERLINE=true
      	fi
      	 
      	continue
		fi
		    
		if [[ "$ISHEADERLINE" == true ]]; then
			LINELEN="${LINE}"
			#debecho _getKeyIndex header of length "$LINELEN"        
      				
			if [[ "$LINELEN" != "$LEN" ]]; then
				#debecho _getKeyIndex length unequal skipping        
				SKIPNEXT=true
			#else
				#debecho _getKeyIndex length equal not skipping        
			fi

			ISHEADERLINE=false #toggle for next iteration
			
			continue
		else
			#data line
			local KEY=${LINE:0:$LEN}
			#debecho _getKeyIndex line key is \""$KEY"\"        
			if [[ "$KEY" == "$1" ]] ; then
				INDEX=${LINE:$((LEN+1))}
				#debecho _getKeyIndex match.  index is "$INDEX"        
				break
			fi
			ISHEADERLINE=true #toggle for next iteration
		fi
	done < "$INDEX_FILE"
		
	if [[ "$INDEX" == -1 ]] ; then
		#debecho _getKeyIndex "key="\""$1"\" "index not found"
		return 1
	else
		#debecho _getKeyIndex "key="\""$1"\" "index=""$INDEX"
		echo "$INDEX"
		return 0
	fi
}
readonly -f _getKeyIndex
#debugFlagOn _getKeyIndex

#tests if the key exists in the index file
existsKV()
{
	_getKeyIndex "$1"
}
readonly -f existsKV
#debugFlagOn existsKV

#gets the value provided the key
getKV()
{
	#debecho getKV getKV \""$1"\"
	
	local INDEX=$(_getKeyIndex "$1" )
	[ -z "$INDEX" ] && return 1 ;

	cat "$DATAFS"/"$INDEX"
	return 0
}
readonly -f getKV
#debugFlagOn getKV

#sets key and value
setKV()
{
	#debecho setKV setKV \""$1"\" \""$2"\"
	
	#look for an index for the provided key		
	local INDEX=$(_getKeyIndex "$1")
	
	#if record not found, update the counter, add an entry to index 
	[ -z "$INDEX" ] && INDEX=$(_updateCounter) && \
	echo ${#1} >> "$INDEX_FILE" && \
	echo "$1" "$INDEX" >> "$INDEX_FILE" 
	
	#write the data file
	echo "$2" > "$DATAFS"/"$INDEX"
	#debecho setKV index="$INDEX" key=\""$1"\" value=\""$2"\"	
	return 0
}
readonly -f setKV
#debugFlagOn setKV

#looks for a cached version of a function call and echoes it
#works with stdin and arguments
#usage:  cacheFunction doFunction arg1 arg2
cacheFunction()
{
	local KEY=""
	local HAS_STDIN=false	
	local STDIN=$(getStdIn)
		
	if [ -z "$STDIN" ]; then
		KEY="$@"	
	else
		HAS_STDIN=true		
		KEY="$STDIN""->""$@"
	fi	

	local KEYRV="$KEY""->"RV	
	debecho cacheFunction key is \""$KEY"\" 

	#hit the cache	
	local RESULT=$(getKV "$KEY")
	local RV=$(getKV "$KEYRV")
		
	#if it's not cached eval it
	if [[ -z "$RESULT" ]]; then
		debecho cacheFunction \""$KEY"\" not cached
		if [[ "$HAS_STDIN" == true ]] ; then
   		RESULT=$(echo "$STDIN" | "$@")
		else
			RESULT=$("$@")		
		fi
   	RV="$?"		
   	
		debecho cacheFunction "caching" \""$KEY"\"=\""$RESULT"\"		
		setKV "$KEY" "$RESULT"	
		setKV "$KEYRV" "$RV"
	else
		debecho cacheFunction pulling from cache
	fi

	debecho cacheFunction result is \""$RESULT"\"
	debecho cacheFunction returnValue is "$RV"
	
	echo "$RESULT"
	return "$RV"
}
readonly -f cacheFunction
#debugFlagOn cacheFunction