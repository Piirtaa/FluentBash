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

rightClickMouse()
{
	xdotool click 3
}
readonly -f rightClickMouse

moveMouseToCentre()
{
	xdotool mousemove --polar 0 0
}
readonly -f moveMouseToCentre

getCurrentWindow()
{
	xdotool getactivewindow
	#getwindowfocus -f
}
readonly -f getCurrentWindow

#usage:  getWindowGeometry WID
getWindowGeometry()
{
	local WID
	WID="$1"
	if [[ -z "$WID" ]]; then
		WID=$(getCurrentWindow)	
	fi
	
	xdotool getwindowgeometry --shell "$WID"
	
	#results will look like this
	#WINDOW=60817411
	#X=0
	#Y=51
	#WIDTH=1600
	#HEIGHT=849
	#SCREEN=0
}
readonly -f getWindowGeometry

getMouseLocationX()
{
	xdotool getmouselocation --shell | getLine 1 | getAfter =
}  
readonly -f getMouseLocationX   
         
getMouseLocationY()
{
	xdotool getmouselocation --shell | getLine 2 | getAfter =
}              
readonly -f getMouseLocationY

moveMouseRightHalfToEdge()
{
	local GEO WIDTH LENGTH X
	GEO=$(getWindowGeometry)

	#parse the width, divide it by 2
	WIDTH=$(echo "$GEO" | getLine 4 | getAfter = )
	X=$(getMouseLocationX)	
	LENGTH=$(( WIDTH - X ))	
	LENGTH=$(( LENGTH / 2 ))	
	
	debecho 	moveMouseRightHalfToEdge length "$LENGTH"
		
	xdotool mousemove_relative --polar 90 "$LENGTH" 
}
#debugFlagOn moveMouseRightHalfToEdge
readonly -f moveMouseRightHalfToEdge

moveMouseLeftHalfToEdge()
{
	local GEO WIDTH LENGTH X
	GEO=$(getWindowGeometry)

	#parse the width, divide it by 2
	WIDTH=$(echo "$GEO" | getLine 4 | getAfter = )
	X=$(getMouseLocationX)	
	LENGTH=$(( WIDTH - X ))	
	LENGTH=$(( LENGTH / 2 ))	
	
	debecho 	moveMouseLeftHalfToEdge length "$LENGTH"
		
	xdotool mousemove_relative --polar 270 "$LENGTH" 
}
#debugFlagOn moveMouseLeftHalfToEdge
readonly -f moveMouseLeftHalfToEdge

pasteText()
{
	xclip -o -selection clipboard
}
readonly -f pasteText