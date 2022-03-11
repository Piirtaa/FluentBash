#!/bin/bash
#summary: a captive portal
#tags: web server

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript unitOfWork/trigger.sh

#./oneshot.sh index.html 8080 &
#curl localhost:8080 

PAGE=index.html
COPY=copy.html

before()
{
	cat <<EOF | tee "$PAGE" > /dev/null 2>&1
<html>
<head></head>
<body>
yo
</body>
</html>
EOF

	#NOTE:  the redirection of stdout MUST happen or this function will hang in the trigger mechanism!!
	./oneshot.sh "$PAGE" 8080 >/dev/null & 
	return 0
}
trigger()
{
	curl localhost:8080 > "$COPY"
	return 0
}
after()
{
	debugFlagOn after
	
	local CONTENT1 CONTENT2
	CONTENT1=$(cat "$PAGE")
	CONTENT2=$(cat "$COPY")
	if [[ "$CONTENT1" == "$CONTENT2" ]]; then
		debecho after "same content"
	else
		debecho after "diff content"
	fi
	
	rm "$PAGE"
	rm "$COPY"
	
	debugFlagOff after
	
	return 0
}

createTrigger step1 trigger before after
activateTrigger step1 5
rm step1


