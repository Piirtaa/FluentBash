#!/bin/bash
#summary:  automation functions
#tags: automation

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript automation/x11automation.sh

#usage:  ff_getVisibleWID
ff_getVisibleWID()
{
	xdotool search --all --onlyvisible --name Firefox*
}
readonly -f ff_getVisibleWID

#description: focuses on the address bar
#usage:
ff_focusAddress()
{
	xdotool key F6
}
readonly -f ff_focusAddress

#description: starts the search dialog
#usage:
ff_searchFor()
{
	ctrlKey f 
	typeText "$@"
}
readonly -f ff_searchFor

#description: opens page inspect
#usage:
ff_openPageInspect()
{
	xdotool key ctrl+shift+c
}
readonly -f ff_openPageInspect

#description: closes page inspect
#usage:
ff_closePageInspect()
{
	xdotool key ctrl+shift+i
}
readonly -f ff_closePageInspect

#description: enters page inspect, searches for an element by id, focuses on it, exits page inspect
#usage:
ff_findElementById()
{
	ff_openPageInspect
	sleep 1
	pressTab
	sleep 1
	typeText '#'"$1"
	pressEnter
	sleep 1
	ff_closePageInspect
}
readonly -f ff_findElementById

#description: opens a new tab
#usage:
ff_newTab()
{
	xdotool key ctrl+t
}
readonly -f ff_newTab

#description: opens the console dialog
#usage:
ff_openConsole()
{
	xdotool key ctrl+shift+k
}
readonly -f ff_openConsole

#description: creates a new tab and enters the js console we can interact with if we want to run some js in a REPL, but don't want the overhead of node.js 
#usage: ff_getVisibleWID | activateWID ; ff_newJSREPL
ff_newJSREPL()
{
	ff_newTab	
	typeText "about:blank"
	sleep 1	
	pressEnter
	sleep 1
	ff_openConsole
}
readonly -f ff_newJSREPL

#description: creates a sandbox for code to run
#usage: ff_createSandbox jsFile 
ff_createSandbox()
{
	local ID JSFILE JSCONTENTS HTML FNAME
	ID=$(genID)
	JSFILE="$1"
	if [[ ! -e "$JSFILE" ]] ; then
		debecho ff_createSandbox file does not exist "$JSFILE"		
		return 1	
	fi
	
	JSCONTENTS=$(cat "$JSFILE")
	
HTML=$(cat <<EOF
<html>
	<head>
	<script type="text/javascript" >
		
		const saveRun = function(functionToRun)
		{
			var fileContent = functionToRun();
			var dest=window.location.pathname.slice(0, -5).split("/").pop() + ".output";
			var bb = new Blob([fileContent ], { type: 'text/plain' });
			var a = document.createElement('a');
			a.download = dest;
			a.href = window.URL.createObjectURL(bb);
			a.click();
		};
	
		(()=>{
			Object.freeze(saveRun);
		})();
		
		function blockingSleep(milliseconds) 
		{
  			const date = Date.now();
  			let currentDate = null;
  			do {
    			currentDate = Date.now();
  			} while (currentDate - date < milliseconds);
		}

		(()=>{
			Object.freeze(blockingSleep);
		})();
		
	</script>
	</head>
	<body>
	<script type="text/javascript" >
	$JSCONTENTS
	</script>
	</body>
</html>
EOF
)
	debecho ff_createSandbox html "$HTML"
	FNAME="$ID"".html"
	debecho ff_createSandbox fname "$FNAME"
	echo "$HTML" > "$FNAME"
	firefox "$FNAME" >/dev/null

	echo "$ID"
	
	return 0
}
debugFlagOn ff_createSandbox

#description: runs js and outputs the results to stdout
#usage: ff_runInSandbox jsFile command
ff_runInSandbox()
{
	local JSFILE CMD ID WID
	JSFILE="$1"
	CMD="$2"
	
	ID=$(ff_createSandbox "$1")
		
	sleep 3	
	xdotool key ctrl+shift+i
	sleep 3	
	typeText "saveRun"
	typeText '('
	typeText $CMD
	typeText ')'
	pressEnter
	sleep 2
	
	#wait for "$ID".output to appear in a window title
	until WID=$(xdotool search --all --onlyvisible --name "$ID".output* ); test -n "$WID"; do
   	sleep 1
	done
	
	pressEnter	
	
	#grab the output file and echo its contents
	cat ~/Downloads/"$ID".output
	rm ~/Downloads/"$ID".output
	rm "$ID".html
	
	return 0
}

