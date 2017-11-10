-- c2s协议
-- 在此添加客户端到服务端的协议

local c2s = [[
.package {
    type 0 : integer
    session 1 : integer
}

quit 1 {}

login 2 {
    request {
        id 0 : string
        passwork 1 : string
    }
    response {
        errcode 0 : integer
    }
}

quickstart 3 {
    response {
        errcode 0 : integer
        waittime 1 : integer
    }
}

ready 4 {
    response {
        errcode 0 : integer
    }    
}

cancelready 5 {
    response {
        errcode 0 : integer
    }      
}

cancelstart 6 {
    response {
        errcode 0 : integer
    }
}

calllandholder 7 {
    request {
        call 0 : boolean
    }
    response {
        errcode 0 : integer
    }
}

.card {
    card 0 : *integer
    type 1 : integer
}

followcard 8 {
    request {
        fwcard 0 : *card
        handtype 1 : integer    
    }
    response {
        errcode 0 : integer
    }
}

passfollow 9 {
    request {
    }
    response {
        errcode 0 : integer
    }
}

]]

--[[
1-quickstart：快速开始
2-ready：准备
3-cancelready：取消准备
4-cancelstart：取消开始
5-calllandholder：是否叫地主或者抢地主
6-followcard：出牌，handtype-出牌类型
7-passfollow：不跟
]]
return c2s