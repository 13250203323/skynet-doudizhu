--
-- Author: chenlinhui
-- Date: 2017-09-28 16:47:49
-- Desc: 洗牌

local mod = {}

require("track")
require("define")
math.randomseed(tostring(os.time()):reverse():sub(1, 6))  

local function getARandomCard(lCard)
	local num = #lCard 
	if num <= 0 then
		return {}
	end
	local iRan = math.random(1, num)
	local result = lCard[iRan]
	table.remove(lCard, iRan)
	return lCard, result
end

local function makeCards()
	-- 初始牌库
	local temp = {}
	for i=1, 54 do
		temp[i] = i
	end

	local function getCrad(num)
		if num <= 0 then 
			return {}
		end
		local result = {
			[CARD_HONGTAO] = {type = CARD_HONGTAO, card = {}},
			[CARD_HEITAO] = {type = CARD_HEITAO, card = {}},
			[CARD_MEIHUA] = {type = CARD_MEIHUA, card = {}},
			[CARD_FANGKUAI] = {type = CARD_FANGKUAI, card = {}},
			[CARD_JOKER] = {type = CARD_JOKER, card = {}},
		} 
		for i=1, num do
			local t, r = getARandomCard(temp)
			temp = t
			local iType = math.ceil(r/13)
			if iType >= 5 then -- "王"
				r = r%13+15
				table.insert(result[iType]["card"], r)
			else
				r = (r%13<=2 and 13+r%13) or r%13
				table.insert(result[iType]["card"], r)
			end
		end

		local sortResult = {}
		for _, data in ipairs(result) do
			if #data["card"] > 0 then 
				table.insert(sortResult, data)
			end 
		end

		return sortResult
	end

	local lCard_1 = getCrad(3)
	local lCard_2 = getCrad(17)
	local lCard_3 = getCrad(17)
	local lCard_4 = getCrad(17)

	return lCard_1, {lCard_2, lCard_3, lCard_4}
end

mod.makeCards = makeCards

-- local c1, c2 = makeCards()
-- print(dump(c2))

return mod