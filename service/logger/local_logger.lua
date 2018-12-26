--- logger 服务
-- 本地日志处理模块
-- @module logger.local_logger

local skynet    = require "skynet"
local cluster   = require "cluster"
local json      = require "cjson"
local date      = require "date"
local config_logger = require "logger.config_logger"
local utils     = require "utils"
local settings  = require "settings"
local json      = require "cjson"

require "skynet.manager"
require "logger_api"

skynet.register_protocol {
    name = "busi_logger",
    id = 0,
    pack = function (...)
        local t = {...}
        for i,v in ipairs(t) do
            t[i] = tostring(v)
        end
        return table.concat(t," ")
    end,
    unpack = skynet.unpack,
}

local CMD = {}
CMD.log_box = {}

local function get_log_str(prefix, t)
    return date.format(date.second()) .. "|" ..  prefix .. "|" .. json.encode(t)
end

function CMD.log(logtype, prefix, data)
    if not CMD.log_box[logtype] then
        skynet.error("cannot find bussiness by type: ", logtype)
        return
    end
    local str = get_log_str(prefix, data)
    skynet.send(config_logger.service_name[logtype], "busi_logger", str)
end

-- 玩家在线日志(每5分钟写一次)
-- 参数说明
--[[
playercount 在线玩家数量
time        记录时间
]]
function CMD.log_commit(uid, name, headIcon, score)
    local data = {
        uid         = uid,
        name        = name,
        headIcon    = headIcon,
        score       = score,
        time        = os.time(),
    }
    CMD.log(config_logger.log_index.LOG_COMMIT, 'commit', data)
end

-- end business logger --

function CMD.init()
    for key,value in pairs(config_logger.local_service) do
        skynet.launch("busilogger", value)
        CMD.log_box[key] = 1
    end
end

local traceback = debug.traceback
skynet.start(function()
    skynet.dispatch("lua", function(_, _, command, ...)
    local f = CMD[command]
    if not f then
        skynet.error(("local_logger unhandled message(%s)"):format(command))
        return
    end

    local ok, ret = xpcall(f, traceback, ...)
        if not ok then
            skynet.error(("local_logger handle message(%s) failed : %s"):format(command, ret))
        end
    end)
    skynet.register("." .. SERVICE_NAME)
end)
