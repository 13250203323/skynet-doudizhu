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

-- card：必须为数组
local function getSameTypeCard(card, iType)
	for idx, data in ipairs(card) do
		if data.type == iType then 
			return idx, data
		end
	end
	local data = {type = iType, card = {}}
	return #card+1, data
end

-- 从data_1中移除掉data_2中相同的数据
local function uniqueCard(data_1, data_2)
	for iType, dout in ipairs(data_2) do
		for _, val in ipairs(dout) do
			for idx, iCard in ipairs(data_1[iType]) do
				if val == iCard then 
					table.remove(data_1[iType], idx)
				end
			end
		end
	end
	return data_1
end

-- 检查是否胜利
local function checkisWin(pC)
	for _, data in ipairs(pC) do
		if #data > 0 then 
			return false
		end
	end
	return true
end

-- 单个
handout[HANDOUT_DANGE] = function()

end

-- 对子
handout[HANDOUT_DUIZI] = function()

end

-- 顺子
handout[HANDOUT_SHUNZI] = function()

end

-- 连对
handout[HANDOUT_LIANDUI] = function()

end

-- 三带单
handout[HANDOUT_SANDAI_1] = function()

end

-- 三带一对
handout[HANDOUT_SANDAI_2] = function()

end

-- 飞机带单
handout[HANDOUT_FEIJI_1] = function()

end

-- 飞机带对子
handout[HANDOUT_FEIJI_2] = function()

end

-- 四带二
handout[HANDOUT_SIDAIER] = function()

end

-- 炸弹
handout[HANDOUT_ZHADAN] = function()

end

-- 火箭
handout[HANDOUT_HUOJIAN] = function()

end

function mod.init(playerCard, diCard, dizhuSeat)
	dizhuCard = diCard

	-- 转换格式
	for seat, data in ipairs(playerCard) do
		local card = {}
		for _, dCard in ipairs(data) do
			local iType = dCard.type
			if not card[iType] then 
				card[iType] = {}
			end
			for _, iCard in ipairs(dCard["card"]) do
				table.insert(card[iType], iCard)
			end
			table.sort(card[iType], function(A, B)
				return A < B
			end)
		end		
		allPlayerCard[seat] = card
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
			iType = idx
		end
	end
	assert(iMinCard and iType, "handCardAuto error")
	table.remove(allPlayerCard[seat][iType], 1)
	local isWin = checkisWin(allPlayerCard[seat])
	local result = {[1]={["card"]=iMinCard,["type"]=iType}}
	lastHandOut = {[iType] = {[1]=iMinCard}}
	lastHandOutType = HANDOUT_DANGE
	return result, HANDOUT_DANGE, isWin
end

-- 跟牌
function mod.followCard(seat, card, handType, isFollow)
	local errorcode = handout[handType](card)
	if not isFollow then 
		return errorcode
	end
end

----------------------------------------
-- for test
----------------------------------------
local pCard = {
	[1] = {
		[1] = {
			["card"] = {
				[1] = 13,
				[2] = 4,
				[3] = 5,
			},
			["type"] = 1,
		},
		[2] = {
			["card"] = {
				[1] = 15,
				[2] = 8,
				[3] = 3,
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
print(dump(allPlayerCard))
mod.handCardAuto(1)
print(dump(allPlayerCard))

return mod
