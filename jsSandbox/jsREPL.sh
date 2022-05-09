#!/bin/bash
#summary:  this script wraps sandbox_spidermonkey.js repl functionality using processShim 
#tags: javascript sandbox spidermonkey engine processShim shim js repl

#load dependencies.  
loadScript jsWrapper/jsWrapper.sh

#the command switches
STDIN=$(getStdIn)

case "$1" in
	start)
			initREPL "$2"
			;;
	startLE)
			initLEREPL "$2"
			;;
	stop)
			disposeREPL "$2"
			;;
	getHistory)
			getREPLHistory "$2"
			;;
	run)
			callREPL "$2" < <(echo "$STDIN")
			;;
	runSilent)
			silentCall "$2" < <(echo "$STDIN")
			;;
	quit)
			exitCall "$2"
			;;
	echo)
			echoCall "$2" < <(echo "$STDIN")
			;;
	*)
			args=( "start" "startLE" "stop" "getHistory"  "run"  "runSilent"  "quit"  "echo" )
			desc=( "eg. start myInstance" "eg. startLE myInstance" "eg. getHistory myInstance" "eg. run myInstance < <(echo 'var c=1;')" "eg. runSilent myInstance < <(echo 'var c=1;')" "eg. quit myInstance" "eg. echo myInstance < <(echo hello)" )
			echo -e "Usage:\tjsREPL.sh [argument]\n"
			for ((i=0; i < ${#args[@]}; i++))
			do
				printf "\t%-15s%-s\n" "${args[i]}" "${desc[i]}"
			done
			exit
			;;
esac

