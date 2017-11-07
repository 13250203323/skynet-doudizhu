--
-- Author: chenlinhui
-- Date: 2017-11-02 10:06:42
-- Desc: 出牌

require("track")
require("define")
local mod = {}
local handout = {}

local allPlayerCard = {} -- 玩家牌{seat:{type:{icard}}}
local dizhuCard = {} -- 地主牌
local lastHandOut = {} -- 上一手打的牌
local lastHandOutType = 0 -- 上一手打的牌类型

-- 从data_1中移除掉data_2中相同的数据
-- local function uniqueCard(data_1, data_2)
-- 	for iType, dout in pairs(data_2) do
-- 		for _, val in ipairs(dout) do
-- 			assert(data_1[iType], "牌型出错")
-- 			for idx, iCard in ipairs(data_1[iType]) do
-- 				if val == iCard then 
-- 					table.remove(data_1[iType], idx)
-- 				end
-- 			end
-- 		end
-- 	end
-- 	return data_1
-- end

-- 检查是否胜利
local function checkisWin(pC)
	for _, data in ipairs(pC) do
		if #data > 0 then 
			return false
		end
	end
	return true
end

-- 转换格式
-- 协议格式->类型格式({[type]={}})
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

-- 检测data_1中有没有data_2的卡牌
local function checkCard(data_1, data_2)
	for iType, dout in pairs(data_2) do
		for _, iCard in ipairs(dout) do
			local bHas = false
			for _, v in ipairs(data_1[iType] or {}) do
				if iCard == v then 
					bHas = true
					break
				end
			end
			if not bHas then return 101 end
		end
	end
	return 0
end

-- return: allNums, {[icard]=nums}
local function getCardAttr_1(card)
	local result = {}
	local nums = 0
	for _, data in pairs(card) do
		nums = nums + #data
		for _, iCard in pairs(data) do
			result[iCard] = (result[iCard] or 0) + 1
		end
	end
	return nums, result
end

-- return: {icard}
local function getCardAttr_2(card)
	local result = {}
	for _, data in pairs(card) do
		for _, iCard in pairs(data) do
			result[#result+1] = iCard
		end
	end
	table.sort(result, function(A, B)
		return A < B
	end)
	return result
end

-- 单个，对子，三个
local function check_123(card, seat, isHandOut, iType)
	local nums, resultCard_1 = getCardAttr_1(card)
	local _, resultCard_2 = getCardAttr_1(lastHandOut)
	if nums ~= iType then 
		return 100
	elseif not table.keyof(resultCard_1, iType) then 
		return 100
	end
	local errorcode = checkCard(allPlayerCard[seat], card)
	if isHandOut or errorcode ~= 0 then 
		return errorcode 
	end 
	-- 检查大小 
	for p, q in pairs(resultCard_1) do
		for x, y in pairs(resultCard_2) do
			if p <= x or q ~= y then 
				return 100
			end
		end
	end
	return 0
end

-- 单个
handout[HANDOUT_DANGE] = function(seat, card, isHandOut)
	if not isHandOut and lastHandOutType ~= HANDOUT_DANGE then return 100 end
	return check_123(card, seat, isHandOut, 1)
end

-- 对子
handout[HANDOUT_DUIZI] = function(seat, card, isHandOut)
	if not isHandOut and lastHandOutType ~= HANDOUT_DUIZI then return 100 end
	return check_123(card, seat, isHandOut, 2)
end

-- 三个
handout[HANDOUT_SANGE] = function(seat, card, isHandOut)
	if not isHandOut and lastHandOutType ~= HANDOUT_SANGE then return 100 end
	return check_123(card, seat, isHandOut, 3)
end

-- 顺子
handout[HANDOUT_SHUNZI] = function(seat, card, isHandOut)
	if not isHandOut and lastHandOutType ~= HANDOUT_SHUNZI then return 100 end
	local resultCard = getCardAttr_2(card)
	if #resultCard < 5 then return 100 end

	-- 检查是不是顺子
	for i=1, #resultCard do
		local p = resultCard[i]
		local q = resultCard[i+1]
		if not q then 
			break
		end
		if (q ~= p + 1) or (p >= 15 or q >= 15) then -- "2"以上不能做顺子
			return 100
		end
	end
	
	local errorcode = checkCard(allPlayerCard[seat], card)
	if isHandOut or errorcode ~= 0 then 
		return errorcode 
	end 

	local lastResultCard = getCardAttr_2(lastHandOut)
	if #resultCard ~= #lastResultCard then return 100 end

	-- 判断是否大于上一手
	if resultCard[1] <= lastResultCard[1] then return 100 end 
	return errorcode
end

-- 连对
handout[HANDOUT_LIANDUI] = function(seat, card, isHandOut)
	if not isHandOut and lastHandOutType ~= HANDOUT_LIANDUI then return 100 end
	local nums_1, resultCard_1 = getCardAttr_1(card)
	if nums_1 < 6 then return 100 end

	for _, num in pairs(resultCard_1) do
		if num ~= 2 then return 100 end
	end
	local resultCard_3 = getCardAttr_2(card)
	local resultCard_4 = getCardAttr_2(lastHandOut)
	-- 检查是不是顺
	for i=1, #resultCard_3 do
		local p = resultCard_3[i]
		local q = resultCard_3[i+2]
		if not q then 
			break
		end
		if (q ~= p + 1) or (p >= 15 or q >= 15) then -- "2"以上不能做顺
			return 100
		end
	end	
	local errorcode = checkCard(allPlayerCard[seat], card)
	if isHandOut or errorcode ~= 0 then 
		return errorcode 
	end 

	local nums_2, _ = getCardAttr_1(lastHandOut)
	if nums_1 ~= nums_2 then return 100 end

	if resultCard_3[1] <= resultCard_4[1] then return 100 end 
	return errorcode
end

-- 三带单
handout[HANDOUT_SANDAI_1] = function(seat, card, isHandOut)
	if not isHandOut and lastHandOutType ~= HANDOUT_SANDAI_1 then return 100 end
	local nums_1, resultCard_1 = getCardAttr_1(card)
	if nums_1 ~= 4 then return 100 end


end

-- 三带一对
handout[HANDOUT_SANDAI_2] = function(seat, card, isHandOut)
	if not isHandOut and lastHandOutType ~= HANDOUT_SANDAI_2 then return 100 end

end

-- 飞机带单
handout[HANDOUT_FEIJI_1] = function(seat, card, isHandOut)

end

-- 飞机带对子
handout[HANDOUT_FEIJI_2] = function(seat, card, isHandOut)

end

-- 四带二
handout[HANDOUT_SIDAIER] = function(seat, card, isHandOut)

end

-- 炸弹
handout[HANDOUT_ZHADAN] = function(seat, card, isHandOut)

end

-- 火箭
handout[HANDOUT_HUOJIAN] = function(seat, card, isHandOut)

end

function mod.init(playerCard, diCard, dizhuSeat)
	dizhuCard = diCard

	-- 转换格式
	for seat, data in ipairs(playerCard) do
		allPlayerCard[seat] = changeCardStyle(data)
	end

	-- 合并地主牌
	for _, data in ipairs(diCard) do
		local iType = data.type
		local card = allPlayerCard[dizhuSeat][iType] or {}
		for _, iCard in ipairs(data["card"]) do
			table.insert(card, iCard)
		end
		table.sort(card, function(A, B)
			return A < B
		end)
		allPlayerCard[dizhuSeat][iType] = card
	end
end

function mod.reset()
	allPlayerCard = {}
	dizhuCard = {}
	lastHandOut = {}
	lastHandOutType = 0
end

-- 下一出牌玩家
function mod.getNexSeat(seat)
	seat = seat == 3 and 1 or (seat + 1)
	return seat
end

-- 自动选一个单牌出
function mod.handCardAuto(seat)
	local card = allPlayerCard[seat]
	local iMinCard, iType, index_1, index_2
	for idx, data in ipairs(card) do
		if not iMinCard or iMinCard > data[1] then 
			iMinCard = data[1]
			iType = data.type
		end
	end
	assert(iMinCard and iType, "handCardAuto error")
	table.remove(allPlayerCard[seat][iType], 1)
	local isWin = checkisWin(allPlayerCard[seat])
	local result = {[1]={["flowcard"]={iMinCard},["type"]=iType}}
	local nums = getCardNums(allPlayerCard[seat])
	lastHandOut = {[iType] = {iMinCard}}
	lastHandOutType = HANDOUT_DANGE
	return result, HANDOUT_DANGE, nums, isWin
end

-- 跟牌
-- card：协议格式
function mod.followCard(seat, netCard, handType, isHandOut)
	local card = changeCardStyle(netCard)
	print(">>>>>>>>>出牌，类型：", handType)
	local errorcode = handout[handType](seat, card, isHandOut)
	lastHandOut = errorcode == 0 and card or lastHandOut
	lastHandOutType = errorcode == 0 and handType or lastHandOutType
	return errorcode
end

----------------------------------------
-- for test
----------------------------------------
local pCard = {
	[1] = {
		[1] = {
			["card"] = {
				[1] = 4,
				[2] = 5,
				[3] = 6,
				[4] = 7,
			},
			["type"] = 1,
		},	
		[2] = {
			["card"] = {
				[1] = 4,
				[2] = 5,
				[3] = 6,
				[4] = 7,
			},
			["type"] = 2,
		},
		[3] = {
			["card"] = {
				[1] = 15,
				[2] = 14,
				[3] = 7,
			},
			["type"] = 3,
		},
	},
}

local dizhu = {
	[1] = {
		["card"] = {
			[1] = 8,
			[2] = 9,
		},
		["type"] = 1,
	},
	[2] = {
		["card"] = {
			[1] = 16,
		},
		["type"] = 5,
	},
}

mod.init(pCard, dizhu, 1)
-- print(dump(allPlayerCard))
-- mod.handCardAuto(1)
-- print(dump(allPlayerCard))

local netCard = {
	[1] = {
		["card"] = {
			[1] = 4,
			[2] = 5,
			[3] = 6,
			[4] = 7,
		},
		["type"] = 1,
	},	
	[2] = {
		["card"] = {
			[1] = 4,
			[2] = 5,
			[3] = 6,
			[4] = 7,
		},
		["type"] = 2,
	},
	-- [3] = {
	-- 	["card"] = {
	-- 		[1] = 7,
	-- 	},
	-- 	["type"] = 3,
	-- },
}

-- local handType = HANDOUT_LIANDUI
-- local isHandOut = false
-- lastHandOutType = HANDOUT_LIANDUI 
-- lastHandOut = {
-- 	[1] = {3,4,5,6},
-- 	[2] = {3,4,5,6},
-- }

-- local errorcode = mod.followCard(1, netCard, handType, isHandOut)
-- print(">>>>>>>>>>>>>>>>>>", errorcode)

return mod
