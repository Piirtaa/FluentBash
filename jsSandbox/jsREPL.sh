#!/bin/bash
#summary:  this script wraps sandbox_spidermonkey.js repl functionality using processShim 
#tags: javascript sandbox spidermonkey engine processShim shim js repl

#load dependencies.  
loadScript processShim/processShim.sh
SANDBOX=$(getScriptPath jsSandbox/sandbox_spidermonkey.js) 

#the command switches
STDIN=$(getStdIn)

case "$1" in
	start)
			startShim "$2" repl
			;;
	startLE)
			startShim "$2" repl le
			;;
	stop)
			stopShim "$2"
			;;
	getHistory)
			cat "$2".log
			;;
	run)
			callShim "$2" < <(echo "$STDIN")
			;;
	runSilent)
			callShim "$2" < <(echo "_silent_""$STDIN") > /dev/null
			;;
	quit)
			callShim "$2" < <(echo "_exit_")
			;;
	echo)
			callShim "$2" < <(echo "_echo_""$STDIN")
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

