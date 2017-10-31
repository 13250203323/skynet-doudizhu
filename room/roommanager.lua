--
-- Author: chenlinhui
-- Date: 2017-10-25 10:21:24
-- Desc: 房间管理

local skynet = require("skynet")
require "skynet.manager"

local room = {}
local CMD = {}

local function checkRoomIdx()
	local index = 1
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
	print("++++++++++创建房间：", index)
	local result = skynet.call(rm, "lua", "create", index)
	return index, rm
end

-- 进入房间
function CMD.enterRoom(fd, id)
	print("++++++++++进入房间：", id)
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
	print("++++++++++退出房间：", id)
	return skynet.call(rm, "lua", "removePlayer", fd, id)
end

-- 准备，取消准备
function CMD.changeState(fd, id, idx, state)
	local rm = room[idx]
	if not rm then 
		return 8
	end	
	print("++++++++++准备，取消准备：", id, state)
	return skynet.call(rm, "lua", "changeState", fd, id, state)
end

-- 关闭房间
function CMD.closeRoom(idx)
	print("++++++++++关闭房间：", idx)
	if room[idx] then 
		room[idx] = nil
	end
end

-- 叫地主或者抢地主
function CMD.calllandholder(fd, id, idx, bCall)
	local rm = room[idx]
	if not rm then 
		return 8
	end	
	print("++++++++++叫地主或抢地主：", id, bCall)
	return skynet.call(rm, "lua", "calllandholder", fd, id, bCall)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(subcmd, ...)))
	end)	

	-- skynet.register "ROOMMANAGER"
end)
