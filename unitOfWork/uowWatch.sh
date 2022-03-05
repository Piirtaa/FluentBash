#!/bin/bash
#summary:  uow manager script.  expects uow file ($1)  and polling interval in seconds ($2).  will constantly examine trigger conditions and react accordingly.
#tags: unit of work, uow, task, job, orchestration, bot, automation

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/uow.sh

watchJob "$1" "$2"