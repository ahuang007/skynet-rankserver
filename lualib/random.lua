local random = {}
local table_insert = table.insert

local generator = {}
local random_meta = { __index = generator }
local L_RANDMAX = 0x7fffffff

function generator:l_rand()
  local ctx = self.ctx
  local hi = ctx//127773
  local lo = ctx % 127773
  local x = 16807 * lo - 2836 * hi
  if x < 0 then
    x = x + L_RANDMAX
  end
  self.ctx = x
  return x - 1
end

-- 随机从 m 到 n, 要求是整数, m 和 n 都有可能随机到
-- 不给出参数, 则随机 0~1 的浮点数
-- 只给出一个参数, 则给出 1~m 中的一个随机数
function generator:random(m, n)
  local r = self:l_rand() * (1.0 / (L_RANDMAX + 1.0))
  assert(r >= 0 and r ~= 1)

  local low, up
  if m == nil and n == nil then
    return r
  elseif n == nil then
    low = 1
    up = m
  else
    low = m
    up = n
  end

  local ret = r * (up - low + 1) + low
  return math.floor(ret)
end

--[[
从表中按照 k 指定的概率随机一个对象, 对象由 v 键指定
  { k=rate1, v=item1 },
  { k=rate2, v=item2 },
  { k=rate3, v=item3 }
要求 list 中的概率总和为 1
]]
function generator:randomlist(list, k, v)
  local length = #list
  local sum_rate = 0
  local r = self:random()

  local function rt(i)
    if v then
      return list[i][v]
    else
      return list[i]
    end
  end

  for i = 1, length do
    sum_rate = sum_rate + list[i][k]
    if sum_rate > r then
      return rt(i)
    end
  end

  return rt(length)
end

-- 以 rate 概率随机, 如果随机中了返回 true, 否则返回 false
function generator:roll_rate(rate)
  return self:randomlist({
    { rate = rate,   item = true  },
    { rate = 1-rate, item = false }
  }, "rate", "item")
end

-- 从 list 物品中随机 count 个物品, 随机的物品不重复, 返回随机物品表
function generator:randomcount(list, count)
  local length = #list
  if count > length then
    return list
  end
  local ret = {}
  local ids = {}
  for i=1,count do
    while true do
      local i = self:random(1, length)
      if not ids[i] then
        table_insert(ret, list[i])
        ids[i] = true
        break
      end
    end
  end
  return ret
end

-- 从 list 物品列表中随机一个物品
function generator:randomone(list)
  local length = #list
  return list[self:random(1, length)]
end

function generator:randomseed(seed)
  if seed == nil then
    seed = 1
  end
  seed = tonumber(seed)
  assert(seed > 0 and seed % 1 == 0)
  self.ctx = (seed % 0x7ffffffe) + 1
end

function random.new(seed)
  local generator = setmetatable({}, random_meta)
  generator:randomseed(seed)
  return generator
end

return random
