--
-- Author: chenlinhui
-- Date: 2017-10-25 10:21:24
-- Desc: 房间管理

local skynet = require("skynet")
require "skynet.manager"

local room = {}
local CMD = {}

local function checkRoomIdx()
	local index = 0
	while true do 
		if not room[index] then 
			return index
		end
		index = index + 1
	end
end

-- 创建房间
local function createRoom()
	local index = checkRoomIdx()
	local rm = skynet.newservice("room")
	room[index] = rm
	return index, rm
end

-- 进入房间
function CMD.enterRoom(fd, id)
	for idx, rm in pairs(room) do
		-- idx：房间号，rm：房间
		local result = skynet.call(rm, "lua", "addPlayer", fd, id, idx)
		if result then 
			return idx
		end
	end

	local idx, rm = createRoom()
	skynet.call(rm, "lua", "addPlayer", fd, id, idx)

	return idx -- 返回房号
end

-- 退出房间
function CMD.quitRoom(fd, id, idx)
	local rm = room[idx]
	if not rm then 
		return 8
	end	
	skynet.call(rm, "lua", "removePlayer", fd, id)
end

-- 准备，取消准备
function CMD.changeState(fd, id, idx, state)
	local rm = room[idx]
	if not rm then 
		return 8
	end	
	return skynet.call(rm, "lua", "changeState", fd, id, state)
end

-- 关闭房间
function CMD.closeRoom(idx)
	if room[idx] then 
		room[idx] = nil
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(subcmd, ...)))
	end)	

	-- skynet.register "ROOMMANAGER"
end)
