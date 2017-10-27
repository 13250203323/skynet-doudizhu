-- s2c协议
-- 在此添加服务端到客户端的协议

local s2c = [[
.package {
    type 0 : integer
    session 1 : integer
}

heartbeat 1 {}


]]

-- .person {
--     name 0 : string
--     id 1 : integer
    
--     .phoneNumber {
--         number 0: string
--     }

--     phone 3 : *phoneNumber
-- }

-- login 2 {
--     request person
-- }

return s2c