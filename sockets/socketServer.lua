#!/usr/bin/env lua
--usage:  ./socketServer.lua handlerScript
--description:  opens up a listening socket.  upon msg receipt the handlerFile is invoked and the results (stdout) are sent back.

local handlerScript = arg[1]

local signal = require("posix.signal")
local socket = require("socket")
local string = require("string")
local shell = require("resty.shell")

-- create a TCP socket and bind it to the local host, at any port
local server = assert(socket.bind("127.0.0.1", 0))
local ip, port = server:getsockname()

--print informing what port is up
print(string.format("telnet %s %s", ip, port))

--flags/function to stop the service
local running = 1

local function stop(sig)
    running = 0
    return 0
end

-- Interrupt
signal.signal(signal.SIGINT, stop)

--listen loop
while 1 == running do
    local client = server:accept()
    client:settimeout(9)
    local msg, err = client:receive()
    while not err and "quit" ~= msg do
        print(string.format("received: %s", msg))

		local stdin = msg
		local timeout = 1000  -- ms
		local max_size = 4096  -- byte

		local ok, stdout, stderr, reason, status =
			shell.run(handlerScript, stdin, timeout, max_size)
		if ok then
			client:send(stdout)
		end
		
		--invoke the handler
		--msg, err = os.execute(handlerScript, msg)
		--client:send("\n")
        --msg, err = client:receive()
    end
    client:close()
end
server:close()
