--
-- Author: lin
-- Date: 2017-10-20 10:53:00
-- Desc: 玩家类

local Player = {}
Player.__index = Player

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

return Player