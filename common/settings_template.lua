
-- 全局标志
_ENV.dev_sys_log = false -- 服务器系统log开关
_ENV.dev_rank_log = false
_ENV.dev_client_log = true

-- 服务配置
local settings = {
    test_mode     = false,     -- 测试模式

    --排名服
    rank_conf = {
        rank_ip              = '127.0.0.1',  -- 排名服对外ip【需要手动修改】
        rank_port            = 7112,         -- 登陆认证端口
        rank_web_port        = 7100,         -- rank_web服务监听端口
        rank_slave_cout      = 2,            -- 登陆认证代理个数
        rank_web_slave_count = 20,           -- rank_web服务代理个数
        console_port         = 7110,         -- 账号服控制台端口
    },
}

-- redis配置
settings.redis_conf = {
    host = '127.0.0.1',
    port = 6379,
    db   = 3,
}

return settings
