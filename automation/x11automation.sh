#!/bin/bash
#summary:  automation functions
#tags: automation

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/trigger.sh

#description:  determines the session type of the first login session
#usage:  getFirstSessionType
getFirstSessionType()
{
	local SESSION STYPE
	SESSION=$(loginctl | getLine 2 | getArrayItem 0 )
	 
	STYPE=$(loginctl show-session "$SESSION" -p Type | getAfter Type= )
		
	echo "$STYPE"
}
readonly -f getFirstSessionType

#description:  determines if x11 session
#usage:   isX11 || kack
isX11()
{
	[[ $(getSessionType) == x11 ]]
}
readonly -f isX11

#description:  activates window by window id
#usage:  getVisibleFirefoxWID | activateWID
activateWID()
{
	local WID
	WID=$(getStdIn)

	xdotool windowactivate "$WID"  	
}
readonly -f activateWID

typeText()
{
	xdotool type "$@"
}
readonly -f typeText

pressEnter()
{
	xdotool key Enter
}
readonly -f pressEnter

pressTab()
{
	xdotool key Tab
}
readonly -f pressTab

pressUpArrow()
{
	xdotool key 111
}
readonly -f pressUpArrow

pressDownArrow()
{
	xdotool key 116

}
readonly -f pressDownArrow

pressRightArrow()
{
	xdotool key 114

}
readonly -f pressRightArrow

pressLeftArrow()
{
	xdotool key 113

}
readonly -f pressLeftArrow

altKey()
{
	xdotool key alt+"$1"
}
readonly -f altKey

ctrlKey()
{
	xdotool key ctrl+"$1"
}
readonly -f ctrlKey

shiftKey()
{
	xdotool key shift+"$1"
}
readonly -f shiftKey

