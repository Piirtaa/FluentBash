#!/bin/bash
#summary: library supporting common validator functions
#tags: validation

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
#loadScript piping/keyValueGram.sh

#description:  validates not empty
#usage: isNotEmpty someArg
isNotEmpty()
{
	if [[ -z "$1" ]] ; then
		return 1
	fi
	
	return 0
}
readonly -f isNotEmpty

#description:  validates numeric
#usage: isNumeric someArg
isNumeric()
{
	case $1 in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
	esac
}
readonly -f isNumeric

#description:  validates alpha numeric
#usage: isAlphaNumeric someArg
isAlphaNumeric()
{
	if [[ "$1" =~ [^a-zA-Z0-9] ]]; then
  		return 1
	fi
	return 0
}
readonly -f isAlphaNumeric

#description:  validates alpha numeric
#usage: contains lookingFor lookingIn
contains()
{
	$(echo "$2" | ifContains "$1")
}
readonly -f contains

#description:  validates less than
#usage: isLessThan 10
isLessThan()
{
	[[ "$2" -lt "$1" ]]
}
readonly -f isLessThan

#description:  validates less than or equal
#usage: isLessThanOrEqual 10
isLessThanOrEqual()
{
	[[ "$2" -le "$1" ]]
}
readonly -f isLessThanOrEqual

#description:  validates greater than
#usage: isGreaterThan 10
isGreaterThan()
{
	[[ "$2" -gt "$1" ]]
}
readonly -f isGreaterThan

#description:  validates greater than or equal
#usage: isGreaterThanOrEqual 10
isGreaterThanOrEqual()
{
	[[ "$2" -ge "$1" ]]
}
readonly -f isGreaterThanOrEqual
