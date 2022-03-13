#!/bin/bash


#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript validation/functionSig.sh
loadScript validation/validators.sh

#usage:  addThreeNumbers 1 2 3
addThreeNumbers()
{
	local arg1 arg2 arg3
	arg1="$1"
	arg2="$2"
	arg3="$3"
	
	echo $(( arg1 + arg2 + arg3 ))	
}

#define a validation signature
SIG=$(createSig addThreeNumbers | addParameter arg1 1 false 0 | addParameter arg2 2 false 0 | addParameter arg3 3 false 0)
SIG=$(echo "$SIG" | addParamValidator arg1 isNumeric | addParamValidator arg2 isNumeric | addParamValidator arg3 isNumeric)
SIG=$(echo "$SIG" | addParamValidator arg1 isLessThan 10 | addParamValidator arg2 isGreaterThan 10 | addParamValidator arg3 isLessThan 20 | addParamValidator arg3 isGreaterThanOrEqual 15)

validateSig addThreeNumbers 1 11 15

validateSig addThreeNumbers 1 11 25