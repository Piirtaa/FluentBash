#!/bin/bash
#uninitializes the kv library

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#set debecho flags
#debugFlagOn loadScript

#deps
#load dependencies.  
loadScript $BASH_DIR/../piping/piping.sh
loadScript $BASH_DIR/../piping/strings.sh
loadScript $BASH_DIR/../piping/lists.sh
loadScript $BASH_DIR/../piping/conditionals.sh


#configuration of this subsystem
loadScript $BASH_DIR/../caching/keyValueStoreConfig.sh

#test whether this device exists
mount | grep "$DEVICENAME" > /dev/null && sudo umount "$BASEFS"

sudo rm -rf "$BASEFS" || echo failed to remove "$BASEFS" 

