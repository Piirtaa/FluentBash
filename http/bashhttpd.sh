#!/usr/bin/env bash

#############################################################################
###########################################################################
###                          bashttpd v 1.12
###
### Original author: Avleen Vig,       2012
### Reworked by:     Josh Cartwright,  2012
### Modified by:     A.M.Danischewski, 2015 
### Issues: If you find any issues leave me a comment at 
### http://scriptsandoneliners.blogspot.com/2015/04/bashttpd-self-contained-bash-webserver.html 
### 
### This is a simple Bash based webserver. By default it will browse files and allows for 
### retrieving binary files. 
### 
### It has been tested successfully to view and stream files including images, mp3s, 
### mp4s and downloading files of any type including binary and compressed files via  
### any web browser. 
### 
### Successfully tested on various browsers on Windows, Linux and Android devices (including the 
### Android Smartwatch ZGPAX S8).  
### 
### It handles favicon requests by hardcoded favicon image -- by default a marathon 
### runner; change it to whatever you want! By base64 encoding your favorit favicon 
### and changing the global variable below this header.  
### 
### Make sure if you have a firewall it allows connections to the port you plan to 
### listen on (8080 by default).  
### 
### By default this program will allow for the browsing of files from the 
### computer where it is run.  
###  
### Make sure you are allowed connections to the port you plan to listen on 
### (8080 by default). Then just drop it on a host machine (that has bash) 
### and start it up like this:
###      
### $192.168.1.101> bashttpd -s
###      
### On the remote machine you should be able to browse and download files from the host 
### server via any web browser by visiting:
###      
### http://192.168.1.101:8080 
###  
#### This program requires (to work to full capacity) by default: 
### socat or netcat (w/ '-e' option - on Ubuntu netcat-traditional)
### tree - useful for pretty directory listings 
### If you are using socat, you can type: bashttpd -s  
### 
### to start listening on the LISTEN_PORT (default is 8080), you can change 
### the port below.  
###  E.g.    nc -lp 8080 -e ./bashttpd ## <-- If your nc has the -e option.   
###  E.g.    nc.traditional -lp 8080 -e ./bashttpd 
###  E.g.    bashttpd -s  -or- socat TCP4-LISTEN:8080,fork EXEC:bashttpd
### 
### Copyright (C) 2012, Avleen Vig <avleen@gmail.com>
### 
### Permission is hereby granted, free of charge, to any person obtaining a copy of
### this software and associated documentation files (the "Software"), to deal in
### the Software without restriction, including without limitation the rights to
### use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
### the Software, and to permit persons to whom the Software is furnished to do so,
### subject to the following conditions:
### 
### The above copyright notice and this permission notice shall be included in all
### copies or substantial portions of the Software.
### 
### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
### IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
### FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
### COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
### IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
### CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
### 
###########################################################################
#############################################################################

  ### CHANGE THIS TO WHERE YOU WANT THE CONFIGURATION FILE TO RESIDE 
declare -r BASHTTPD_CONF="/tmp/bashttpd.conf"

  ### CHANGE THIS IF YOU WOULD LIKE TO LISTEN ON A DIFFERENT PORT 
declare -i LISTEN_PORT=8080  

 ## If you are on AIX, IRIX, Solaris, or a hardened system redirecting 
 ## to /dev/random will probably break, you can change it to /dev/null.  
declare -a DUMP_DEV="/dev/random" 

 ## Just base64 encode your favorite favicon and change this to whatever you want.    
declare -r FAVICON="AAABAAEAEBAAAAEAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAADg4+3/srjc/5KV2P+ortn/xMrj/6Ch1P+Vl9f/jIzc/3572f+CgNr/fnzP/3l01f+Ih9r/h4TZ/8fN4//P1Oj/3uPr/7O+1v+xu9X/u8XY/9bi6v+UmdD/XV26/3F1x/+GitT/VVXC/3x/x/+HjNT/lp3Z/6633f/E0eD/2ePr/+bt8v/U4+v/0uLp/9Xj6//Z5e3/oKbX/0pJt/9maML/cHLF/3p8x//T3+n/3Ofu/9vo7//W5Oz/0uHq/9zn7f/j6vD/1OLs/8/f6P/R4Oj/1OPr/7jA4f9KSbf/Skm3/3p/yf/U4ez/1ePq/9rn7//Z5e3/0uHp/87e5//a5Ov/5Ovw/9Hf6v/T4uv/1OLp/9bj6/+kq9r/Skq3/0pJt/+cotb/zdnp/9jl7f/a5u//1+Ts/9Pi6v/O3ub/2uXr/+bt8P/Q3un/0eDq/9bj7P/Z5u7/r7jd/0tKt/9NTLf/S0u2/8zW6v/c5+//2+fv/9bj6//S4un/zt3m/9zm7P/k7PD/1OPr/9Li7P/V5Oz/2OXt/9jl7v+HjM3/lZvT/0tKt/+6w+L/2ebu/9fk7P/V4+v/0uHq/83d5v/a5ev/5ezw/9Pi6v/U4+z/1eXs/9bj6//b5+//vsjj/1hYvP9JSLb/horM/9nk7P/X5e3/1eTs/9Pi6v/P3uf/2eXr/+Tr7//O3+n/0uLr/9Xk7P/Y5e3/w8/k/7XA3/9JR7f/SEe3/2lrw//G0OX/1uLr/9Xi7P/T4ev/0N/o/9zn7f/k7PD/zN3p/8rd5v/T4ur/1ePt/5We0/+0w9//SEe3/0pKt/9OTrf/p7HZ/7fD3//T4uv/0N/o/9Hg6f/d5+3/5ezw/9Li6//T4uv/2ubu/8PQ5f9+hsr/ucff/4eOzv+Ei8z/rLja/8zc6P/I1+b/0OLq/8/f6P/Q4Oj/3eft/+bs8f/R4On/0+Lq/9Tj6v/T4Ov/wM7h/9Df6f/M2uf/z97q/9Dg6f/Q4On/1OPr/9Tj6//S4ur/0ODp/93o7f/n7vH/0N/o/8/f5//P3+b/2OXt/9zo8P/c6fH/zdjn/7fB3/+3weD/1eLs/9nn7//V5Oz/0+Lr/9Pi6//e6O7/5u3x/9Pi6v/S4en/0uLp/9Tj6//W4+v/3Ojw/9rm7v9vccT/wcvm/9rn7//X5Oz/0uHq/9Hg6f/S4er/3uju/+bt8f/R4On/0uHp/9Xk6//Y5u7/1OTs/9bk7P/W5Ov/XFy9/2lrwf/a5+//1uPr/9Pi6v/U4er/0eHq/93o7v/v8vT/5ezw/+bt8f/o7vL/6e/z/+jv8v/p7/L/6e/y/9XZ6//IzOX/6e7y/+nv8v/o7vL/5+7x/+ft8f/r8PP/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==" 

declare -i DEBUG=1 
declare -i VERBOSE=0
declare -a REQUEST_HEADERS
declare    REQUEST_URI="" 
declare -a HTTP_RESPONSE=(
   [200]="OK"
   [400]="Bad Request"
   [403]="Forbidden"
   [404]="Not Found"
   [405]="Method Not Allowed"
   [500]="Internal Server Error")
declare DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")
declare -a RESPONSE_HEADERS=(
      "Date: $DATE"
   "Expires: $DATE"
    "Server: Slash Bin Slash Bash"
)

function warn() { ((${VERBOSE})) && echo "WARNING: $@" >&2; }

function chk_conf_file() { 
[ -r "${BASHTTPD_CONF}" ] || {
   cat >"${BASHTTPD_CONF}" <<'EOF'
#
# bashttpd.conf - configuration for bashttpd
#
# The behavior of bashttpd is dictated by the evaluation
# of rules specified in this configuration file.  Each rule
# is evaluated until one is matched.  If no rule is matched,
# bashttpd will serve a 500 Internal Server Error.
#
# The format of the rules are:
#    on_uri_match REGEX command [args]
#    unconditionally command [args]
#
# on_uri_match:
#   On an incoming request, the URI is checked against the specified
#   (bash-supported extended) regular expression, and if encounters a match the
#   specified command is executed with the specified arguments.
#
#   For additional flexibility, on_uri_match will also pass the results of the
#   regular expression match, ${BASH_REMATCH[@]} as additional arguments to the
#   command.
#
# unconditionally:
#   Always serve via the specified command.  Useful for catchall rules.
#
# The following commands are available for use:
#
#   serve_file FILE
#     Statically serves a single file.
#
#   serve_dir_with_tree DIRECTORY
#     Statically serves the specified directory using 'tree'.  It must be
#     installed and in the PATH.
#
#   serve_dir_with_ls DIRECTORY
#     Statically serves the specified directory using 'ls -al'.
#
#   serve_dir  DIRECTORY
#     Statically serves a single directory listing.  Will use 'tree' if it is
#     installed and in the PATH, otherwise, 'ls -al'
#
#   serve_dir_or_file_from DIRECTORY
#     Serves either a directory listing (using serve_dir) or a file (using
#     serve_file).  Constructs local path by appending the specified root
#     directory, and the URI portion of the client request.
#
#   serve_static_string STRING
#     Serves the specified static string with Content-Type text/plain.
#
# Examples of rules:
#
# on_uri_match '^/issue$' serve_file "/etc/issue"
#
#   When a client's requested URI matches the string '/issue', serve them the
#   contents of /etc/issue
#
# on_uri_match 'root' serve_dir /
#
#   When a client's requested URI has the word 'root' in it, serve up
#   a directory listing of /
#
# DOCROOT=/var/www/html
# on_uri_match '/(.*)' serve_dir_or_file_from "$DOCROOT"
#   When any URI request is made, attempt to serve a directory listing
#   or file content based on the request URI, by mapping URI's to local
#   paths relative to the specified "$DOCROOT"
#
#unconditionally serve_static_string 'Hello, world!  You can configure bashttpd by modifying bashttpd.conf.'
DOCROOT=/
on_uri_match '/(.*)' serve_dir_or_file_from 
# More about commands:
#
# It is possible to somewhat easily write your own commands.  An example
# may help.  The following example will serve "Hello, $x!" whenever
# a client sends a request with the URI /say_hello_to/$x:
#
# serve_hello() {
#    add_response_header "Content-Type" "text/plain"
#    send_response_ok_exit <<< "Hello, $2!"
# }
# on_uri_match '^/say_hello_to/(.*)$' serve_hello
#
# Like mentioned before, the contents of ${BASH_REMATCH[@]} are passed
# to your command, so its possible to use regular expression groups
# to pull out info.
#
# With this example, when the requested URI is /say_hello_to/Josh, serve_hello
# is invoked with the arguments '/say_hello_to/Josh' 'Josh',
# (${BASH_REMATCH[0]} is always the full match)
EOF
   warn "Created bashttpd.conf using defaults.  Please review and configure bashttpd.conf before running bashttpd again."
#  exit 1
} 
}

function recv() { ((${VERBOSE})) && echo "< $@" >&2; }

function send() { ((${VERBOSE})) && echo "> $@" >&2; echo "$*"; }

function add_response_header() { RESPONSE_HEADERS+=("$1: $2"); }

function send_response_binary() {
  local code="$1"
  local file="${2}" 
  local transfer_stats="" 
  local tmp_stat_file="/tmp/_send_response_$$_"
  send "HTTP/1.0 $1 ${HTTP_RESPONSE[$1]}"
  for i in "${RESPONSE_HEADERS[@]}"; do
     send "$i"
  done
  send
 if ((${VERBOSE})); then 
   ## Use dd since it handles null bytes
  dd 2>"${tmp_stat_file}" < "${file}" 
  transfer_stats=$(<"${tmp_stat_file}") 
  echo -en ">> Transferred: ${file}\n>> $(awk '/copied/{print}' <<< "${transfer_stats}")\n" >&2  
  rm "${tmp_stat_file}"
 else 
   ## Use dd since it handles null bytes
  dd 2>"${DUMP_DEV}" < "${file}"   
 fi 
}   

function send_response() {
  local code="$1"
  send "HTTP/1.0 $1 ${HTTP_RESPONSE[$1]}"
  for i in "${RESPONSE_HEADERS[@]}"; do
     send "$i"
  done
  send
  while IFS= read -r line; do
     send "${line}"
  done
}

function send_response_ok_exit() { send_response 200; exit 0; }

function send_response_ok_exit_binary() { send_response_binary 200  "${1}"; exit 0; }

function fail_with() { send_response "$1" <<< "$1 ${HTTP_RESPONSE[$1]}"; exit 1; }

function serve_file() {
  local file="$1"
  local CONTENT_TYPE=""
  case "${file}" in
    *\.css)
      CONTENT_TYPE="text/css"
      ;;
    *\.js)
      CONTENT_TYPE="text/javascript"
      ;;
    *)
      CONTENT_TYPE=$(file -b --mime-type "${file}")
      ;;
  esac
  add_response_header "Content-Type"  "${CONTENT_TYPE}"
  CONTENT_LENGTH=$(stat -c'%s' "${file}") 
  add_response_header "Content-Length" "${CONTENT_LENGTH}"
    ## Use binary safe transfer method since text doesn't break. 
  send_response_ok_exit_binary "${file}"
}

function serve_dir_with_tree() {
  local dir="$1" tree_vers tree_opts basehref x
    ## HTML 5 compatible way to avoid tree html from generating favicon
    ## requests in certain browsers, such as browsers in android smartwatches. =) 
  local no_favicon=" <link href=\"data:image/x-icon;base64,${FAVICON}\" rel=\"icon\" type=\"image/x-icon\" />"  
  local tree_page="" 
  local base_server_path="/${2%/}"
  [ "$base_server_path" = "/" ] && base_server_path=".." 
  local tree_opts="--du -h -a --dirsfirst" 
  add_response_header "Content-Type" "text/html"
   # The --du option was added in 1.6.0.   "/${2%/*}"
  read _ tree_vers x < <(tree --version)
  tree_page=$(tree -H "$base_server_path" -L 1 "${tree_opts}" -D "${dir}")
  tree_page=$(sed "5 i ${no_favicon}" <<< "${tree_page}")  
  [[ "${tree_vers}" == v1.6* ]] 
  send_response_ok_exit <<< "${tree_page}"  
}

function serve_dir_with_ls() {
  local dir="$1"
  add_response_header "Content-Type" "text/plain"
  send_response_ok_exit < \
     <(ls -la "${dir}")
}

function serve_dir() {
  local dir="$1"
   # If `tree` is installed, use that for pretty output.
  which tree &>"${DUMP_DEV}" && \
     serve_dir_with_tree "$@"
  serve_dir_with_ls "$@"
  fail_with 500
}

function urldecode() { [ "${1%/}" = "" ] && echo "/" ||  echo -e "$(sed 's/%\([[:xdigit:]]\{2\}\)/\\\x\1/g' <<< "${1%/}")"; } 

function serve_dir_or_file_from() {
  local URL_PATH="${1}/${3}"
  shift
  URL_PATH=$(urldecode "${URL_PATH}") 
  [[ $URL_PATH == *..* ]] && fail_with 400
   # Serve index file if exists in requested directory
  [[ -d "${URL_PATH}" && -f "${URL_PATH}/index.html" && -r "${URL_PATH}/index.html" ]] && \
     URL_PATH="${URL_PATH}/index.html"
  if [[ -f "${URL_PATH}" ]]; then
     [[ -r "${URL_PATH}" ]] && \
        serve_file "${URL_PATH}" "$@" || fail_with 403
  elif [[ -d "${URL_PATH}" ]]; then
     [[ -x "${URL_PATH}" ]] && \
        serve_dir  "${URL_PATH}" "$@" || fail_with 403
  fi
  fail_with 404
}

function serve_static_string() {
  add_response_header "Content-Type" "text/plain"
  send_response_ok_exit <<< "$1"
}

function on_uri_match() {
  local regex="$1"
  shift
  [[ "${REQUEST_URI}" =~ $regex ]] && \
     "$@" "${BASH_REMATCH[@]}"
}

function unconditionally() { "$@" "$REQUEST_URI"; }

function main() { 
  local recv="" 
  local line="" 
  local REQUEST_METHOD=""
  local REQUEST_HTTP_VERSION="" 
  chk_conf_file
  [[ ${UID} = 0 ]] && warn "It is not recommended to run bashttpd as root."
   # Request-Line HTTP RFC 2616 $5.1
  read -r line || fail_with 400
  line=${line%%$'\r'}
  recv "${line}"
  read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION <<< "${line}"
  [ -n "${REQUEST_METHOD}" ] && [ -n "${REQUEST_URI}" ] && \
   [ -n "${REQUEST_HTTP_VERSION}" ] || fail_with 400
   # Only GET is supported at this time
  [ "${REQUEST_METHOD}" = "GET" ] || fail_with 405
  while IFS= read -r line; do
    line=${line%%$'\r'}
    recv "${line}"
      # If we've reached the end of the headers, break.
    [ -z "${line}" ] && break
    REQUEST_HEADERS+=("${line}")
  done
} 

if [[ ! -z "{$1}" ]] && [ "${1}" = "-s" ]; then 
 socat TCP4-LISTEN:${LISTEN_PORT},fork EXEC:"${0}" 
else 
 main 
 source "${BASHTTPD_CONF}" 
 fail_with 500
fi 
