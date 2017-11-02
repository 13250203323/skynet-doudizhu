--
-- Author: chenlinhui
-- Date: 2017-11-02 10:06:42
-- Desc: 出牌

require("track")
require("define")
local mod = {}

local playerCard_1 = {} -- seat:1
local playerCard_2 = {} -- seat:2
local playerCard_3 = {} -- seat:3
local dizhuCard = {} -- 地主牌

-- HANDOUT_DANGE = 100  		-- 单个
-- HANDOUT_DUIZI = 101  		-- 对子
-- HANDOUT_SHUNZI = 102  		-- 顺子
-- HANDOUT_LIANDUI = 103  		-- 连对
-- HANDOUT_SANDAI_1 = 104  	-- 三带单
-- HANDOUT_SANDAI_2 = 105  	-- 三带对子
-- HANDOUT_FEIJI_1 = 106 		-- 飞机带单
-- HANDOUT_FEIJI_2 = 107  		-- 飞机带对子
-- HANDOUT_SIDAIER = 108  		-- 四带二
-- HANDOUT_ZHADAN = 109 		-- 炸弹
-- HANDOUT_HUOJIAN = 110  		-- 火箭

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

-- 合并类型相同的数组，data_2合并到data_1
local function combineCard(data_1, data_2)
	assert(data_1.type == data_2.type, "合并类型出错!")
	for _, iCard in pairs(data_2.card) do
		table.insert(data_1.card, iCard)
	end
	return data_1
end

function mod.init(playerCard, diCard, dizhuSeat)
	dizhuCard = diCard
	for _, data in pairs(diCard) do
		local iType = data.type
		local index, data_1 = getSameTypeCard(playerCard[dizhuSeat], iType)
		local result = combineCard(data_1, data)
		playerCard[dizhuSeat][index] = result
	end
	playerCard_1 = playerCard[1]
	playerCard_2 = playerCard[2]
	playerCard_3 = playerCard[3]
end

function mod.reset()
	playerCard_1 = {}
	playerCard_2 = {}
	playerCard_3 = {}
	dizhuCard = {}
end

----------------------------------------
-- for test
----------------------------------------
local pCard = {
	[1] = {
		[1] = {
			["card"] = {
				[1] = 3,
				[2] = 4,
				[3] = 5,
			},
			["type"] = 1,
		},
		[2] = {
			["card"] = {
				[1] = 5,
				[2] = 8,
				[3] = 10,
			},
			["type"] = 2,
		},
		[3] = {
			["card"] = {
				[1] = 13,
				[2] = 14,
				[3] = 15,
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
print(dump(playerCard_1))

return mod
