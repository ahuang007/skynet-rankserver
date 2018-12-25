
local constant = require 'constant'
local utils = require 'utils'
local json = require "json"
local md5 = require "md5"
local app_config = require "app_config"

local M = {}

local function commitdata_check(method, decode_data)
    local keys = {
        "uid",          -- uid
        "name",     -- 物品类型
        "headIcon",        -- 数值（物品为配置id 属性为数值）
        "score",
    }

    for _,v in pairs(keys) do
        if not decode_data[v] then
            return {false, '缺少参数'}
        end
    end

    return {true, constant.REQ_TYPE.RT_COMMITDATA, decode_data}
end

local function getranklist_check(method, decode_data)
    local keys = {
        "uid",
        "startindex",
        "endindex",
    }
    for _,v in pairs(keys) do
        if not decode_data[v] then
            return {false, '缺少参数'}
        end
    end

    return {true, constant.REQ_TYPE.RT_GETRANKLIST, decode_data}
end

local function clearranklist_check(method, decode_data)
    local keys = {
    }
    for _,v in pairs(keys) do
        if not decode_data[v] then
            return {false, '缺少参数'}
        end
    end
    return {true, constant.REQ_TYPE.ClearRankList, decode_data}
end

local function decode_func(c)
    return string.char(tonumber(c, 16))
end

local function decode(str)
    local str = str:gsub('+', ' ')
    return str:gsub("%%(..)", decode_func)
end

--校验参数
M.verify_data = function (method, res)
    local gmcmd = {
        CommitData      = commitdata_check(),
        GetRankList     = getranklist_check(),
        ClearRankList   = clearranklist_check(),
    }

    if not res.cmd or not gmcmd[res.cmd] then
        return {false, '没有找到对应的命令'}
    end
    return gmcmd[res.cmd](method, res.decode_data)
end

--校验签名
M.verify_sign = function(appid, res)
    local appkey = app_config[appid]
    if not appkey then
        return false
    end

    if not res or not res.sign or not res.data then
        return false
    end

    return  md5.sumhexa(res.data .. appkey) == res.sign
end

-- 解析数据
M.parse = function (query, body)
    local res = {}

    for k,v in pairs(query) do
        res[k] = v
    end

    if body then
        local t = utils.split(body, '&')
        for i=1,#t do
            local k2v = utils.split(t[i], '=')
            if #k2v == 2 then
                res[k2v[1]] = decode(k2v[2])
            end
        end
    end

    local function checkParams(tab)
        if not tab or type(tab) ~= "table" then
            return
        end

        for k,v in pairs(tab) do
            if type(v) == "function" then
                tab[k] = nil
            elseif type(v) == "table" then
                checkParams(v)
            end
        end
    end

    if res.data then
        res.decode_data = json.decode(res.data)
        checkParams(res.decode_data)
    end
    return res
end

return M