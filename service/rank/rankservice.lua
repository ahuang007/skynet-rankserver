--- rank 服务
-- 登录服务
-- @module rank.rankservice

local skynet    = require "skynet"
local crypt     = require "crypt"
local settings  = require 'settings'
local constant  = require 'constant'
local utils     = require 'utils'
local sharedata = require "sharedata"
local cluster   = require "cluster"
local app_config = require "app_config"
require "logger_api"

local CMD           = {}
local ranksrvs      = {} --{ appid => ranksrv }

local inspect = require 'inspect'
skynet.info_func(function ()
    return inspect {
        ranksrvs = ranksrvs,
    }
end)

function CMD.init()
    cluster.register("rankservice")

    for _, v in pairs(app_config) do
        if not ranksrvs[v.appid] then
            local ranksrv = skynet.newservice("rank_agent", v.appid)
            skynet.send(ranksrv, "lua", "start")
            ranksrvs[v.appid] = ranksrv
        else
            beEnter = true
            agent   = user.agent
        end
    end
end

function CMD.GetRankSrvs()
    return ranksrvs
end

function CMD.GetRankSrv(appid)
    return ranksrvs[appid]
end

skynet.start(function ()
    skynet.dispatch("lua", function(session, source, command, ...)
        if dev_rank_log then
            skynet.error('command: ', command, ...)
        end
        local f = CMD[command]
        if f then
            if session ~= 0 then
                skynet.retpack(f(...))
            else
                f(...)
            end
        else
            skynet.error("unknow command : ", command, source)
            if session ~= 0 then
                skynet.ret(false, "unknow command : " .. command)
            end
        end
    end)
end)
