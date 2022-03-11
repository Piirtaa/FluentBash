#!/bin/bash
file="$1"
port="$2"
if [[ -n "$file" ]] && [[ -n "$port" ]]; then
        { echo -ne "HTTP/1.0 200 OK\r\nContent-Disposition: inline; filename=\"$1\"\r\nContent-Length: $(wc -c < $file)\r\n\r\n"; cat "$file"; } | nc -l "$port"
else
        echo "Usage: oneshot.sh <file> <port>"
fi

exit 0