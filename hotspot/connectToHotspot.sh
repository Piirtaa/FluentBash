#!/bin/bash
#summary: connect to access point hotspot
#tags: ap, hotspot, access point, wifi, hostapd, wpa supplicant

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

INTERFACE_WLAN="${1:-wlan0}"
SSID="${2:-secretfbivan}"
WPAPASS="${3:-fancy12345}"

scanAP()
{
	local APS
	APS=$(sudo iwlist "$INTERFACE_WLAN" scan | grep ESSID )
	debecho scanAP APS "$APS"
}
readonly -f scanAP
debugFlagOn scanAP

connectToAP()
{
	#setup the exit hook
	trap cleanup EXIT

	#take the interface down and up
	ifconfig "$INTERFACE_WLAN" down
	ifconfig "$INTERFACE_WLAN" up 

	local DUMP
	FILE="wpa_supplicant_""$INTERFACE_WLAN"".conf"
	wpa_passphrase "$SSID" "$WPAPASS" | sudo tee "$FILE"
	#wpa_supplicant -B -c "$FILE" -i "$INTERFACE_WLAN"
	#wpa_supplicant -Dnl80211 -i"$INTERFACE_WLAN" -C/var/run/wpa_supplicant/ -c"$FILE" -dd
	wpa_supplicant -Dnl80211 -i"$INTERFACE_WLAN" -C/var/run/wpa_supplicant/ -c"$FILE" &
	
	sleep 5
	DUMP=$(sudo dhclient "$INTERFACE_WLAN")
	debecho connectToAP "$DUMP"
	DUMP=$(ifconfig "$INTERFACE_WLAN")
	debecho connectToAP "$DUMP"
}
readonly -f connectToAP
debugFlagOn connectToAP

cleanup()
{
	killall dhclient
	killall wpa_supplicant
	rm "$FILE"
}

scanAP
connectToAP
