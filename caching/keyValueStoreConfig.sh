#!/bin/bash

#define config vars for keyValueStore.sh and related scripts
BASEFS="/tmp/kvram"
INDEX_FILE="$BASEFS"/index.txt
COUNTER_FILE="$BASEFS"/counter.txt
COUNTER_LOCK="$BASEFS"/counter.lock
DATAFS="$BASEFS"/data
SIZE=1000
DEVICENAME="keyvaluestore"



