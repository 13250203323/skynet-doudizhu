--
-- Author: chenlinhui
-- Date: 2017-09-28 16:47:49
-- Desc: 洗牌

local mod = {}

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

function mod.makeCards()
	-- 初始牌库
	local temp = {}
	for i=1, 54 do
		temp[i] = i
	end

	local function getCrad(num)
		if num <= 0 then 
			return {}
		end
		local result = {}
		local list = {}
		for i=1, num do
			local t, r = getARandomCard(temp)
			temp = t
			local iType = math.ceil(r/13)
			if not result[iType] then 
				result[iType] = {}
			end
			if iType >= 5 then -- "王"
				r = r%13+15
				if not list[r] then
					list[r] = {}
				end
				table.insert(result[iType], r)
				table.insert(list[r], iType)
			else
				r = (r%13<=2 and 13+r%13) or r%13
				if not list[r] then
					list[r] = {}
				end
				table.insert(result[iType], r)
				table.insert(list[r], iType)
			end
		end
		return list
	end

	local lCard_1 = getCrad(3)
	local lCard_2 = getCrad(17)
	local lCard_3 = getCrad(17)
	local lCard_4 = getCrad(17)

	return {lCard_1, lCard_2, lCard_3, lCard_4}
end

--排序
function mod.sortCard(allCard)
	for i,v in ipairs(allCard) do
		for k,p in pairs(v) do
			table.sort(p, function (a, b)
				return a < b
			end)
		end
	end
end
-- dump(makeCards())

-- require("collectcards")
-- collectcard.showMessage()

return mod