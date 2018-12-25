
--- rank_agent服务

local skynet    = require "skynet"
local utils     = require "utils"
local inspect   = require "inspect"
local cs        = require 'skynet.queue'
local settings  = require "settings"
local constant  = require "constant"
local zset      = require "zset"
require "logger_api"
local redisx    = require 'redisx'
local json      = require "cjson"

local NO_RETURN = {}
local CMD = {}

local appid     = ...
local db_name = "rank_" .. appid
local ranklist
local datas

local inspect = require 'inspect'
skynet.info_func(function (cmd, ...)
    return inspect {
        datas = datas,
    }
end)

local function loadAll()
    ranklist = zset.new()
    datas = redisx.hgetallobj(db_name, true) -- datas的key为number
    for _, v in pairs(datas) do
        --TRACE("loadAll ", v.score, v.uid)
        ranklist:add(tonumber(v.score), tostring(v.uid))
    end
end

function CMD.start()
    loadAll()
end

local function commit(uid, userdata)
    local score = tonumber(userdata.score)
    local rankScore = ranklist:score(tostring(uid)) or 0
    if score > rankScore then
        ranklist:rem(tostring(uid))
        ranklist:add(score, tostring(uid))
        redisx.hsettable(db_name, uid, userdata)
        datas[uid] = userdata
    end
end

--- 提交排行数据
--[[
 data:请求参数(json数据）
    uid: 玩家id
    name: 玩家名
    headIcon: 玩家头像url
    score: 玩家分数
--]]
function CMD.CommitData(data)
    local data = json.decode(data)
    TRACE("CommitData ...", appid, data.uid, data.name, data.headIcon, data.score)
    local uid = data.uid
    local userdata = {
        uid         = data.uid,
        name        = data.name,
        headIcon    = data.headIcon,
        score       = data.score,
    }
    cs(commit(uid, userdata))
    return true
end

-- 获取单个玩家的名次和分数
function CMD.GetRankInfo(uid)
    local rank = ranklist:rev_rank(tostring(uid)) or 0
    local score = ranklist:score(tostring(uid)) or 0
    return rank, score
end

--- 获取排行榜
--[[
data:请求参数(json数据）
    uid: 玩家id
    startindex:排行榜开始下标
    endindex:排行榜结束下标（两者之差不能大于100）
--]]
function CMD.GetRankList(data)
    local data = json.decode(data)
    local uid = tonumber(data.uid)
    TRACE("GetRankList ... ", appid, uid, data.startindex, data.endindex)
    local lists = {}
    local startindex = tonumber(data.startindex)
    local endindex = tonumber(data.endindex)
    if endindex <= startindex or endindex > startindex + 100 then
        ERR("GetRankList ERROR 1", startindex, endindex)
        return false, constant.ERRORCODE.params_failed;
    end

    if startindex > ranklist:count() then
        return true, {}, {}
    end

    local inrank = false
    local count = startindex
    for _, v in ipairs(ranklist:rev_range(startindex, endindex)) do
        if tonumber(v) == uid then
            inrank = true
        end

        local userdata = datas[tonumber(v)]
        local item = {
            rankd       = count,
            uid         = tonumber(v),
            score       = ranklist:score(tostring(v)),
            name        = userdata.name,
            headIcon    = userdata.headIcon,
        }
        table.insert(lists, item)
        count = count + 1
    end

    if (uid and uid ~= 0) and (not inrank) then
        local rank, score = CMD.GetRankInfo(uid)
        if rank > 0 then
            local myinfo = {
                rank        = rank,
                uid         = uid,
                name        = datas[uid].name,
                headIcon    = data.headIcon,
                score       = score,
            }
            table.insert(lists, myinfo)
        end
    end
    return true, {}, lists
end

local function ClearRankList()
    TRACE("ClearRankList begin ...")
    datas = {}
    redisx.del(db_name)
    ranklist = zset.new()
    TRACE("ClearRankList end ...")
end

--- 清空排行榜
function CMD.ClearRankList(data)
    cs(ClearRankList)
end

--- 设置日志级别
function CMD.logLevel(level)
    defaultLevel = level
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, command, ...)
        if dev_agent_log then
            skynet.error('command: ', command, ...)
        end

        local f = CMD[command]
        assert(f, command)

        if f then
            if session ~= 0 then
                skynet.retpack(f(...))
            else
                f(...)
            end
        end
    end)
end)
