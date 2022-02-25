#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#set debecho flags
#debugFlagOn loadScript

#load dependencies.  
loadScript $BASH_DIR/../caching/keyValueStore.sh


echo "Current Index:" "$CURRENT_INDEX"
echo "Mounts:"
mount | grep "$DEVICENAME"
dumpDirContents "$BASEFS"
dumpDirContents "$DATAFS"


