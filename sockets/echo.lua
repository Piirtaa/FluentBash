#!/usr/bin/env lua
local params = {...}
params[1] -- first parameter, if any.
params[2] -- second parameter, if any.
#params

local signal = require("posix.signal")
local socket = require("socket")
local string = require("string")

-- create a TCP socket and bind it to the local host, at any port
local server = assert(socket.bind("127.0.0.1", 0))
local ip, port = server:getsockname()

print(string.format("telnet %s %s", ip, port))

local running = 1

local function stop(sig)
    running = 0
    return 0
end

-- Interrupt
signal.signal(signal.SIGINT, stop)

while 1 == running do
    local client = server:accept()
    client:settimeout(9)
    local msg, err = client:receive()
    while not err and "quit" ~= msg do
        print(string.format("received: %s", msg))
        client:send(msg)
        client:send("\n")
        msg, err = client:receive()
    end
    client:close()
end
server:close()
