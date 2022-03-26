#!/bin/bash

#load loader first
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader


#load dependencies.  
loadScript book/bookGram.sh


#GRAM=$(addData top "1
#1 
#1
#1" )
#
#GRAM=$(echo "$GRAM" | addData top.level2A "2A
#2A" )
#
#GRAM=$(echo "$GRAM" | addData top.level2B "2B
#2B" )
#
#GRAM=$(echo "$GRAM" | addData top.level2A.level3A "2A3B
#2A3B" )
#
#GRAM=$(echo "$GRAM" | removeData top.level2A )
#echo "full gram"
#echo "$GRAM" 
#echo "------------"
#
#typeset -a OPS 
#typeset -a KEYS
#typeset -a VALUES

#convertBookGramToArrays  KEYS VALUES OPS  <<< "$GRAM"

#echo keys 
#dumpArray KEYS
#echo values
#dumpArray VALUES
#echo ops
#dumpArray OPS
#echo "------------"

#echo convert to array top.level2A 
#convertBookGramToArrays KEYS VALUES OPS top.level2A <<< "$GRAM"
#echo keys 
#dumpArray KEYS
#echo values
#dumpArray VALUES
#echo ops
#dumpArray OPS
#echo "------------"
#echo "query level2A"
#echo "$GRAM" | queryBook level2A 
#echo "------------"
#echo "query level4"
#echo "$GRAM" | queryBook level4 
#echo "------------"
#echo "emerge top.level2A"
#echo "$GRAM" | emergeBook top.level2A
#echo "------------"
#echo "emerge top"
#echo "$GRAM" | emergeBook top 
#echo "------------"

function generateGram()
{
	local I J LENGTH BRANCH GRAM DATA KEY
	LENGTH=1000
	BRANCH=0
	DATA=$(echo "dataline1"; echo "dataline2"; echo "dataline3"; echo "dataline4"; echo "dataline5"; echo "dataline6"; echo "dataline7"; echo "dataline8"; echo "dataline9"; ) 

	for ((I = 0 ; I < "$LENGTH" ; I++)); do
		BRANCH=$((BRANCH +1))
		if (( "$BRANCH" >= 10 )); then
			BRANCH=1
		fi
		
		KEY=branch"$BRANCH"
		#GRAM=$(echo "$GRAM" | addData "$KEY" "$DATA")	
		GRAM=$(addData "$KEY" "$DATA" <<< "$GRAM")	

	done
	
	echo "$GRAM"  
	
}

function emerge1()
{
	emergeBook <<< "$GRAM" >/dev/null
}
function emerge2()
{
	echo "$GRAM" | emergeBook >/dev/null
}
function emerge3()
{
	emergeBook < <(echo "$GRAM") >/dev/null
}


GRAM=$(generateGram)
echo heredoc
time emerge1
echo pipe
time emerge2 
echo process sub
time emerge3
