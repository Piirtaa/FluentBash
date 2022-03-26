#!/bin/bash
#this has the core libs that must be loaded first
#contains:
# library loader:  loadScript
# debugging utils:  debugFlagOn, debugFlagOff, debecho

#if this script has been loaded already we stop
[ -z "${IS_CORE_LOADED}" ] &&
{
	export LC_ALL=C #to speed stuff up by not using any unicode
	
	typeset -r IS_CORE_LOADED=true

	#set BASH_DIR.  this will clobber prior values.  all scripts are then loaded relative to the scriptloader
	BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
	#flag it as readonly
	readonly BASH_DIR
	
	#DEBUGGING STUFF
	
	#hash of debug flags
	typeset -A DEBUG_FLAGS;
	
	#enables a debug flag.  when enabled and passed to debecho (as first arg), the message is written
	debugFlagOn()
	{
		DEBUG_FLAGS["$1"]=true
	}
	#readonly -f debugFlagOn
	#        ^^^ -f typeset functions readonly to prevent overwriting and notify of duplicate lib calls
	
	#disables a debug flag.  when disabled the message is not written
	debugFlagOff()
	{
		DEBUG_FLAGS["$1"]=false
	}
	#readonly -f debugFlagOff
	#        ^^^ -f typeset functions readonly to prevent overwriting and notify of duplicate lib calls
	
	#tests whether a debug flag has been set.  returns true only if explicitly set on
	isDebugFlagOn()
	{
		if [ ! -v DEBUG_FLAGS["$1"] ]; then
			#flag is not set, presume off
			return 1
		fi
			
		if [ ${DEBUG_FLAGS[$1]} == true ]; then
			return 0
		fi
		
		return 1
	}
	#readonly -f isDebugFlagOn
	#        ^^^ -f typeset functions readonly to prevent overwriting and notify of duplicate lib calls
	
	#write a debug entry if the flag exists
	#usage: debecho flagName text to write out
	debecho () 
	{
		local IDX STACK
		
		for (( IDX=${#FUNCNAME[@]}-1 ; IDX>=1 ; IDX-- )) ; do
			STACK="$STACK""${FUNCNAME[IDX]}""-->"			
		done
		
		#isDebugFlagOn "$1" && { shift; echo -e "[\e[01;31mfunction:${FUNCNAME[2]} function:${FUNCNAME[1]} line:${BASH_LINENO} $@\e[0m]" >&2; } 
		isDebugFlagOn "$1" && { shift; echo -e "[\e[01;31m${STACK} line:${BASH_LINENO} $@\e[0m]" >&2; } 
																												#						         ^^^ to stderr
	  	return 0	  	
	}
	#readonly -f debecho 
	#        ^^^ -f typeset functions readonly to prevent overwriting and notify of duplicate lib calls
	
	#dumps contents of specified directory
	dumpDirContents()
	{
		for FILE in "$1"/*; do
	    	debecho DUMP "$FILE"
	    	echo "$FILE"
	    	cat "$FILE"
	    	echo 
		done
	}
	#readonly -f dumpDirContents
	#        ^^^ -f typeset functions readonly to prevent overwriting and notify of duplicate lib calls
	#debugFlagOn dumpDirContents	
	
	waitForKeyPress()
	{
		echo "Press any key to continue"
		while [ true ] ; do
			read -t 3 -n 1
			if [ $? = 0 ] ; then
				return 0 
			else
				echo "waiting for the keypress"
			fi
		done	
	}
	#readonly -f waitForKeyPress
	
	#generates random alpha numeric of given length (defaults to 5)
	#usage:  genID length
	genID()
	{
		local LENGTH
		LENGTH="${1:-5}"
		cat /dev/urandom | env LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w "$LENGTH" | head -n 1	
	}
	#readonly -f genID
	
	#SCRIPT LOADER

	#hash of debug flags
	typeset -A LOADED_SCRIPTS;
	
	#mark the current script as loaded
	LOADED_SCRIPTS["core/core.sh"]=$(date +"%y%m%d%H%M%S")
	
	#loads a script if it hasn't already been loaded
	loadScript()
	{
		if [ ! -v LOADED_SCRIPTS["$1"] ]; then
			debecho loadScript loading "$1"
			#load it		
			LOADED_SCRIPTS["$1"]=$(date +"%y%m%d%H%M%S")
			. "$BASH_DIR"'/../'"$1"

			debecho loadScript loaded "$1"
			
			return 0
		fi
		
		#already loaded
		debecho loadScript already loaded "$1"
		return 1
	}
	#readonly -f loadScript
	#        ^^^ -f typeset functions readonly to prevent overwriting and notify of duplicate lib calls
	#debugFlagOn loadScript	
}
	
