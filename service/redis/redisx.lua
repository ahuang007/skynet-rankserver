--- redisx redis服务高级接口
local redisx = {}

local skynet = require 'skynet'
local utils = require "utils"
local tonumber = tonumber
local json = require "cjson"

local REDIS

-- 存储类型
-- 默认存储Lua 表的 json:encode序列化字符串

skynet.init(function ()
    REDIS = skynet.queryservice('redis')
end)

function redisx.del(...)
    return skynet.send(REDIS, 'lua', 'del', ...)
end

--- redis set lua table value
function redisx.setvalue(key, ...)
    return skynet.send(REDIS, 'lua', 'set', key, json.encode(...))
end

--- redis get lua table value
function redisx.getvalue(key)
    local value = skynet.call(REDIS, 'lua', 1, 'get', key)
    return value and json.decode(value) or value
end

function redisx.setstring(key, value)
    return skynet.send(REDIS, 'lua', 'set', key, value)
end

function redisx.getstring(key)
    return skynet.call(REDIS, 'lua', 1, 'get', key)
end

--- redis hset lua table
function redisx.hsettable(key, field, value)
    return skynet.send(REDIS, 'lua', 'hset', key, field, json.encode(value))
end

--- redis hget lua table
function redisx.hgettable(key, field)
    local r = skynet.call(REDIS, 'lua', 1, 'hget', key, field)
    return r and json.decode(r) or r
end

function redisx.hkeys(key)
    return skynet.call(REDIS, 'lua', 1, 'hkeys', key)
end

--- 获取整张表信息(json数据)
function redisx.hgetallobj(key, flag)
    local tmp = skynet.call(REDIS, 'lua', 1, 'hgetall', key)
    local len = #tmp / 2
    local lists = {}
    for i = 1, len do
        local key = tmp[i * 2 -1 ]
        if flag then key = tonumber(key) end
        lists[key] = json.decode(tmp[i * 2])
    end
    return lists
end

-- 获取整张表信息(此接口不做反序列化)
function redisx.hgetallstring(key)
    local tmp = skynet.call(REDIS, 'lua', 1, 'hgetall', key)
    local len = #tmp / 2
    local lists = {}
    for i = 1, len do
        local key = tmp[i * 2 -1 ]
        lists[key] = tmp[i * 2]
    end
    return lists
end

function redisx.hsetstring(key, field, value)
    return skynet.send(REDIS, 'lua', 'hset', key, field, value)
end

function redisx.hgetstring(key, field)
    return skynet.call(REDIS, 'lua', 1, 'hget', key, field)
end

function redisx.setnx(key, value)
    return skynet.call(REDIS, 'lua', 1, 'setnx', key, value) == 1
end

function redisx.hsetnx(key,  field, value)
    return skynet.call(REDIS, 'lua', 1, 'hsetnx', key, field, value) == 1
end

function redisx.incrby(key, increment)
    return tonumber(skynet.call(REDIS, 'lua', 1, 'incrby', key, increment))
end

function redisx.hincrby(key, field, increment)
    return tonumber(skynet.call(REDIS, 'lua', 1, 'hincrby', key, field, increment))
end

function redisx.hdel(...)
    skynet.send(REDIS, "lua", 'hdel', ...)
end

function redisx.zadd(key, score, value)
    skynet.send(REDIS, "lua", "ZADD", key, score, value)
end

--[[
    {
        [1] = value,
        [2] = score,
    }
    or
    {
    }
--]]
function redisx.zall(key)
    return skynet.call(REDIS, "lua", 1, "ZRANGE", key, 0, -1, "WITHSCORES")
end

--[[
    {
        [1] = value,
        [2] = score,
    }
    or
    {
    }
--]]
function redisx.zrevrange(key, last)
    local res = skynet.call(REDIS, "lua", 1, "ZREVRANGE", key, 0, last or -1, "WITHSCORES")
    local len = #res / 2
    local list = {}
    for i = 1, len do
        list[i] = {res[i*2-1], res[i*2]}
    end
    return list
end

--- 批量设置hash key-value(value为lua table)
-- in: redis_key, arr or hash
function redisx.hmsetvalue(key, tb)
    local tmp_arr = {}
    for k, v in pairs(tb) do
        v = json.encode(v)
        table.insert(tmp_arr, k) -- 如果是数组 则k为索引
        table.insert(tmp_arr, v)
    end
    table.insert(tmp_arr, 1, key)
    return skynet.call(REDIS, 'lua', 1, 'hmset', tmp_arr)
end

function redisx.hmset(key, ...)
    return skynet.send(REDIS, 'lua', 'hmset', key, ...)
end

-- 检测key是否存在
function redisx.exists(key)
    local r = skynet.call(REDIS, 'lua', 1, 'exists', key) == 1
    return r == 1 and true or false
end

-- 检测哈希key是否存在
function redisx.hexists(table, key)
    local r = skynet.call(REDIS, 'lua', 1, 'hexists', table, key)
    return r == 1 and true or false
end

return redisx
