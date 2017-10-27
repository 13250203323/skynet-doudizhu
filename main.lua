local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

local max_client = 1000

skynet.start(function()
	print(">>>> main server start")

	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	
	skynet.uniqueservice("protoloader")
	-- skynet.uniqueservice("roommanager")
	-- skynet.newservice("roledtdb")
	-- skynet.newservice("simpledb")

	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		address = "127.0.0.1",
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	
	skynet.exit()
end)
