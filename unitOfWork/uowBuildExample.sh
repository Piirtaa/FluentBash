#!/bin/bash

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/uow.sh

#construct a  unit of work
UOW=$(workCreate)

#register variables
UOWVAR="this is an initial var"
UOW=$(echo "$UOW" |  workSetVar UOWVAR)

#register files
echo "this is some file data" > dataFile
UOW=$(echo "$UOW" |  workSetFile dataFile)

#define strategies
canInit() {	return 0 }
init() { return 0 }
canRun() { return 0 }
run() { return 0 }
canStop() { return 0 }
stop() { return 0 }
canDispose() { return 0 }
dispose() { return 0 }

#register strategies
UOW=$(echo "$UOW" | workAddCanInitStrategy canInit | workSetInitStrategy init | workAddCanStartStrategy canRun |  workSetStartStrategy run)
UOW=$(echo "$UOW" | workAddCanStopStrategy canStop | workSetStopStrategy stop | workAddCanDisposeStrategy canDispose | workSetDisposeStrategy dispose)

