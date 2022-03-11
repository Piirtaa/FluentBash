#!/bin/bash
#summary: a captive portal
#tags: web server

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/trigger.sh


PAGE=index.html
cat <<EOF | tee "$PAGE" > /dev/null 2>&1
<html>
<head></head>
<body>
yo
</body>
</html>
EOF

#debugFlagOn kvgSet

before()
{
	debecho before wiring oneshot $1
	#NOTE:  the redirection of stdout MUST happen or this function will hang in the trigger mechanism!!
	../http/oneshot.sh "$PAGE" "$1" >/dev/null && touch "$1" &
	return 0
}

waitFor()
{
	if [[ -f "$1" ]]; then
		debecho waitFor $1 triggered		
		return 0
	else
		debecho waitFor $1 not triggered	
		return 1
	fi 
}

debugFlagOn before
debugFlagOn waitFor

#server logic
createTrigger knockknock waitFor 8080 | doBeforeTrigger before 8080  > /dev/null
createTrigger whoisthere waitFor 8081 | doBeforeTrigger before 8081  > /dev/null
createTrigger daveman waitFor 8082 | doBeforeTrigger before 8082  > /dev/null
createTrigger davesnothereman waitFor 8083 | doBeforeTrigger before 8083  > /dev/null
chainTriggers knockknock whoisthere 1
chainTriggers whoisthere daveman 1
chainTriggers daveman davesnothereman 1

activateTrigger knockknock 1 > /dev/null 





