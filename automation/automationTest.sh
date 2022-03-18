#!/bin/bash
#summary:  scraping functions
#tags: scraping

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript automation/x11automation.sh
loadScript automation/queryGoogle.sh
loadScript automation/scraping.sh
loadScript automation/firefox.sh

searchGoogle dog training methods > dumpfile.html 
cat dumpfile.html | parseSearchResultUrls
rm dumpfile.html

