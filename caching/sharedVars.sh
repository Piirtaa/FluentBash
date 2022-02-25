#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript $BASH_DIR/../piping/piping.sh
loadScript $BASH_DIR/../piping/strings.sh
loadScript $BASH_DIR/../piping/lists.sh
loadScript $BASH_DIR/../piping/conditionals.sh


#sources var file if the local timestamp is less (or null) than the file timestamp
#usage: 	doUpdate filename
doUpdate()
{
	local FILE="$1"
	local FILESTAMP=$(cat "$FILE".update)
	debecho doUpdate filestamp "$FILESTAMP"	 
	local VARNAME=STAMP_$(echo "$FILE" | tr -d "./" ) #scrub to get valid var name
	debecho doUpdate varname "$VARNAME" 	
	local OURSTAMP=${!VARNAME}	
	debecho doUpdate ourstamp "$OURSTAMP"	

	if [[ "$OURSTAMP" -lt "$FILESTAMP" ]]; then
			debecho doUpdate update indicated
			source "$FILE"
			local UNIXTIME="$(date +%s)"	
			eval $VARNAME=$UNIXTIME
			
			OURSTAMP=${!VARNAME}	
			debecho doUpdate ourstamp "$OURSTAMP"	
	fi
}
readonly -f doUpdate
#debugFlagOn doUpdate

#checks for valid (ie. alphanumeric) var name
isValidVarName() {
    echo "$1" | grep -q '^[_[:alpha:]][_[:alpha:][:digit:]]*$' && return || return 1
}
readonly -f isValidVarName


#writes an existing var to the var file and updates varfile timestamp
#usage:  shareVar file variable.  eg. shareVar dumpfile myvarname.  don't use $myvarname
shareVar()
{
	local FILE="$1"
	debecho shareVar file "$FILE"
	local NAME="$2"
	debecho shareVar name "$NAME"
	local VAL="${!2}"
	debecho shareVar val "$VAL"
	
	#validate
	if isValidVarName "$NAME"; then
		local LINE="${NAME}="\""${VAL}"\"
		debecho shareVar line "$LINE"
		
		if [[ ! -e "$FILE" ]]; then
			#add the line
			echo "$LINE" >> "$FILE"
		else
			IDX=$(grep -n "${NAME}=" "$FILE" | awk -F: '{print $1}')
			debecho shareVar idx "$IDX"
			
			if (( "$IDX" >= 0 )); then
				#replace the line
				cat "$FILE" | replaceLine "$IDX" "$LINE" > "$FILE"
			else
				#add the line
				echo "$LINE" >> "$FILE"
			fi 
		fi	
		#update the file time
		UNIXTIME="$(date +%s)"	
		echo "$UNIXTIME" > "$FILE".update
		
		return 0		
	fi
	
	return 1
}
readonly -f shareVar
#debugFlagOn shareVar

#removes a var from the varfile
#usage:  unshareVar file variable
unshareVar()
{
	local FILE="$1"
	debecho unshareVar file "$FILE"
	local NAME="$2"
	debecho unshareVar name "$NAME"
	
	#validate
	if [[ -e "$FILE" ]]; then
		IDX=$(grep -n "${NAME}=" "$FILE" | awk -F: '{print $1}')
		debecho unshareVar idx "$IDX"
		
		if (( "$IDX" >= 0 )); then
			debecho unshareVar removing "$IDX"
			#replace the line
			cat "$FILE" | removeLine "$IDX" > "$FILE"

			#update the file time
			UNIXTIME="$(date +%s)"	
			echo "$UNIXTIME" > "$FILE".update
	
			return 0		
		fi 
	fi	

	return 1
}
readonly -f unshareVar
#debugFlagOn unshareVar
