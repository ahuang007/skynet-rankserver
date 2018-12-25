--- redis 服务
-- redis服务
-- @module redis

local skynet = require 'skynet'
require 'skynet.manager' -- import skynet.abort()
local redis = require 'redis'
local settings = require 'settings'

skynet.start(function ()

  local db_conf = settings.redis_conf
  local ok, hredis = pcall(redis.connect, db_conf)

  if not ok then
    skynet.error('cannot connect to redis!')
    return skynet.abort()
  end

  skynet.dispatch("lua", function(_, _, cmd, subcmd, ...)

    if dev_redis_log then
      --skynet.error('command: ', cmd, subcmd, ...)
    end

    local hredis = hredis

    if cmd == 1 then
      return skynet.retpack(hredis[subcmd](hredis, ...))
    else
      return hredis[cmd](hredis, subcmd, ...)
    end
  end)
end)
