--
-- Author: chenlinhui
-- Date: 2017-10-31 11:55:12
-- Desc: 抢地主逻辑

local mod = {}

local callpriority = 0 -- 当前抢地主的权利
local dizhuSeat = 0 -- 地主
local dizhu = {1, 2, 3} -- 地主集合
local time = 4

local function getNextSeat(seat)
	if time == 0 then 
		return 0
	end
	while true then 
		local seat = seat == 3 and 1 or (seat + 1)
		if dizhu[seat] then 
			return dizhu[seat]
		end
	end
end

function mod.callLandHolder(seat, bCall)
	if callpriority == 0 then -- 0代表叫地主
		if bCall then 
			dizhuSeat = seat
			time = time - 1
		else
			dizhu[seat] = nil
			time = time - 2
		end
		local nextSeat = getNextSeat(seat)
		return dizhuSeat, nextSeat
	else
		if bCall then 
			dizhuSeat = seat
		else
			dizhu[seat] = nil
		end
		time = time - 1
		local nextSeat = getNextSeat(seat)
		return dizhuSeat, nextSeat
	end
end

-- reset数据
function mod.reset()
	callpriority = 0 
	dizhuSeat = 0
	dizhu = {1, 2, 3}
	time = 4
end

return mod 
