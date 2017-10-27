--
-- Author: chenlinhui
-- Date: 2017-10-25 10:34:52
-- Desc: 房间

local skynet = require("skynet")
require("track")

local CMD = {}
local player = {} -- id集合
local client = {} -- fd集合
local state = {} -- 状态集合：1-未准备，2-准备，3-游戏中
local bRunning = false
local index = 0 -- 房号

-- 分发数据：name-协议名，msg-内容
local function dispatchMessage(name, msg)
	if not bRunning then 
		return 
	end
	for _, fd in pairs(client) do

	end
end

local function startGame()
	bRunning = true

end

local function endGame()
	bRunning = false

end

local function getSeat()
	for i=1, 3 do
		if not player[i] then 
			return i
		end
	end
	error("room error!")
end

function CMD.addPlayer(fd, id, idx)
	for seat, client_id in pairs(player) do
		if client_id == id then 
			client[seat] = fd
			return true
		end
	end

	if table.nums(player) >= 3 then 
		return false
	end

	index = idx
	local seat = getSeat()
	player[seat] = id
	client[seat] = fd
	
	return true
end

function CMD.removePlayer(fd, id)
	for seat, client_id in pairs(player) do
		if id == client_id then 
			client[seat] = nil
			if not bRunning then -- 游戏中不清空player，用于断线重连
				player[seat] = nil
			end
			return true
		end
	end
	error("player not found!")
end

function CMD.changeState(fd, id, iState)
	for seat, client_id in pairs(player) do
		if id == client_id then 
			state[seat] = iState
			return 0
		end
	end
	return 9 -- 没有该玩家
end

-- function CMD.getPlayers()
-- 	return table.nums(player)
-- end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(subcmd, ...)))
	end)	
end)

-- 检测房间是否可以开始游戏
local function checkStartGame()
	skynet.fork(function()
		while true do
			-- local iResult = checkInGame() 
			-- if iResult == 1 then 
			-- 	skynet.call(RoomManager, "lua", "closeRoom", index)
			-- 	skynet.exit()
			-- 	return 
			-- elseif iResult == 4 then
			-- 	startGame()
			-- end
			skynet.sleep(1000)
		end
	end)
end

checkStartGame()