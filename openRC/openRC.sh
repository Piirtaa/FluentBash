#!/bin/bash
#summary:  openrc functions
#tags: openrc, system v, init

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh

#description:  disables an open rc service, also allows for masking 
#usage:  disableOpenRCService myServiceName runLevel maskFlag
#usage:											^^eg.  NetworkManager
#usage:														^^eg. default (this is the default)
#usage:															  		^^providing maskFlag this will ensure it cannot start
disableOpenRCService()
{
	local SERVICE RUNLEVEL MASKFLAG DUMP
	# Check if user is root
	if [[ ! $(whoami) = "root" ]] ; then
		echo "error: must be root" 
		return 1
	fi
	
	SERVICE="$1"
	RUNLEVEL="${2:-default}"
	MASKFLAG="$3" #just pass anything here and it will right a "non-existent" dependency to the service configuration to disable it
	
	debecho disableOpenRCService service "$SERVICE"
	debecho disableOpenRCService runlevel "$RUNLEVEL"
	debecho disableOpenRCService disable "$MASKFLAG"
	
	DUMP=$(rc-service "$SERVICE" stop)
	debecho disableOpenRCService stopped service "$DUMP"
	
	if [[ ! -z "$MASKFLAG" ]] ; then
		#the following line is explained here https://fitzcarraldoblog.wordpress.com/tag/networkmanager/ 
		echo 'rc_need="non-existent_service"' >> /etc/conf.d/NetworkManager
		debecho disableOpenRCService masked service 
	fi
	
	DUMP=$(rc-update del "$SERVICE" "$RUNLEVEL")
	debecho disableOpenRCService removed service "$DUMP"
	
	return 0
}
readonly -f disableOpenRCService
#debugFlagOn disableOpenRCService

#description:  enables an open rc service.  removes any masking
#usage:  enableOpenRCService myServiceName runLevel 
#usage:											^^eg.  NetworkManager
#usage:														^^eg. default (this is the default)
enableOpenRCService()
{
	local SERVICE RUNLEVEL DUMP
	# Check if user is root
	if [[ ! $(whoami) = "root" ]] ; then
		echo "error: must be root" 
		return 1
	fi
	
	SERVICE="$1"
	RUNLEVEL="${2:-default}"
	
	debecho enableOpenRCService service "$SERVICE"
	debecho enableOpenRCService runlevel "$RUNLEVEL"
	
	#regardless of masking we remove it
	DUMP=$(sed -i '/rc_need="non-existent_service"/d' /etc/conf.d/"$SERVICE")
	debecho enableOpenRCService removed any masking "$DUMP"
	
	DUMP=$(rc-service "$SERVICE" restart)
	debecho enableOpenRCService started service "$DUMP"
	
	DUMP=$(rc-update add "$SERVICE" "$RUNLEVEL") # Only needed if I earlier deleted the service from the default runlevel.
	debecho enableOpenRCService added service "$DUMP"
	
	return 0
}
readonly -f enableOpenRCService
#debugFlagOn enableOpenRCService

#description:  gets run state of an open rc service.
#usage:  getOpenRCServiceStatus myServiceName  
getOpenRCServiceStatus()
{
	local SERVICE STATUS
	
	SERVICE="$1"

	STATUS=$(rc-status -s | grep "$SERVICE" | getAfter "[" | getBefore "]" | xargs)	
	
	if [[ -z "$STATUS" ]]; then
		return 1
	else
		echo "$STATUS"
		return 0
	fi
}
readonly -f getOpenRCServiceStatus
#debugFlagOn getOpenRCServiceStatus

#description:  gets run level of an open rc service.
#usage:  getOpenRCServiceRunLevel myServiceName  
getOpenRCServiceRunLevel()
{
	local SERVICE STATUS
	
	SERVICE="$1"

	STATUS=$(rc-update show -v | grep "$SERVICE" | getAfter "|" | xargs)	
	
	if [[ -z "$STATUS" ]]; then
		return 1
	else
		echo "$STATUS"
		return 0
	fi
}
readonly -f getOpenRCServiceRunLevel
#debugFlagOn getOpenRCServiceRunLevel
