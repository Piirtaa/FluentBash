#!/bin/bash

#builds sendToTTY.c

#usage: ./sendToTTY hi < "$some_tty"
#to get current tty:  tty

gcc sendToTTY.c -o sendToTTY
