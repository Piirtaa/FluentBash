#!/bin/bash
#summary:  meta reporting on scripts
#tags: meta, fluentBash

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript core/meta.sh
loadScript piping/piping.sh

TESTS=$(getAllScripts | doEachLine ifEndsWith "Test.sh" | doEachLine getAfter "../" )
echo "$TESTS"
echo "$TESTS" | doEachLine runAsLastArg loadScript
 
	
	