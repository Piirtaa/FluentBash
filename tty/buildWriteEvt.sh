#!/bin/bash

#builds sendToTTY.c

#usage: sudo writevt /dev/ttyN command 
#to get current tty:  tty
#you have to use '\r' (or '\x0D') instead of '\n' (or '\x0A') to send a return.

gcc writeEvt.c -o writeEvt
