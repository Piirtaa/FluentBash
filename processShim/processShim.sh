#!/bin/bash
#summary:  process Shim that manages stdin and stdout around a wrapped process. 
#tags: process interception shim 

#load loader first.  
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh
loadScript piping/strings.sh

#description:  writes a log entry for a session
#usage: echo $data | logShim name 
logShim()
{
	local NAME LOGFILE STDIN
	NAME="$1"
	if [[ -z "$NAME" ]]; then
		echo "no name provided"
		return 1
	fi
	STDIN=$(getStdIn)
	LOGFILE="$NAME"".log"
	echo "$STDIN" >> "$LOGFILE"
}

#description:  starts a Shim.  
#usage:  startShim name commandToRun 
startShim()
{
	local NAME CMD
	NAME="$1"
	if [[ -z "$NAME" ]]; then
		echo "no name provided"
		return 1
	fi
	shift
	CMD="$@"
	
	#create a named pipe for input and a file for output
	local IN_PIPE OUT_FILE
	IN_PIPE="$NAME""IN"
	OUT_FILE="$NAME""OUT"

	if [ ! -p "$IN_PIPE" ]; then
		mkfifo "$IN_PIPE"
	fi
	
	#run the command we are shimming in the background, with input from the named pipe and redirecting (by appending) stdout to the output file
	local CMD_PID
	$CMD < "$IN_PIPE" >> "$OUT_FILE" &
	CMD_PID=$!

	logShim "$NAME" < <(echo "CMD=""$CMD" )
	logShim "$NAME" < <(echo "CMD_PID=""$CMD_PID" )
	
	#keep the pipe open indefinitely
	local INPIPE_HOLD_PID	
	sleep infinity > "$IN_PIPE" &  #setup writer that never writes
	INPIPE_HOLD_PID=$!
	logShim "$NAME" < <(echo "INPIPE_HOLD_PID=""$INPIPE_HOLD_PID" )

	#create a script to send a command to the shim
	local REQUEST_FILE="callShim""$NAME"".sh"
	local REQUEST CALLLINE
	CALLLINE='callShim '"$NAME"' $@'
	REQUEST=$(cat <<EOF
#!/bin/bash
#load loader first.  
. $BASH_DIR/../core/core.sh #first thing we load is the script loader
loadScript processShim/processShim.sh

$CALLLINE
EOF
)
	echo "$REQUEST" > "$REQUEST_FILE"
	chmod +x "$REQUEST_FILE"
	logShim "$NAME" < <(echo "REQUEST_FILE=""$REQUEST_FILE" )

	#create a script to dispose 
	local DISPOSE_FILE="dispose""$NAME"".sh"
	local DISPOSE
	DISPOSE=$(cat <<EOF
#!/bin/bash	
kill "$CMD_PID"
kill "$INPIPE_HOLD_PID"
rm "$IN_PIPE"
rm "$OUT_FILE"
rm "$NAME".log
rm "$DISPOSE_FILE"
rm "$REQUEST_FILE"

EOF
)
	echo "$DISPOSE" > "$DISPOSE_FILE"
	chmod +x "$DISPOSE_FILE"
	logShim "$NAME" < <(echo "DISPOSE_FILE=""$DISPOSE_FILE" )
	
	
}
readonly -f startShim

#description: sends commands to the Shim.  
#usage:  echo 'adafadsf' | callShim name isCompleteTest testArg1 testArg2..
#if the "silent" argument is provided the Shim will not return a response 
callShim()
{
	local NAME
	NAME="$1"
	if [[ -z "$NAME" ]]; then
		echo "no name provided"
		return 1
	fi
	shift
	
	local IN_PIPE OUT_FILE
	IN_PIPE="$NAME""IN"
	OUT_FILE="$NAME""OUT"
	
	if [ ! -p "$IN_PIPE" ]; then
		echo "invalid in pipe"
		return 1
	fi	
	
	local STDIN OUTPUT
	STDIN=$(getStdIn)

	logShim "$NAME" < <(echo "INPUT=""$STDIN" )

	#make the call
	echo "$STDIN" > "$IN_PIPE"
	
	#get the response
	local OUTPUT 
	
	while true 
	do
		OUTPUT=$(cat "$OUT_FILE")
		
		if [[ -z "$OUTPUT" ]]; then
			continue;
		fi
		
		#if there is no completion test consider it complete
		if [[ -z "$1" ]]; then
			break
		else
			#isComplete?
			makeCall "$@" < <(echo "$OUTPUT") > /dev/null && break
		fi
	done 
	
	#clean up the file
	truncate -s 0 "$OUT_FILE"
	logShim "$NAME" < <(echo "OUTPUT=""$OUTPUT" )

	echo "$OUTPUT"
	
	return 0	

}
readonly -f callShim


#description:  stops a mediated process
#usage:  stopShim name
stopShim()
{
	local NAME
	NAME="$1"
	if [[ -z "$NAME" ]]; then
		echo "no name provided"
		return 1
	fi

	local DISPOSE_FILE="dispose""$NAME"".sh"
	./"$DISPOSE_FILE"
}
readonly -f stopShim



