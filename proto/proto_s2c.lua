-- s2c协议
-- 在此添加服务端到客户端的协议

local s2c = [[
.package {
    type 0 : integer
    session 1 : integer
}

heartbeat 1 {
	request {
		servertimer 0 : integer
	}
}

.card {
	card 0 : *integer
	type 1 : integer
}

handcard 2 {
	request {
		myCard 1 : *card
		otherplayer_1 2 : integer
		otherplayer_2 3 : integer
	}
}

callpriority 3 {
	request {
		priority 0 : integer
		time 1 : integer
	}
}

callholder 4 {
	request {
		result 0 : boolean
		nextcall 1 : integer
	}
}

landholder 5 {
	request {
		dizhu 0 : *card
		landholder 0 : integer
	}
}

followcard 6 {
    request {
        card 0 : *card
        handtype 1 : integer    
        seat 2 : integer
    }
}

passfollow 7 {
	request {
		seat 0 : integer
	}
}

handoutpriority 8 {
	request {
		priority 0 : integer
		time 1 : integer
	}
}

gameover 9 {
	request {
		win 0 : integer
	}
}

]]

--[[
1-handcard：发牌
2-callpriority：叫地主或者抢地主权利
3-followcard：出牌，handtype-出牌类型，seat-座位
4-passfollow：不跟
]]

return s2c