local table, string, pairs, ipairs, type, math = table, string, pairs, ipairs, type, math

local table_insert  = table.insert
local table_concat  = table.concat
local string_format = string.format
local constant      = require "constant"

local utils = {}

function utils.simple_copy_obj(obj)
    if type(obj) ~= "table" then
        return obj
    end
    local ret = {}
    for k, v in pairs(obj) do
        ret[utils.simple_copy_obj(k)] = utils.simple_copy_obj(v)
    end
    return ret
end

function utils.var_dump(data, max_level, prefix)
    if type(prefix) ~= "string" then
        prefix = ""
    end
    if type(data) ~= "table" then
        print(prefix .. tostring(data))
    else
        print(data)
        if max_level ~= 0 then
            local prefix_next = prefix .. "    "
            print(prefix .. "{")
            for k, v in pairs(data) do
                io.stdout:write(prefix_next .. k .. " = ")
                if type(v) ~= "table" or (type(max_level) == "number" and max_level <= 1) then
                    print(v, ",")
                else
                    if max_level == nil then
                        utils.var_dump(v, nil, prefix_next)
                    else
                        utils.var_dump(v, max_level - 1, prefix_next)
                    end
                end
            end
            print(prefix .. "}")
        end
    end
end

--- 查找表中是否存在值等于value的项
function utils.findValue(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

--序列化
function utils.serialize_table(obj, lvl)
    local lua = {}
    local t = type(obj)
    if t == "number" then
        table_insert(lua, obj)
    elseif t == "boolean" then
        table_insert(lua, tostring(obj))
    elseif t == "string" then
        table_insert(lua, string_format("%q", obj))
    elseif t == "table" then
        lvl = lvl or 0
        local lvls = ('  '):rep(lvl)
        local lvls2 = ('  '):rep(lvl + 1)
        table_insert(lua, "{\n")
        for k, v in pairs(obj) do
            table_insert(lua, lvls2)
            table_insert(lua, "[")
            table_insert(lua, utils.serialize_table(k,lvl+1))
            table_insert(lua, "]=")
            table_insert(lua, utils.serialize_table(v,lvl+1))
            table_insert(lua, ",\n")
        end
        local metatable = getmetatable(obj)
        if metatable ~= nil and type(metatable.__index) == "table" then
            for k, v in pairs(metatable.__index) do
                table_insert(lua, "[")
                table_insert(lua, utils.serialize_table(k, lvl + 1))
                table_insert(lua, "]=")
                table_insert(lua, utils.serialize_table(v, lvl + 1))
                table_insert(lua, ",\n")
            end
        end
        table_insert(lua, lvls)
        table_insert(lua, "}")
    elseif t == "nil" then
        return nil
    else
        print("can not serialize a " .. t .. " type.")
    end
    return table_concat(lua, "")
end

function utils.makeGmManagerValue(type, content)
    local res = {
        status =type[1],
        msg = type[2],
    }
    if content then
        res.content = content
    end
    return res
end

--反序列化
function utils.unserialize_table(lua)
    local t = type(lua)
    if t == "nil" or lua == "" then
        return nil
    elseif t == "number" or t == "string" or t == "boolean" then
        lua = tostring(lua)
    else
        print("can not unserialize a " .. t .. " type.")
    end
    lua = "return " .. lua
    local func = load(lua)
    if func == nil then
        return nil
    end
    return func()
end

function utils.fill_string(str, len, expr)
    if #str < len then
        for i = 1, len - #str do
            str =  expr .. str
        end
    end
    return str
end

function utils.write_file(file_name, string)
    local f = assert(io.open(file_name, 'a+'))
    f:write(string)
    f:close()
end

-- hash key的数量
function utils.hashsize(table)
    local n = 0
    for k, v in pairs(table) do
        n = n + 1
    end
    return n
end

-- 数组中是否存在元素e
function utils.elem(list, e)
    for _, v in ipairs(list) do
        if v == e then
            return true
        end
    end
    return false
end

-- 数组中是否存在元素e
function utils.removeElem(list, e)
    for i, v in ipairs(list) do
        if v == e then
            table.remove(list, i)
            return true
        end
    end
    return false
end

-- 合并数组
function utils.combineTable(tb1, tb2)
    assert(type(tb1) == "table" and type(tb2) == "table")
    for _, v in ipairs(tb2) do
        table_insert(tb1, v)
    end
    return tb1
end

-- 按哈希key排序
function utils.spairs(t, cmp)
    local sort_keys = {}
    for k, v in pairs(t) do
        table.insert(sort_keys, {k, v})
    end
    local sf
    if cmp then
        sf = function (a, b) return cmp(a[1], b[1]) end
    else
        sf = function (a, b) return a[1] < b[1] end
    end
    table.sort(sort_keys, sf)

    return function (tb, index)
        local ni, v = next(tb, index)
        if ni then
            return ni, v[1], v[2]
        else
            return ni
        end
    end, sort_keys, nil
end

-- 深拷贝
function utils.copy(t, nometa)
    local result = {}
    if not nometa then
        setmetatable(result, getmetatable(t))
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = utils.copy(v, nometa)
        else
            result[k] = v
        end
    end
    return result
end

-- t1,t2为时间戳
function utils.is_same_day(t1, t2)
    local last = os.date("*t", t1)
    local now = os.date("*t", t2)
    return last.year == last.year and now.month == last.month and now.day == last.day
end

function utils.getHashLen(hash)
    if type(hash) ~= "table" then return 0 end
    local len = 0
    for _, _ in pairs(hash) do
        len = len + 1
    end
    return len
end

function utils.str2array(str)
    local ret = {}
    for id,value in string.gmatch(str, "(%d+),(%d+)") do
        ret[tonumber(id)] = tonumber(value)
    end
    return ret
end

function utils.checkKeys(keys, src)
    for _,v in pairs(keys) do
        if not src[v] then
            print(string.format("checkKeys(...) not found key[%s]", v))
            return false
        end
    end
    return true
end

function utils.checkKV(keys, src)
    for k,v in pairs(keys) do
        if not src[k] then
            print(string.format("checkKV(...) not found key %s", k))
            return false
        end

        if type(v) ~= type(src[k]) then
            print(string.format("checkKV(...) key diff type %s", k))
            return false
        end
    end
    return true
end

-- 针对于某一个时间点的下一个到点的间隔
function utils.nextTicker(hour, min, sec)
    local now = os.time()
    local date = os.date('*t', now)
    local ticker_time
    if (hour > date.hour) or 
        (hour == date.hour and min >= date.min and sec <= date.sec) then
        ticker_time = os.time({year = date.year, month = date.month,
                                day = date.day, hour = hour, min = min, sec = sec})
    else
        ticker_time = os.time({year = date.year, month = date.month,
                                day = date.day + 1, hour = hour, min = min, sec = sec})
    end
    local diff = os.difftime(ticker_time, now)
    return (diff < 0 and 1 or diff)
end

-- 数组乱序
function utils.randArrOrder(arr)
    local t = utils.copy(arr, true)
    for i = #t, 2, -1 do
        local tmp = t[i]
        local index = math.random(1, i - 1)
        t[i] = t[index]
        t[index] = tmp
    end
    return t
end

function utils.split(str, split)
    local list = {}
    local pos = 1
    if string.find("", split, 1) then -- this would result in endless loops
        error("split matches empty string!")
    end
    while true do
        local first, last = string.find(str, split, pos)
        if first then
            table_insert(list, string.sub(str, pos, first - 1))
            pos = last + 1
        else
            table_insert(list, string.sub(str, pos))
            break
        end
    end
    return list
end

return utils
