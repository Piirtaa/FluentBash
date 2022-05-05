#!/bin/bash
#summary:  this script wraps sandbox_spidermonkey.js standalone js execution
#tags: javascript sandbox spidermonkey engine js standalone 

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh

SANDBOX=$(getScriptPath jsSandbox/sandbox_spidermonkey.js) 

case "$1" in
	--help)
			args=( "" "piped")
			desc=( "eg. '()=>{return 1;}'" "eg. < <(echo '()=>{return 1;}'" )
			echo -e "Usage:\tjsRUN.sh [argument]\n"
			for ((i=0; i < ${#args[@]}; i++))
			do
				printf "\t%-15s%-s\n" "${args[i]}" "${desc[i]}"
			done
			exit
			;;
	
	piped)
			STDIN=$(getStdIn)
			"$SANDBOX piped" "$@:2" < <(echo "$STDIN")
			;;
	*)
			STDIN=$(getStdIn)
			"$SANDBOX" "$@" < <(echo "$STDIN")
			;;
	
esac

