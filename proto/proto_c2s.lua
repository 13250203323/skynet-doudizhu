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

readystart 4 {
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


]]

-- .person {
--     name 0 : string
--     id 1 : integer
    
--     .phoneNumber {
--         number 0: string
--     }

--     phone 3 : *phoneNumber
-- }

-- login 4 {
--     request person
-- }

return c2s