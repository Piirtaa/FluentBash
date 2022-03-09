#!/bin/bash
#uninitializes the kv library

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

#test whether this device exists
mount | grep "$DEVICENAME" > /dev/null && sudo umount "$BASEFS"

sudo rm -rf "$BASEFS" || echo failed to remove "$BASEFS" 

