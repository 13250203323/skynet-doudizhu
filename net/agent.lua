local skynet = require "skynet"
local netpack = require "skynet.netpack"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local player = require("player")

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}

local client_fd
local oPlayer
local playerId

function REQUEST:quit()
	local roledb = skynet.uniqueservice("roledb")
	skynet.call(roledb, "lua", "unLine", playerId)
	if oPlayer then 
		local roomIdx = oPlayer:getRoom()
		local roomManager = skynet.uniqueservice("roommanager")
		skynet.call(roomManager, "lua", "quitRoom", client_fd, playerId, roomIdx)
		oPlayer = nil 
	end
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

function REQUEST:login()
	if oPlayer then 
		return {errcode = 3}
	end
	local roledb = skynet.uniqueservice("roledb")
	local result = skynet.call(roledb, "lua", "checkRole", self.id, self.passwork)
	if result == 0 then 
		oPlayer = player.new(fd, self.id)
		playerId = self.id
	end
	return {errcode = result}
end

-- 快速开始
function REQUEST:quickstart()
	if not oPlayer then 
		return {errcode = 4, waittime = 0} -- 没玩家
	elseif oPlayer:getRoom() ~= 0 then
		return {errcode = 5, waittime = 0}  -- 已经在房间
	end
	local roomManager = skynet.uniqueservice("roommanager")
	local idx, seat = skynet.call(roomManager, "lua", "enterRoom", client_fd, playerId)
	oPlayer:setRoom(idx)
	oPlayer:setState(1)
	return {errcode = 0, waittime = 60, seat = seat}
end

-- 取消快速开始
function REQUEST:cancelstart()
	if not oPlayer then 
		return {errcode = 4} -- 没玩家
	elseif oPlayer:getRoom() == 0 then 
		return {errcode = 6} -- 没进房间
	elseif oPlayer:getState() == 2 then 
		return {errcode = 7} -- 准备中
	end
	local roomIdx = oPlayer:getRoom()
	local roomManager = skynet.uniqueservice("roommanager")
	local err = skynet.call(roomManager, "lua", "quitRoom", client_fd, playerId, roomIdx)
	if err == 0 then 
		oPlayer:setRoom(0)
		oPlayer:setState(0)
	end
	return {errcode = err}
end

-- 准备
function REQUEST:ready()
	if not oPlayer then 
		return {errcode = 4} -- 未登录
	elseif oPlayer:getRoom() == 0 then 
		return {errcode = 6} -- 没进房间
	elseif oPlayer:getState() == 2 then 
		return {errcode = 7} -- 准备中
	end
	local roomIdx = oPlayer:getRoom()
	local roomManager = skynet.uniqueservice("roommanager")
	local err = skynet.call(roomManager, "lua", "changeState", client_fd, playerId, roomIdx, 2)
	if err == 0 then 
		oPlayer:setState(2)
	end
	return {errcode = err}
end

-- 取消准备
function REQUEST:cancelready()
	if not oPlayer then 
		return {errcode = 4} -- 没玩家
	elseif oPlayer:getRoom() == 0 then 
		return {errcode = 6} -- 没进房间
	elseif oPlayer:getState() == 1 then 
		return {errcode = 12} -- 未准备
	end
	local roomIdx = oPlayer:getRoom()
	local roomManager = skynet.uniqueservice("roommanager")
	local err = skynet.call(roomManager, "lua", "changeState", client_fd, playerId, roomIdx, 1)
	if err == 0 then 
		oPlayer:setState(1)
	end
	return {errcode = err}
end

-- 叫地主或抢地主
function REQUEST:calllandholder()
	if not oPlayer then 
		return {errcode = 4} -- 没玩家
	elseif oPlayer:getRoom() == 0 then 
		return {errcode = 6} -- 没进房间
	elseif oPlayer:getState() == 1 then 
		return {errcode = 12} -- 未准备
	end
	local roomIdx = oPlayer:getRoom()
	local roomManager = skynet.uniqueservice("roommanager")
	local err = skynet.call(roomManager, "lua", "calllandholder", client_fd, playerId, roomIdx, self.call)
	return {errcode = err}
end

-- 出牌
function REQUEST:followcard()
	if not oPlayer then 
		return {errcode = 4} -- 没玩家
	elseif oPlayer:getRoom() == 0 then 
		return {errcode = 6} -- 没进房间
	elseif oPlayer:getState() == 1 then 
		return {errcode = 12} -- 未准备
	end
	local roomIdx = oPlayer:getRoom()
	local roomManager = skynet.uniqueservice("roommanager")
	local err = skynet.call(roomManager, "lua", "followcard", client_fd, playerId, roomIdx, self.card, self.handtype)
	return {errcode = err}
end

function REQUEST:passfollow()
	if not oPlayer then 
		return {errcode = 4} -- 没玩家
	elseif oPlayer:getRoom() == 0 then 
		return {errcode = 6} -- 没进房间
	elseif oPlayer:getState() == 1 then 
		return {errcode = 12} -- 未准备
	end
	local roomIdx = oPlayer:getRoom()
	local roomManager = skynet.uniqueservice("roommanager")
	local err = skynet.call(roomManager, "lua", "followcard", client_fd, playerId, roomIdx)
	return {errcode = err}
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			local ok, result = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	skynet.fork(function()
		-- while true do
		-- 	send_package(send_request("heartbeat", {servertimer=os.time()}))
		-- 	skynet.sleep(1000)
		-- end
	end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
