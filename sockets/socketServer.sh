#!/bin/bash
#summary:  a bunch of different socket server reference implementations
#tags: 

#load loader first.  
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh

#description:  starts a netcat server which delegates its processing to a handler function
#usage:  startNCServer 	port quitCmd handlerFn arg arg arg
#defaults:				8080 quit
startNCServer()
{
	local QUITCMD PORT HANDLERFN CMD RES
	PORT=${1:-8080} 
	shift
	QUITCMD=${1:-quit}
	shift
	HANDLERFN="$@"
	
	coproc nc -l localhost "$PORT"
	
	while read -r CMD; do
		case "$CMD" in
		"$QUITCMD") break ;;
		*) 
			RES=$("$HANDLERFN" "$CMD")
			echo "$RES"			
		esac
	done <&"${COPROC[0]}" >&"${COPROC[1]}"

	kill "$COPROC_PID"
}
readonly -f startNCServer

#description:  sends a line to a nc server
#usage:  sendNCClient addr port line
sendNCClient()
{
	local ADDR PORT CMD RES
	ADDR=${1:-localhost}
	PORT=${2:-8080} 
	shift; shift;
	CMD="$@"
	echo command is "$CMD"
	RES=$(nc "$ADDR" "$PORT" < <(echo "$CMD"))
}
readonly -f sendNCClient
