package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;doudizhu/?.lua;doudizhu/proto/?.lua;doudizhu/net/?.lua;doudizhu/tools/?.lua;"

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local socket = require "client.socket"
local proto = require "proto"
local sproto = require "sproto"
local errorCode = require "errorcode"
require "track"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))

local fd = assert(socket.connect("127.0.0.1", 8888))

local myAllCard = {}
local netCard = {}

local function changeCardStyle(netcard)
	local card = {}
	for _, data in ipairs(netcard) do
		local iType = data.type
		if not card[iType] then 
			card[iType] = {}
		end
		for _, iCard in ipairs(data["card"]) do
			table.insert(card[iType], iCard)
		end
		table.sort(card[iType], function(A, B)
			return A < B
		end)
	end		
	return card
end

local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
	send_package(fd, str)
	print("Request:", session)
end

local last = ""

local function print_request(name, args)
	print("REQUEST", name)
	if name == "handcard" then  
		print(dump(args))
		myAllCard = changeCardStyle(args.myCard)
		print(dump(myAllCard))
		return 
	end
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
		print(dump(args))
	end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
			if k == "errcode" then 
				if errorCode[v] then 
					print(errorCode[v])
				end
			end
		end
	end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end

		print_package(host:dispatch(v))
	end
end

-- local netCard = {
-- 	[1] = {
-- 		["card"] = {
-- 			[1] = 3,
-- 			[2] = 9,
-- 		},
-- 		["type"] = 5,
-- 	},
-- }
-- netCard
local function checkValue(data)
	netCard = {}
	local result = {}
	for _, sCard in ipairs(data) do
		local iCard = tonumber(sCard)
		for iType, dCard in pairs(myAllCard) do
			if not result[iType] then 
				result[iType] = {["card"]={},["type"]= iType}
			end
			for idx, c in pairs(dCard) do
				if iCard == c then 
					table.insert(result[iType]["card"], iCard)
					table.remove(dCard, idx)
					break
				end
			end
		end
	end
	for _, da in pairs(result) do
		table.insert(netCard, da)
	end
end

while true do
	dispatch_package()
	local cmd = socket.readstdin()
	if cmd then
		if cmd == "quit" then
			send_request("quit")
			socket.close(fd)
			return
		elseif cmd == "1" then 
			send_request("login", {id="123456", passwork="linhui"})
		elseif cmd == "2" then 
			send_request("login", {id="10086", passwork="crazy"})
		elseif cmd == "3" then 
			send_request("login", {id="10010", passwork="3331723"})
		elseif cmd == "4" then 
			send_request("login", {id="misswu", passwork="misswu"})
		elseif cmd == "5" then 
			send_request("login", {id="jean", passwork="jean"})
		elseif cmd == "6" then 
			send_request("login", {id="dabiaoge", passwork="dabiaoge"})
		elseif cmd == "11" then -- 快速开始
			send_request("quickstart")
		elseif cmd == "21" then -- 准备
			send_request("ready")
		elseif cmd == "22" then -- 取消准备
			send_request("cancelready")
		elseif cmd == "12" then -- 取消开始
			send_request("cancelstart")
		elseif cmd == "100" then -- 叫地主
			send_request("calllandholder", {call = true})
		elseif cmd == "101" then -- 不叫
			send_request("calllandholder", {call = false})
		elseif cmd == "999" then -- 不跟
			send_request("passfollow")
		else -- 出牌、跟牌("cp,101,3,4,5,6,7"--"出牌、类型、34567")
			local data = string.lua_string_split(cmd, ",")
			local hType = tonumber(data[2])
			table.remove(data, 1)
			table.remove(data, 2)
			checkValue(data)
			print(dump(netCard))
			print(dump(myAllCard))
			if #netCard ~= 0 then 
				send_request("followcard", {fwcard = netCard, handtype = hType})
			end
		end
	else
		socket.usleep(100)
	end
end

-- HANDOUT_DANGE = 100  		-- 单个
-- HANDOUT_DUIZI = 101  		-- 对子
-- HANDOUT_SANGE = 102  		-- 三个
-- HANDOUT_SHUNZI = 103  		-- 顺子
-- HANDOUT_LIANDUI = 104  		-- 连对
-- HANDOUT_SANDAI_1 = 105  		-- 三带单
-- HANDOUT_SANDAI_2 = 106  		-- 三带对子
-- HANDOUT_FEIJI_1 = 107 		-- 飞机带单
-- HANDOUT_FEIJI_2 = 108  		-- 飞机带对子
-- HANDOUT_SIDAIER = 108  		-- 四带二
-- HANDOUT_ZHADAN = 110 		-- 炸弹
-- HANDOUT_HUOJIAN = 111  		-- 火箭