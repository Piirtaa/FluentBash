#!/bin/bash
#summary:  meta reporting on scripts
#tags: meta, fluentBash

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh


#we need a way to query for functionality in our libraries to and to know to use it.
#to facilitate this we are adding meta information comments to scripts that follows the format below

#scripts.sh
	#summary:  a summary of the script 
	#tags: a, b, c
	#....
	#usage:  appears in the lines directly above function definitions
	#description:  appears in the lines directly above function definitions
	#myFunction

#description:  finds all scripts (name ends in .sh,  has a shebang)
#usage:  getAllScripts 
getAllScripts()
{
	#get all a) files with b) a name ending in ".sh" that have c) a shebang of #!/bin
	LIST=$(find "$BASH_DIR/.." -type f -name "*.sh" -exec grep -l '#!/bin' {} \; ) 
	
	#filter out scripts that don't have meta
	echo "$LIST"
}
readonly -f getAllScripts

#description:  does the file have fluentBash meta information
#usage: echo myfile | hasScriptMeta
hasScriptMeta()	
{
	local STDIN=$(getStdIn)
	debecho hasScriptMeta stdin "$STDIN"
	
	#return false if file does not have:
	#line 2 starts with "#summary:"
	#line 3 starts with "#tags:"
	local FILEDATA=$(cat "$STDIN" | head -n 3)
	debecho hasScriptMeta filedata "$FILEDATA"

	local FILTER=$(echo "getLine 2 | ifStartsWith #summary:" | appendLine "getLine 3 | ifStartsWith #tags:" )
	
	local RESULT	
	local RV	
	RESULT=$(echo "$FILEDATA" | filter FILTER)
	RV=$?
	if [[ "$RV" == 0 ]]; then
		echo "$STDIN"
		return 0	
	fi
	
	return 1
}
readonly -f hasScriptMeta
#debugFlagOn hasScriptMeta

#description:  finds all scripts that have fluentBash meta information
#usage: getAllScriptsWithMeta
getAllScriptsWithMeta()
{
	local LIST=$(getAllScripts )
	echo "$LIST" | doEachLine hasScriptMeta
}
readonly -f getAllScriptsWithMeta
#debugFlagOn getAllScriptsWithMeta


#description:  gets a list of all files and their meta tags
#usage: getAllScriptsAndTags
getAllScriptsAndTags()
{
	local LIST=$(getAllScriptsWithMeta)
	
	#now grep all the tag lines in this list
	local TAGLIST=$(echo "$LIST" | doEachLine dump | grep '^#tags' | doEachLine getSubstring 6)

	#we probably want some join and split going on here
	echo "$LIST" | joinLists TAGLIST "  ===>  "
}
readonly -f getAllScriptsAndTags
#debugFlagOn getAllScriptsAndTags

#description:  returns which files have the provided tag
#usage:  echo myTag | whereIsTag
whereIsTag()
{
	local STDIN=$(getStdIn)
	
	getAllScriptsAndTags | grep "$STDIN"
}
readonly -f whereIsTag
#debugFlagOn whereIsTag

#description: returns all of the functions every script has
#usage: getAllScriptFunctions
getAllScriptFunctions()
{
	#find files that match the script name
	local MATCHES=$(getAllScriptsWithMeta)
	IFS=$'\n' read -d '' -r -a SCRIPTS <<< "$MATCHES"
			
	#now iterate thru the matched files
	for EACH in "${SCRIPTS[@]}"
	do
		TEXT=$(cat "$EACH")
		LEN=$(echo "$TEXT" | getLineCount)
		#split into array
		IFS=$'\n' read -d '' -r -a ARR <<< "$TEXT"
		#iterate over each line
		for ((i = 0 ; i < "$LEN" ; i++)); do
			LINE="${ARR[$i]}"
			#if the line starts with "#description:"  we start our grab
			HASMATCH=false
			echo "$LINE" | ifStartsWith "#description" && HASMATCH=true
			while [[ "$HASMATCH" == true ]]; do
				i=$((i + 1))
				LINE="${ARR[$i]}"
				echo "$LINE" | ifStartsWith "#usage" || HASMATCH=false
				
				#if we've switched HASMATCH off the first time we echo it
				if [[ "$HASMATCH" == false ]]; then
					echo "$EACH""  ===>  ""$LINE"
					echo
				fi				
			done
		done		
	done

}
readonly -f getAllScriptFunctions
#debugFlagOn getAllScriptFunctions

#usage:  echo scriptPartialName | getScriptFunctions
getScriptFunctions()
{
	local STDIN=$(getStdIn)
	
	#find files that match the script name
	local MATCHES=$(getAllScriptsWithMeta | grep "$STDIN")
	
	#now iterate thru the matched files
	for EACH in "${MATCHES[@]}"
	do
		TEXT=$(cat "$EACH")
		LEN=$(echo "$TEXT" | getLineCount)
		#split into array
		IFS=$'\n' read -d '' -r -a ARR <<< "$TEXT"
		#iterate over each line
		for ((i = 0 ; i < "$LEN" ; i++)); do
			LINE="${ARR[$i]}"
			#if the line starts with "#description:"  we start our grab
			HASMATCH=false
			echo "$LINE" | ifStartsWith "#description" && HASMATCH=true
			while [[ "$HASMATCH" == true ]]; do
				i=$((i + 1))
				LINE="${ARR[$i]}"
				echo "$LINE" | ifStartsWith "#usage" || HASMATCH=false
				
				#if we've switched HASMATCH off the first time we echo it
				if [[ "$HASMATCH" == false ]]; then
					echo "$EACH""  ===>  ""$LINE"
					echo
				fi				
			done
		done		
	done

}
readonly -f getScriptFunctions
#debugFlagOn getScriptFunctions

#description:  returns which file defines the function
#usage:  echo myFunction | whereIsFunction
whereIsFunction()
{
	local STDIN=$(getStdIn)
	getAllScriptFunctions | grep "$STDIN"
}
readonly -f whereIsFunction
#debugFlagOn whereIsFunction
 
	
	