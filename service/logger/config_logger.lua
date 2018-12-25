--- logger 服务
-- 日志配置表
-- @module logger.config_logger

local skynet = require "skynet"
local config = {}

--业务日志
config.log_index =
{
    LOG_COMMIT     = 1, -- 提交排行数据
}

--业务日志对应服务名
config.service_name =
{
    [config.log_index.LOG_COMMIT]    = ".rank_commit",
}

-- 游戏逻辑服务
config.local_service =
{
    [config.log_index.LOG_COMMIT]   = ".rank_commit busilog commit",
}

return config

