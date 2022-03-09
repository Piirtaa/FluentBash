#!/bin/bash
#summary: examine stack
#tags: networking

#load loader first.  
#[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#source $BASH_DIR/../core/core.sh #first thing we load is the script loader



# Check if user is root
if [[ ! $(whoami) = "root" ]] ; then
	echo "error: must be root" 
	exit 1
fi

for x in /etc/runlevels/default/net.* ; do
	echo basename $x	
	#rc-update del $(basename $x) default 
	#rc-service --ifstarted $(basename $x) stop
done

#sed -i '/rc_need="non-existent_service"/d' /etc/conf.d/NetworkManager
#rc-service NetworkManager restart
#rc-update add NetworkManager default # Only needed if I earlier deleted the service from the default runlevel.

