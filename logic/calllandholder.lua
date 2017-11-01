--
-- Author: chenlinhui
-- Date: 2017-10-31 11:55:12
-- Desc: 抢地主逻辑

local mod = {}

local dizhuSeat = 0 -- 地主
local dizhu = {1, 2, 3} -- 地主集合
local firstCall = 0 
local bLastCall = false

local function getNextSeat(seat)
	if table.nums(dizhu) <= 0 then -- 3个都不抢
		return -1 
	elseif firstCall ~= 0 and table.nums(dizhu) == 1 then -- 结束
		return 0
	end
	if bLastCall then 
		return 0
	end
	while true do 
		seat = seat == 3 and 1 or (seat + 1)
		local nextSeat = dizhu[seat]
		bLastCall = firstCall == seat and true or false
		if nextSeat then 
			return nextSeat
		end
	end
end

function mod.callLandHolder(seat, bCall)
	if bCall then 
		firstCall = firstCall == 0 and seat or firstCall -- 记录第一次叫的位置
		dizhuSeat = seat
		local nextSeat = getNextSeat(seat)
		return dizhuSeat, nextSeat
	else
		dizhu[seat] = nil
		local nextSeat = getNextSeat(seat)
		return dizhuSeat, nextSeat
	end
end

-- reset数据
function mod.reset()
	dizhuSeat = 0
	firstCall = 0
	dizhu = {1, 2, 3}
	bLastCall = false
end

return mod 
