#!/bin/bash

#load loader first
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader


#load dependencies.  
loadScript book/bookGram.sh


GRAM=$(addData top "1
1 
1
1" )

GRAM=$(echo "$GRAM" | addData top.level2A "2A
2A" )

GRAM=$(echo "$GRAM" | addData top.level2B "2B
2B" )

GRAM=$(echo "$GRAM" | addData top.level2A.level3A "2A3B
2A3B" )

GRAM=$(echo "$GRAM" | removeData top.level2A )
echo "full gram"
echo "$GRAM" 
echo "------------"

declare -a OPS 
declare -a KEYS
declare -a VALUES

#convertBookGramToArrays  KEYS VALUES OPS  <<< "$GRAM"

#echo keys 
#dumpArray KEYS
#echo values
#dumpArray VALUES
#echo ops
#dumpArray OPS
echo "------------"

echo convert to array top.level2A 
convertBookGramToArrays KEYS VALUES OPS top.level2A <<< "$GRAM"
echo keys 
dumpArray KEYS
echo values
dumpArray VALUES
echo ops
dumpArray OPS
echo "------------"
echo "query level2A"
echo "$GRAM" | queryBook level2A 
echo "------------"
echo "query level4"
echo "$GRAM" | queryBook level4 
echo "------------"
echo "emerge top.level2A"
echo "$GRAM" | emergeBook top.level2A
echo "------------"
echo "emerge top"
echo "$GRAM" | emergeBook top 
echo "------------"
