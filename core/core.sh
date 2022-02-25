#!/bin/bash
#this has the core libs that must be loaded first
#contains:
# library loader:  loadScript
# debugging utils:  debugFlagOn, debugFlagOff, debecho

#if this script has been loaded already we stop
[ -z "${IS_CORE_LOADED}" ] &&
{
	declare -r IS_CORE_LOADED=true

	#set BASH_DIR.  this will clobber prior values.  all scripts are then loaded relative to the scriptloader
	BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
	#flag it as readonly
	readonly BASH_DIR
	
	#DEBUGGING STUFF
	
	#hash of debug flags
	declare -gA DEBUG_FLAGS;
	
	#enables a debug flag.  when enabled and passed to debecho (as first arg), the message is written
	debugFlagOn()
	{
		DEBUG_FLAGS["$1"]=true
	}
	readonly -f debugFlagOn
	#        ^^^ -f declare functions readonly to prevent overwriting and notify of duplicate lib calls
	
	#disables a debug flag.  when disabled the message is not written
	debugFlagOff()
	{
		DEBUG_FLAGS["$1"]=false
	}
	readonly -f debugFlagOff
	#        ^^^ -f declare functions readonly to prevent overwriting and notify of duplicate lib calls
	
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
	readonly -f isDebugFlagOn
	#        ^^^ -f declare functions readonly to prevent overwriting and notify of duplicate lib calls
	
	#write a debug entry if the flag exists
	#usage: debecho flagName text to write out
	debecho () 
	{
		isDebugFlagOn "$1" && { shift; echo -e "[\e[01;31mfunction:${FUNCNAME[1]} line:${BASH_LINENO} $@\e[0m]" >&2; } 
																												#						         ^^^ to stderr
	  	return 0	  	
	}
	readonly -f debecho 
	#        ^^^ -f declare functions readonly to prevent overwriting and notify of duplicate lib calls
	
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
	readonly -f dumpDirContents
	#        ^^^ -f declare functions readonly to prevent overwriting and notify of duplicate lib calls
	#debugFlagOn dumpDirContents	
	
	#SCRIPT LOADER

	#hash of debug flags
	declare -gA LOADED_SCRIPTS;
	
	#mark the current script as loaded
	LOADED_SCRIPTS["$BASH_DIR""/../core/core.sh"]=$(date +"%y%m%d%H%M%S")
	
	#loads a script if it hasn't already been loaded
	loadScript()
	{
		if [ ! -v LOADED_SCRIPTS["$1"] ]; then
			debecho loadScript loading "$1"
			#load it		
			LOADED_SCRIPTS["$1"]=$(date +"%y%m%d%H%M%S")
			source "$1"
			return 0
		else
			debecho loadScript already loaded "$1"
		fi
		
		#already loaded
		return 1
	}
	readonly -f loadScript
	#        ^^^ -f declare functions readonly to prevent overwriting and notify of duplicate lib calls
	#debugFlagOn loadScript	
}
	