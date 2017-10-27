--
-- Author: lin
-- Date: 2017-10-20 10:53:00
-- Desc: 玩家类

local Player = {}
Player.__index = Player

-- local skynet = require("skynet")
-- local socket = require "skynet.socket"
-- local sprotoloader = require "sprotoloader"

function Player.new(...)
	local obj = {}
	setmetatable(obj, Player)

	obj:init(...)
	return obj
end

function Player:init(fd, id)
	self.fd = fd
	self.id = id
	self.state = 0 -- 0:大厅，1：房间中（未准备），2：房间中（准备），3:游戏中
	self.room = 0 -- 房间号
	-- self.seat = 0 -- 座位号
	-- self.card = {} -- 牌
	-- local host = sprotoloader.load(1):host("package")
	-- self.send_request = host:attach(sprotoloader.load(2))

	-- test
	-- self:sendMessage("heartbeat")
end

function Player:getFD()
	return self.fd
end

function Player:getId()
	return self.id
end

function Player:setRoom(idx)
	self.room = idx
end

function Player:getRoom()
	return self.room
end

function Player:setState(iState)
	self.state = iState
end

function Player:getState()
	return self.state
end

-- local function send_package(self, pack)
-- 	local package = string.pack(">s2", pack)
-- 	socket.write(self.fd, package)
-- end

-- -- 发送消息
-- function Player:sendMessage(name, msg)
-- 	skynet.fork(function()
-- 		-- while true do 
-- 			local pack = self.send_request(name, msg)
-- 			send_package(self, pack)

-- 			-- skynet.sleep(500)
-- 		-- end
-- 	end)
-- end

return Player