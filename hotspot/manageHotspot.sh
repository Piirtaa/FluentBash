#!/bin/bash
#summary: manages (ie. starts or stops) a hotspot
#tags: ap, hotspot, access point, wifi, hostapd
#usage:  manageHotspot.sh start|stop wlan0 (optional:  wlan0) mySSID (optional: myhotspot) myPW (optional: derp123456) myMode (optional: g) eth0 (optional: '' ) 
#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript hotspot/hotspot.sh

WORKFILE="hotspotuow.txt"

start()
{
	#overwrite some of the hotspot vars
	INTERFACE_WLAN="${2:-'wlan0'}"
	SSID="${3:-'secretfbivan'}"
	WPAPASS="${4:-'fancy12345'}"
	HW_MODE="${5:-'g'}"
	INTERFACE_NET="$5"

	UOW=$(echo "$UOW" |  workSetVar INTERFACE_WLAN)
	UOW=$(echo "$UOW" |  workSetVar INTERFACE_NET)
	UOW=$(echo "$UOW" |  workSetVar SSID)
	UOW=$(echo "$UOW" |  workSetVar WPAPASS)
	UOW=$(echo "$UOW" |  workSetVar HW_MODE)
	
	startTrigger() { return 0 }
	UOW=$(echo "$UOW" | workSetStartTriggerStrategy startTrigger)
	
	#if we have any custom conditions to add we can do so here
	#UOW=$(echo "$UOW" | workAddCanInitStrategy canInit1)
	#UOW=$(echo "$UOW" | workAddCanStartStrategy canRun1 )
	#UOW=$(echo "$UOW" | workAddCanStopStrategy canStop1 )
	#UOW=$(echo "$UOW" | workAddCanDisposeStrategy canDispose1 )
	#UOW=$(echo "$UOW" | workSetStopTriggerStrategy stopTrigger)

	#save this uow to a file

	echo "$UOW" > "$WORKFILE"

	#start the job
	workWatch "$WORKFILE" 60 

}

stop()
{
	cat "$WORKFILE" | workStop  
}



case "$1" in
	start)
			start "${@:2}";;
	stop)
			stop;;
	*)
			args=( "start" "stop" )
			desc=( "eg. start wlan0 mySSID myPW g eth0" "eg. stop"  )
			echo -e "Usage:\tmanageHotspot.sh [argument]\n"
			for ((i=0; i < ${#args[@]}; i++))
			do
				printf "\t%-15s%-s\n" "${args[i]}" "${desc[i]}"
			done
			exit;;
esac




