local zset = require "zset"
local redisx = require "redisx"

local ipairs, pairs = ipairs, pairs
local table_insert = table.insert

local M = {}

function M.load(key)
  local zset = zset.new()
  local fields = redisx.hkeys(key)
  if not fields then return zset end
  for _, field in ipairs(fields) do
    local tbl = redisx.hgettable(key, field)
    for i=1, #tbl, 2 do
      zset:add(tbl[i+1], tbl[i])
    end
  end
  return zset
end

function M.save(zset, key)
  redisx.del(key)
  local i = 0
  local seri_t = {}
  for member, score in pairs(zset.tbl) do
    table_insert(seri_t, member)
    table_insert(seri_t, score)
    i = i + 1
    if i % 1000 == 0 then
      redisx.hsettable(key, i, seri_t)
      seri_t = {}
    end
  end
  redisx.hsettable(key, i, seri_t)
end

-- obj bool 默认true
-- 代表hash里面value是一个table还是单一的string
function M.loadEX(key, obj)
  obj = obj or true
  local zset = zset.new()
  local list
  if obj then
    list = redisx.hgetallobj(key)
  else
    list = redisx.hgetallstring(key)
  end
  for uid, score in pairs(list) do
    zset:add(tonumber(score), uid)
  end
  return zset
end

return M
