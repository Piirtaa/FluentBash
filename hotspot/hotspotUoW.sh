#!/bin/bash
#summary: creates access point hotspot unitOfWork
#tags: ap, hotspot, access point, wifi, hostapd

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/HS_UOW.sh
loadScript openRC/openRC.sh 

#construct a  unit of work
HS_UOW=$(workCreate)

#register variables with the HS_UOW
USER=$(who | grep $(echo "$DISPLAY" | cut -d '.' -f 1) | cut -d ' ' -f 1 | tail -1)
HS_UOW_LOGFILE="HS_UOW.log"
HOSTAPD_PIDFILE="hotspot.pid"
HOSTAPD_CONFIGFILE="hotspot.conf"
DNSMASQ_CONFIGFILE="dnsmasq.conf"
INTERFACE_WLAN="wlan1"
INTERFACE_NET="" 	#only set this if we want to route wifi clients to the internet
						#we can figure what this is by the command:  route | grep -iw "default" | awk '{print $NF}'
SSID="myhotspot"
WPAPASS="qwerty0987"
HW_MODE=g #can be (b/g/n)	

HS_UOW=$(echo "$HS_UOW" |  workSetVar USER)
HS_UOW=$(echo "$HS_UOW" |  workSetVar HS_UOW_LOGFILE)
HS_UOW=$(echo "$HS_UOW" |  workSetVar HOSTAPD_PIDFILE)
HS_UOW=$(echo "$HS_UOW" |  workSetVar HOSTAPD_CONFIGFILE)
HS_UOW=$(echo "$HS_UOW" |  workSetVar DNSMASQ_CONFIGFILE)
HS_UOW=$(echo "$HS_UOW" |  workSetVar INTERFACE_WLAN)
HS_UOW=$(echo "$HS_UOW" |  workSetVar INTERFACE_NET)
HS_UOW=$(echo "$HS_UOW" |  workSetVar SSID)
HS_UOW=$(echo "$HS_UOW" |  workSetVar WPAPASS)
HS_UOW=$(echo "$HS_UOW" |  workSetVar HW_MODE)

#description:  writes to the HS_UOW log
#usage:  echo msg | HS_UOWLog
HS_UOWLog()
{
	local STDIN=$(getStdIn)
	echo "$STDIN" >> "$HS_UOW_LOGFILE"
}
readonly -f HS_UOWLog

canInitHotspot() 
{
	if [[ -e "$HS_UOW_LOGFILE" ]] ; then
		rm "$HS_UOW_LOGFILE"
	fi
	touch "$HS_UOW_LOGFILE"
	
	# Check if user is root
	if [[ ! $(whoami) = "root" ]] ; then
		echo "error: must be root" | HS_UOWLog
		exit 1
	fi

	return 0	
}
readonly -f canInitHotspot
debugFlagOn canInitHotspot

initHotspot() 
{
	
	#shutdown the ap interface
	debecho initHotspot shutting down interface
	sudo ifconfig "$INTERFACE_WLAN" down | HS_UOWLog
	
	#shutdown services
	debecho initHotspot shutting down NetworkManager, dnsmasq, hostapd
	disableOpenRCService NetworkManager default mask | HS_UOWLog
	disableOpenRCService dnsmasq default mask | HS_UOWLog
	disableOpenRCService hostapd default mask | HS_UOWLog
	killAll dnsmasq | HS_UOWLog
	killAll hostapd | HS_UOWLog
	
	debecho initHotspot airmon-ng check kill
	sudo airmon-ng check kill | HS_UOWLog
	#killall dhclient | HS_UOWLog
	#killall wpa_supplicant | HS_UOWLog
	
	debecho initHotspot starting interface
	sudo ifconfig "$INTERFACE_WLAN" up | HS_UOWLog

	debecho initHotspot writing "$HOSTAPD_CONFIGFILE"

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

	debecho initHotspot writing "$DNSMASQ_CONFIGFILE"
	
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
readonly -f initHotspot
debugFlagOn initHotspot
HS_UOW=$(echo "$HS_UOW" | workAddCanInitStrategy canInitHotspot | workSetInitStrategy initHotspot )

startHotspot() 
{
	#set ip of ap interface to subnet of what is in dnsmasq
	debecho startHotspot assign ip to "$INTERFACE_WLAN"
	ifconfig "$INTERFACE_WLAN" 192.168.150.1 2>&1 | HS_UOWLog

	debecho startHotspot starting dnsmasq
	dnsmasq -C "$DNSMASQ_CONFIGFILE" -d 2>&1 | HS_UOWLog &
	#https://linux.die.net/man/8/dnsmasq
	#-d, --no-daemon
   # Debug mode: don't fork to the background, don't write a pid file, don't change user id, generate a complete cache dump on receipt on SIGUSR1, log to stderr as well as syslog, don't fork new processes to handle TCP queries. 		
	#-h, --no-hosts
   # Don't read the hostnames in /etc/hosts. 
	#-H, --addn-hosts=<file>
   # Additional hosts file. Read the specified file as well as /etc/hosts. If -h is given, read only the specified file. This option may be repeated for more than one additional hosts file. If a directory is given, then read all the files contained in that directory. 	
	#-x, --pid-file=<path>
   # Specify an alternate path for dnsmasq to record its process-id in. Normally /var/run/dnsmasq.pid. 
	
	
	#if we have internet, wire up forwarding and nat
	if [[ ! -z "$INTERFACE_NET" ]] ; then
		debecho startHotspot wiring routing to internet
		# Enable routing
		sysctl net.ipv4.ip_forward=1 2>&1 | HS_UOWLog
		# Enable NAT
		iptables -t nat -A POSTROUTING -o "$INTERFACE_NET" -j MASQUERADE 2>&1 | HS_UOWLog
		#iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
		#iptables -A FORWARD -i $INTERFACE_WLAN -o $INTERFACE_NET -j ACCEPT
	fi
	
	debecho startHotspot starting hostapd
	hostapd "$HOSTAPD_CONFIGFILE" -B -dd -t -K -P "$HOSTAPD_PIDFILE" 2>&1 | HS_UOWLog &
	#https://nxmnpg.lemoda.net/8/hostapd
	#-d 	Enable debugging messages. If this option is supplied twice, more verbose messages are displayed.
	#-h 	Show help text.
	#-t 	Include timestamps in debugging output.
	#-v 	Display version information on the terminal and exit.
	#-B 	Detach from the controlling terminal and run as a daemon process in the background.
	#-K 	Include key information in debugging output.
	#-P 	pidfile 	Store PID in pidfile. 
}
readonly -f startHotspot
#debugFlagOn startHotspot
HS_UOW=$(echo "$HS_UOW" | workSetStartStrategy startHotspot )

stopHotspot() 
{
	#log the status before we shut stuff down
	
	#if there's a valid pidfile, read the pid and kill
	if [[ -f "$HOSTAPD_PIDFILE" ]] ; then
		local PID=$(cat "$HOSTAPD_PIDFILE")
		rm -f "$HOSTAPD_PIDFILE"
		[[ $(grep -s "hotspot.sh" "/proc/$PID/cmdline") ]] && kill -9 "$PID"
	fi
	
	if [[ ! -z "$INTERFACE_NET" ]] ; then
		# Disable NAT
		iptables -D POSTROUTING -t nat -o "$INTERFACE_NET" -j MASQUERADE 2>&1 | HS_UOWLog
		# Disable routing
		sysctl net.ipv4.ip_forward=0 2>&1 | HS_UOWLog
	fi
	
	# Set up the services
	debecho stopHotspot shutting down dnsmasq, hostapd
	killAll dnsmasq | HS_UOWLog
	killAll hostapd | HS_UOWLog
	enableOpenRCService NetworkManager default mask | HS_UOWLog
	
	# Restart WiFi and disable newly created mon.WLAN network
	ifconfig "mon.$INTERFACE_WLAN" down | HS_UOWLog
	ifconfig "$INTERFACE_WLAN" down | HS_UOWLog
	ifconfig "$INTERFACE_WLAN" up | HS_UOWLog
}
readonly -f stopHotspot
HS_UOW=$(echo "$HS_UOW" | workSetStopStrategy stopHotspot )

disposeHotspot()
{
	#remove the files
	rm -f "$HOSTAPD_CONFIGFILE"
	rm -f "$DNSMASQ_CONFIGFILE"
	#rm -f "$HS_UOW_LOGFILE"

}
readonly -f disposeHotspot
HS_UOW=$(echo "$HS_UOW" | workSetDisposeStrategy disposeHotspot )

show_notify() {
	sudo -u "$user" notify-send -h int:transient:1 -i "network-wireless" "$@"
}

pollHotspot()
{
	# Monitor logfile for connected devices
	lines_con="0"
	lines_dis="0"
	while [[ -f "$HS_UOW_LOGFILE" ]]
	do
		if [[ "$lines_con" < $(grep -c "AP-STA-CONNECTED" "$HS_UOW_LOGFILE") ]]
		then
			show_notify "New device connected to Hotspot"
			(( lines_con++ ))
		elif [[ "$lines_dis" < $(grep -c "AP-STA-DISCONNECTED" "$HS_UOW_LOGFILE") ]]
		then
			show_notify "Device disconnected from Hotspot"
			(( lines_dis++ ))
		fi
		sleep 5
	done
}
readonly -f pollHotspot
HS_UOW=$(echo "$HS_UOW" | workSetPollingStrategy pollHotspot )

startTrigger()
{
	return 0
}
HS_UOW=$(echo "$HS_UOW" | workSetStartTriggerStrategy startTrigger )


