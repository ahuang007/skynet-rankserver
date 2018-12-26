--- logger 服务
-- 日志传输模块
-- 日志分类打印功能
-- @module logger.logger_api

local skynet    = require "skynet"
local constant  = require "constant"
local date      = require "date"

_G.defaultLevel = constant.LOG_LEVEL.LOG_DEFAULT

-- 业务日志
function LOG_COMMIT(...)
    skynet.send(".local_logger","lua", "log_commit", ...)
end

-- 错误日志 --
local function logger(str, level, color)
    return function (...)
        if level >= defaultLevel then
            local info = G_INFO or { uid = "N/A" }
            skynet.error(string.format("%s %s \x1b[0m", color, str), date.format(date.second()), info.uid, ...)
        end
    end
end

local M = {
    TRACE = logger("[trace]",     constant.LOG_LEVEL.LOG_TRACE,   "\x1b[32m"),
    DEBUG = logger("[debug]",     constant.LOG_LEVEL.LOG_DEBUG,   "\x1b[32m"),
    INFO  = logger("[info]",      constant.LOG_LEVEL.LOG_INFO,    "\x1b[32m"),
    WARN  = logger("[warning]",   constant.LOG_LEVEL.LOG_WARN,    "\x1b[33m"),
    ERR   = logger("[error]",     constant.LOG_LEVEL.LOG_ERROR,   "\x1b[31m"),
    FATAL = logger("[fatal]",     constant.LOG_LEVEL.LOG_FATAL,   "\x1b[31m")
}

setmetatable(M, {
    __call = function(t)
        for k, v in pairs(t) do
            _G[k] = v
        end
    end,
})

M()

return M
