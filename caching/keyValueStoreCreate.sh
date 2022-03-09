#!/bin/bash
#usage:  
#	keyValueStoreCreate.sh

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh

#configuration of this subsystem
loadScript caching/keyValueStoreConfig.sh


#builds the inmem file system 
buildStore()
{
	#test if we have enough memory
	RAM=$(cat /proc/meminfo | grep MemAvailable | tr -dc '0-9')
	
	if [ "$SIZE" -gt "$RAM" ]
	then
		echo "NOT ENOUGH RAM!"
		echo Avail"  |" $(( $RAM / 1000 ))MB
	   echo Used"   |" $(( $SIZE / 1000 ))MB
		echo Needed" |" $(( $(($SIZE - $RAM)) / 1000 ))MB
		exit 1
	fi

	#unmount it if it's mounted
	mount | grep "$DEVICENAME" > /dev/null && sudo umount "$BASEFS"
	
	#make the fs
	sudo mkdir -p "$BASEFS"
	
	#give everyone perms
	sudo chmod 777 "$BASEFS"
	
	sudo mount -t tmpfs -o size="$SIZE"K "$DEVICENAME" "$BASEFS"

	#have to do this after mounting
	sudo mkdir -p "$DATAFS"
	sudo chmod 777 "$DATAFS"

	#write the index files	
	[ ! -e "$INDEX_FILE" ] && touch "$INDEX_FILE" ;
	[ ! -e "$COUNTER_FILE" ] && echo 0 > "$COUNTER_FILE" ;
	#[ ! -e "$COUNTER_LOCK" ] && touch "$COUNTER_LOCK" ;

	
	
}
readonly -f buildStore

buildStore
