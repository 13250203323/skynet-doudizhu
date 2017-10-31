--
-- Author: chenlinhui
-- Date: 2017-10-25 10:34:52
-- Desc: 房间

local skynet = require("skynet")
local socket = require "skynet.socket"
local sprotoloader = require "sprotoloader"
local makecard = require("makecards")
local callHolder = require("calllandholder")
require("track")

local host = sprotoloader.load(1):host("package")
local send_request = host:attach(sprotoloader.load(2))

local startGame
local endGame
local setState

-- 房间变量
local CMD = {}
local player = {} -- id集合
local client = {} -- fd集合
local state = {} -- 状态集合：1-未准备，2-准备，3-游戏中
local bRunning = false
local index = 0 -- 房号
local isNew = true -- 是否新建

-- 游戏进行中变量
local playerCard = {} -- 玩家牌，key：seat
local dizhuCard = {} -- 地主牌

-- 抢地主相关变量
local callpriority = 0 -- 当前抢地主的权利
local dizhuSeat = 0 -- 地主

------------------------------------------
-- 分发数据相关：start
------------------------------------------
local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.write(fd, package)
end

-- 分发数据：name-协议名，msg-内容
local function dispatchMessage(fd, name, msg)
	if not bRunning then 
		return 
	end
	local pack = send_request(name, msg)
	send_package(fd, pack)
end

local function dispatchAllPlayer(name, msg)
	for seat, fd in pairs(client) do
		dispatchMessage(fd, name, msg)
	end
end
------------------------------------------
-- 分发数据相关：end
------------------------------------------

------------------------------------------
-- 游戏主体逻辑：start
------------------------------------------
-- 发牌
local function handOutCard()
	dizhuCard, playerCard = makecard.makeCards()
	print("<<<<<<<<<<<<<<发牌")
	print(dump(dizhuCard))
	skynet.fork(function()
		for seat, fd in pairs(client) do
			dispatchMessage(fd, "handcard", {dizhu = dizhuCard, myCard = playerCard[seat], 
				otherplayer_1 = 13, otherplayer_2 = 13})
		end
	end)
end

-- 抢地主逻辑
local function callLandHolder(seat, bCall)
	assert(seat == callpriority, "位置出错")
	dizhuSeat, callpriority = callHolder.callLandHolder(seat, bCall)
	dispatchAllPlayer("callholder", {result = bCall, nextcall = callpriority})
	if callpriority == 0 then -- 抢地主结束
		return 
	end
	local endTime = os.time()+20
	dispatchAllPlayer("callpriority", {priority = callpriority, time = endTime})
	checkLandHolder(endTime, callpriority)
end

-- 检测抢地主（时间限制内没回协议默认不抢）
local function checkLandHolder(endTime, seat)
	skynet.fork(function()
		while true do
			if seat ~= callpriority then 
				return 
			end 
			if os.time() >= endTime then 
				callLandHolder(seat, false)
				return 
			end
			skynet.sleep(500)
		end
	end)
end 
------------------------------------------
-- 游戏主体逻辑：end
------------------------------------------

function startGame()
	print("--------->>开始游戏：", index)
	bRunning = true
	setState(3)
	-- 发牌
	handOutCard()
	-- 选地主
	skynet.fork(function()
		skynet.sleep(1000)
		local ran = math.random(1,3)
		callpriority = ran
		local endTime = os.time()+20
		dispatchAllPlayer("callpriority", {priority = ran, time = endTime})
		checkLandHolder(endTime, callpriority)
	end)

end
 
function endGame()
	print("--------->>结束游戏：", index)
	bRunning = false
	playerCard = {}
	dizhuCard = {}
	dizhuSeat = 0
	setState(1)
	callHolder.reset()
end

local function getSeatById(id)
	for seat, v in pairs(player) do
		if v == id then 
			return seat
		end
	end
end

local function getSeat()
	for i=1, 3 do
		if not player[i] then 
			return i
		end
	end
	error("room error!")
end

function setState(iState)
	for idx, _ in pairs(state) do
		state[idx] = iState
	end
end

local function checkGameState()
	if bRunning then 
		return 4 -- 游戏中
	end
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
	isNew = true
end

function CMD.addPlayer(fd, id, idx)
	assert(index == idx, "房间出错", index, idx)
	print("--------->>加入玩家：", id, idx)
	for seat, client_id in pairs(player) do
		if client_id == id then 
			client[seat] = fd
			if bRunning then -- 在游戏中，发送相关信息
				dispatchMessage(fd, "handcard", {dizhu = dizhuCard, myCard = playerCard[seat], 
					otherplayer_1 = 13, otherplayer_2 = 13})
			end
			return true
		end
	end

	if table.nums(player) >= 3 then 
		return false
	end

	local seat = getSeat()
	player[seat] = id
	client[seat] = fd

	isNew = false	
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
			return 0
		end
	end
	error("player not found!")
end

function CMD.changeState(fd, id, iState)
	if bRunning then 
		print("--------->>游戏中")
		return 11
	end
	for seat, client_id in pairs(player) do
		if id == client_id then 
			state[seat] = iState
			return 0
		end
	end
	return 9 -- 没有该玩家
end

function CMD.calllandholder(fd, id, bCall)
	if not bRunning then 
		return 13
	end
	local seat = getSeatById(id)
	if callpriority ~= seat then 
		return 14
	end
	callLandHolder(seat, bCall)
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
				if iResult == 1 and not isNew then 
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