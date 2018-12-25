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

function CMD.log_reg(plat, channel, username, uid, ip, phonemodel, devicekey, quick)
    local data = {
        plat = plat,
        channel = channel,
        username = username,
        uid = uid,
        -- 其他数据
    }
    CMD.log(config_logger.log_index.LOG_REG, 'register', data)
end

-- 玩家在线日志(每5分钟写一次)
-- 参数说明
--[[
playercount 在线玩家数量
time        记录时间
]]
function CMD.log_online(playerCount)
    local data = {
        playercount = playerCount,
        time        = os.time(),
    }
    counter()
    CMD.log(config_logger.log_index.LOG_ONLINE, 'online', data)
end


-------login日志--------
--[[
参数名          参数定义      参数类型    默认值                 参数必传
gameId          应用ID        int        无，系统分配             是
channelId       渠道ID        int        若无，默认为0            是
zoneId          分区ID        int        若未分区，默认为0        是
zoneName        分区名        char       若未分区，默认为游戏名    是
playerId        玩家ID        int        游戏分配给玩家的玩家ID    是
playerName      玩家名        char       游戏分配给玩家的用户名    是
playerGender    玩家性别      int        男传0,女传1,未知传2       是
playerLevel     玩家级别      int        默认为0                  是
playerVipLevel  玩家vip级别   int        默认为0                  是
playerIp        玩家ip地址    char       玩家登录时的ip地址        是
platform        玩家设备平台  int        Android 传0，IOS传1      是
deviceKey       玩家设备标识  char       无                       是
phoneModel      玩家设备型号  char       示例’MI MAX2’            是
loginTime       登录时间      bigint     无                       是
timeStamp       请求时间戳    bigint     无                       是
signType        签名方式      char       目前支持md5，sha1         是
reportType      上报类型      char       login                     是
sign            签名          char       md5或sha1对以上字段的签名 是
]]
function CMD.log_login(uid, plat, channel, nickname, ip, devicekey, phonemodel)
    local data = {
        playerId           = uid,
        playerName         = nickname,
    }
    CMD.log(config_logger.log_index.LOG_LOGIN, 'logout', data)
end

-------logout日志--------
---
function CMD.log_logout(uid, plat, channel, nickname, ip, devicekey, phonemodel)
    local data = {
        player_id           = uid,
        player_name         = nickname,
    }
    CMD.log(config_logger.log_index.LOG_LOGOUT, 'logout', data)
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
