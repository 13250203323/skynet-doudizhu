--
-- Author: chenlinhui
-- Date: 2017-10-25 10:34:52
-- Desc: 房间

local skynet = require("skynet")
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"
local makecard = require("makecards")
require("track")

local host = sprotoloader.load(1):host("package")
local send_request = host:attach(sprotoloader.load(2))

-- 房间变量
local CMD = {}
local player = {} -- id集合
local client = {} -- fd集合
local state = {} -- 状态集合：1-未准备，2-准备，3-游戏中
local bRunning = false
local index = 0 -- 房号

-- 游戏进行中变量
local playerCard = {} -- 玩家牌，key：seat
local dizhuCard = {} -- 地主牌

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

-- 分发数据：name-协议名，msg-内容
local function dispatchMessage(fd, name, msg)
	if not bRunning then 
		return 
	end
	skynet.fork(function()
		local pack = send_request(name, msg)
		send_package(fd, pack)
	end)
end

local function startGame()
	print("--------->>开始游戏：", index)
	bRunning = true
	-- 发牌
	dizhuCard, playerCard = makecard.makeCards()
	-- for seat, fd in pairs(client) do
	-- 	dispatchMessage(fd, "handcard", {dizhu = dizhuCard, player = playerCard[seat]})
	-- end

end

local function endGame()
	print("--------->>结束游戏：", index)
	bRunning = false
	playerCard = {}
	dizhuCard {}

end

local function getSeat()
	for i=1, 3 do
		if not player[i] then 
			return i
		end
	end
	error("room error!")
end

local function setState(iState)
	for idx, _ in pairs(state) do
		state[idx] = iState
	end
end

local function checkGameState()
	local nums = table.nums(player)
	if nums == 0 then 
		return 1 -- 没人，将摧毁房间
	elseif nums < 3 then 
		return 2 -- 人不满
	end
	for i=1, 3 do
		if state[i] ~= 2 then 
			return 3 -- 未准备
		end
	end

	return 0 -- 准备开始游戏
end

local function removeSelf()
	local roomManager = skynet.uniqueservice("roommanager")
	skynet.call(roomManager, "lua", "closeRoom", index)
	index = nil 
	skynet.exit()
end

function CMD.create(idx)
	index = idx
end

function CMD.addPlayer(fd, id, idx)
	assert(index == idx, "房间出错")
	print("--------->>加入玩家：", id, idx)
	for seat, client_id in pairs(player) do
		if client_id == id then 
			client[seat] = fd
			return true
		end
	end

	if table.nums(player) >= 3 then 
		return false
	end

	local seat = getSeat()
	player[seat] = id
	client[seat] = fd
	
	return true
end

function CMD.removePlayer(fd, id)
	print("--------->>离开玩家：", id, index)
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
			if not bRunning then 
				local iResult = checkGameState()
				if iResult == 1 then 
					removeSelf()
					return 
				elseif iResult == 0 then
					startGame()
				end
			end
			skynet.sleep(1000)
		end
	end)
end

checkStartGame()