--- rank 服务
-- rank 服务入口
-- @module rank

local skynet = require 'skynet.manager'
local cluster = require "cluster"
local settings = require 'settings'

skynet.start(function ()
    skynet.uniqueservice('debug_console', settings.rank_conf.console_port)
    skynet.uniqueservice('redis')

    -- 业务日志服务
    local local_logger = assert(skynet.uniqueservice('local_logger'), 'init local_logger failed')
    skynet.send(local_logger,"lua", "init")

    local rankservice = skynet.newservice("rankservice")
    skynet.name(".rankservice", rankservice)
    skynet.call(rankservice, "lua", "init")
    skynet.name(".rank_web", skynet.newservice("rank_web"))

    cluster.open "ranknode"
    skynet.exit()
end)

