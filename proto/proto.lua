local sprotoparser = require "sprotoparser"
local c2s = require("proto_c2s")
local s2c = require("proto_s2c")

local proto = {}

-- 解析协议
proto.t_c2s = sprotoparser.parsefortab(c2s) 
proto.t_s2c = sprotoparser.parsefortab(s2c) 

-- 注册协议
proto.c2s = sprotoparser.parse_(proto.t_c2s) 
proto.s2c = sprotoparser.parse_(proto.t_s2c) 

return proto