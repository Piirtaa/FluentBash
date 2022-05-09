#!/bin/bash
#summary:  this script wraps sandbox_spidermonkey.js repl functionality using processShim 
#tags: javascript sandbox spidermonkey engine processShim shim js repl

#load dependencies.  
loadScript processShim/processShim.sh
loadScript encoding/lengthEncoder.sh

SANDBOX=$(getScriptPath jsSandbox/sandbox_spidermonkey.js) 

#description: initializes a js sandbox repl
#usage: initREPL myInstance
initREPL()
{
	startShim "$1" "$SANDBOX" repl
}
readonly -f initREPL

#description: initializes a js sandbox repl that returns length-encoded messages
#usage: initLEREPL myInstance
initLEREPL()
{
	startShim "$1" "$SANDBOX" repl le 
}
readonly -f initLEREPL

#description: determines whether the provided instance name is a length-encoded instance
#usage: isLEREPL myInstance
isLEREPL()
{
	getREPLHistory "$1" | getLine 1 | ifEndsWith " le" > /dev/null
}
readonly -f isLEREPL

#description: disposes js sandbox repl
#usage: disposeREPL myInstance
disposeREPL()
{
	stopShim "$1"
}
readonly -f disposeREPL

#description: calls the repl
#usage: echo $cmd | callREPL myInstance
callREPL()
{
	local STDIN
	STDIN=$(getStdIn)
	
	#if the repl is length encoded we have to provide an "iscomplete" test to make sure the response is completely length-encoded
	if isLEREPL "$1" ; then
	
		#this line does the same thing as the one below it.  the js repl can handle both le and non-le inputs
		#echo "$STDIN" | le_encode | callShim "$1" le_isValid | le_getValue
		
		echo "$STDIN" | callShim "$1" le_isValid | le_getValue
	
	else
		callShim "$1" < <(echo "$STDIN")
	fi 
}
readonly -f callREPL

#description: gets the repl command history (requests and responses)
#usage: getREPLHistory myInstance
getREPLHistory()
{
	getShimLog "$1"
}
readonly -f getREPLHistory

#SPECIAL CALLS

#description:  tells the REPL to shutdown
#usage: exitCall myInstance
exitCall()
{
	callREPL "$1" < <(echo "_exit_")
}
readonly -f exitCall

#description:  invokes the echo function of the REPL (useful for implementing an "acknowledged handshake" messaging protocol)
#usage: echo $cmd | echoCall myInstance
echoCall()
{
	local STDIN
	STDIN=$(getStdIn)
	callREPL "$1" < <(echo "_echo_""$STDIN")
}
readonly -f echoCall

#description:  makes a silent call to the REPL (ie. telling it not to respond), and does not listen for a response
#usage: echo $cmd | silentCall myInstance
silentCall()
{
	local STDIN
	STDIN=$(getStdIn)
	
	callShimWithoutRead "$1" < <(echo "_silent_""$STDIN")
}
readonly -f silentCall
