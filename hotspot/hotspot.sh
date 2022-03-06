#!/bin/bash
#summary: access point hotspot
#tags: ap, hotspot, access point, wifi, hostapd

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/uow.sh

#construct a  unit of work
UOW=$(workCreate)

#register variables with the uow
USER=$(who | grep $(echo "$DISPLAY" | cut -d '.' -f 1) | cut -d ' ' -f 1 | tail -1)
UOW_LOGFILE="uow.log"
HOSTAPD_PIDFILE="hotspot.pid"
HOSTAPD_CONFIGFILE="/etc/hotspot.conf"
DNSMASQ_CONFIGFILE="/etc/dnsmasq.conf"
INTERFACE_WLAN="wlan0"
INTERFACE_NET="" 	#only set this if we want to route wifi clients to the internet
						#we can figure what this is by the command:  route | grep -iw "default" | awk '{print $NF}'
SSID="myhotspot"
WPAPASS="qwerty0987"
HW_MODE=g #can be (b/g/n)	

UOW=$(echo "$UOW" |  workSetVar USER)
UOW=$(echo "$UOW" |  workSetVar UOW_LOGFILE)
UOW=$(echo "$UOW" |  workSetVar HOSTAPD_PIDFILE)
UOW=$(echo "$UOW" |  workSetVar HOSTAPD_CONFIGFILE)
UOW=$(echo "$UOW" |  workSetVar DNSMASQ_CONFIGFILE)
UOW=$(echo "$UOW" |  workSetVar INTERFACE_WLAN)
UOW=$(echo "$UOW" |  workSetVar INTERFACE_NET)
UOW=$(echo "$UOW" |  workSetVar SSID)
UOW=$(echo "$UOW" |  workSetVar WPAPASS)
UOW=$(echo "$UOW" |  workSetVar HW_MODE)

#description:  writes to the uow log
#usage:  echo msg | uowLog
uowLog()
{
	local STDIN=$(getStdIn)
	echo "$STDIN" >> "$UOW_LOGFILE"
}
readonly -f uowLog

canInitHotspot() 
{
	if [[ -e "$UOW_LOGFILE" ]] ; then
		rm "$UOW_LOGFILE"
	fi
	touch "$UOW_LOGFILE"
	
	# Check if user is root
	if [[ ! $(whoami) = "root" ]] ; then
		echo "error: must be root" | uowLog
		exit 1
	fi

	# Check if the wireless card supports Access Point mode. This script won't work if it doesn't support it
	if [[ ! $(iw list 2>&1 | grep -A6 "Supported interface modes" | grep AP$) ]] ; then
		echo "error: AP mode not supported" | uowLog
		exit 1
	fi

	# Check if Wireless is disabled
	if [[ $(iwconfig "$INTERFACE_WLAN" 2>&1 | grep "Tx-Power=off") ]] ; then
		echo "error: wifi is disabled" | uowLog
		exit 1
	fi
	
	# Check if Wireless is enabled, but connected to a network
	if [[ ! $(iwconfig "$INTERFACE_WLAN" 2>&1 | grep "ESSID:off/any") && $(iwconfig "$INTERFACE_WLAN" 2>&1 | grep "ESSID:") ]] ; then
		echo "error: wifi must be disconnected" | uowLog
		exit 1
	fi
	
	return 0	
}
readonly -f canInitHotspot
#debugFlagOn canInitHotspot

initHotspotFiles() 
{
	cat <<EOF | tee "$HOSTAPD_CONFIGFILE" > /dev/null 2>&1
	# WiFi Hotspot
	interface=$INTERFACE_WLAN
	driver=nl80211
	#Access Point
	ssid=$SSID
	hw_mode=$HW_MODE
	# WiFi Channel:
	channel=1
	macaddr_acl=0
	auth_algs=1
	ignore_broadcast_ssid=0
	wpa=3
	wpa_passphrase=$WPAPASS
	wpa_key_mgmt=WPA-PSK
	wpa_pairwise=TKIP
	rsn_pairwise=CCMP
EOF

	cat <<EOF | tee "$DNSMASQ_CONFIGFILE" > /dev/null 2>&1
	# Bind to only one interface
	bind-interfaces
	# Choose interface for binding
	interface=$INTERFACE_WLAN
	# Specify range of IP addresses for DHCP leasses
	dhcp-range=192.168.150.2,192.168.150.12,12h
	#INTERFACE_NET=$INTERFACE_NET
EOF

	if [[ -e "$HOSTAPD_PIDFILE" ]] ; then
		rm "$HOSTAPD_PIDFILE"
	fi
	touch "$HOSTAPD_PIDFILE"

}
readonly -f initHotspotFiles
debugFlagOn initHotspotFiles

UOW=$(echo "$UOW" | workAddCanInitStrategy canInitHotspot | workSetInitStrategy initHotspotFiles )

startHotspot() 
{
	#not on gentoo	
		#service hostapd stop 2>&1 | uowLog
		#service dnsmasq stop 2>&1 | uowLog
		#update-rc.d hostapd disable 2>&1 | uowLog
		#update-rc.d dnsmasq disable 2>&1 | uowLog
	#on gentoo	
	rc-service hostapd stop 2>&1 | uowLog
	rc-service dnsmasq stop 2>&1 | uowLog
		
	#set ip of ap interface to subnet of what is in dnsmasq
	ifconfig "$INTERFACE_WLAN" 192.168.150.1 2>&1 | uowLog
	rc-service dnsmasq restart 2>&1 | uowLog

	#if we have internet, wire up forwarding and nat
	if [[ ! -z "$INTERFACE_NET" ]] ; then
		# Enable routing
		sysctl net.ipv4.ip_forward=1 2>&1 | uowLog
		# Enable NAT
		iptables -t nat -A POSTROUTING -o "$INTERFACE_NET" -j MASQUERADE 2>&1 | uowLog
	fi
	
	hostapd -B "$HOSTAPD_CONFIGFILE" -P "$HOSTAPD_PIDFILE" 2>&1 | uowLog
}
readonly -f startHotspot
#debugFlagOn startHotspot

UOW=$(echo "$UOW" | workSetStartStrategy startHotspot )

stopHotspot() 
{
	#log the status before we shut stuff down
	
	#if there's a valid pidfile, read the pid and kill
	#if [[ -f "$HOSTAPD_PIDFILE" ]] ; then
	#	local PID=$(cat "$HOSTAPD_PIDFILE")
	#	rm -f "$HOSTAPD_PIDFILE"
	#	[[ $(grep -s "ap-hotspot" "/proc/$PID/cmdline") ]] && kill -9 "$PID"
	#fi
	
	if [[ ! -z "$INTERFACE_NET" ]] ; then
		# Disable NAT
		iptables -D POSTROUTING -t nat -o "$INTERFACE_NET" -j MASQUERADE 2>&1 | uowLog
		# Disable routing
		sysctl net.ipv4.ip_forward=0 2>&1 | uowLog
	fi
	
	# Set up the services
	rc-service hostapd stop 2>&1 | uowLog
	rc-service dnsmasq stop 2>&1 | uowLog
	killall hostapd | uowLog
	
	# Restart WiFi and disable newly created mon.WLAN network
	ifconfig "mon.$INTERFACE_WLAN" down | uowLog
	ifconfig "$INTERFACE_WLAN" down | uowLog
	ifconfig "$INTERFACE_WLAN" up | uowLog
}
readonly -f stopHotspot
UOW=$(echo "$UOW" | workSetStopStrategy stopHotspot )

disposeHotspot()
{
	#remove the files
	rm -f "$HOSTAPD_PIDFILE"
	rm -f "$HOSTAPD_CONFIGFILE"
	rm -f "$DNSMASQ_CONFIGFILE"
	#rm -f "$UOW_LOGFILE"
}
readonly -f disposeHotspot
UOW=$(echo "$UOW" | workSetDisposeStrategy disposeHotspot )

show_notify() {
	sudo -u "$user" notify-send -h int:transient:1 -i "network-wireless" "$@"
}

pollHotspot()
{
	# Monitor logfile for connected devices
	lines_con="0"
	lines_dis="0"
	while [[ -f "$UOW_LOGFILE" ]]
	do
		if [[ "$lines_con" < $(grep -c "AP-STA-CONNECTED" "$UOW_LOGFILE") ]]
		then
			show_notify "New device connected to Hotspot"
			(( lines_con++ ))
		elif [[ "$lines_dis" < $(grep -c "AP-STA-DISCONNECTED" "$UOW_LOGFILE") ]]
		then
			show_notify "Device disconnected from Hotspot"
			(( lines_dis++ ))
		fi
		sleep 5
	done
}
readonly -f pollHotspot
UOW=$(echo "$UOW" | workSetPollingStrategy pollHotspot )

echo "$UOW" > dump.txt



