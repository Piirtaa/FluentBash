#!/bin/bash
#summary: a captive portal
#tags: web server

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/trigger.sh

#debugFlagOn kvgSet

#client logic
attempt()
{
	local RV
	debecho attempt "$1"
	curl localhost:"$1" > /dev/null
	RV=$?
	
	if [[ "$RV" == 0 ]] ; then
		debecho attempt success	
	else
		debecho attempt fail
	fi
}
after()
{
	debecho after "$1"client 
	touch "$1"client
}
debugFlagOn attempt
debugFlagOn after

createTrigger knockknockClient attempt 8080 | doAfterTrigger after 8080 > /dev/null
createTrigger whoisthereClient attempt 8081 | doAfterTrigger after 8081 > /dev/null
createTrigger davemanClient  attempt 8082 | doAfterTrigger after 8082 > /dev/null
createTrigger davesnotheremanClient attempt 8083 | doAfterTrigger after 8082 > /dev/null
chainTriggers knockknockClient whoisthereClient 1
chainTriggers whoisthereClient davemanClient 1
chainTriggers davemanClient davesnotheremanClient 1

activateTrigger knockknockClient 1

#waitForKeyPress

rm 8080* 8081* 8082* 8083* knockknock* whoisthere* daveman* davesnothereman* index.html




