--- mysql 服务
-- mysql服务高级接口
-- @module mysql.mysqlx

local skynet        = require 'skynet'
local inspect       = require "inspect"
local inspect_log   = require "inspect_log"
require "logger_api"
local utils         = require "utils"

local mysqlx = {}
local MYSQL

skynet.init(function ()
    MYSQL = skynet.queryservice('mysql')
end)

local function genConditionStr(hash)
    local str = ""
    for key, value in pairs(hash) do
        if str ~= "" then
            str = str .. " and"
        end
        local valueStr = (type(value) == 'string') and ( "'" .. value .. "'") or value
        str = str .. " `" .. key .. "` = " .. valueStr
    end
    return str
end

local function genUpdateValuesStr(hash)
    local str = ""
    for key, value in pairs(hash) do
        if str ~= "" then
            str = str .. ","
        end
        local valueStr = (type(value) == 'string') and ( "'" .. value .. "'") or value
        str = str .. " `" .. key .. "` = " .. valueStr
    end
    return str
end

local function genInsertStr(hash)
    local keys = ""
    local values = ""
    for key, value in pairs(hash) do
        if keys ~= "" then
            keys = keys .. ","
        end
        keys = keys .. "`" .. key .. "`"
        if values ~= "" then
            values = values .. ","
        end
        local valueStr = (type(value) == 'string') and ( "'" .. value .. "'") or value
        values = values .. valueStr
    end

    local str = string.format("(%s) values (%s)", keys, values)
    return str
end

-- 修改
function mysqlx.update(tableName, mpColumns, mpConditions)
    assert(next(mpColumns) ~= nil and next(mpConditions) ~= nil and tableName ~= "")
    local sql = string.format("update `%s` set %s where %s;", tableName,
        genUpdateValuesStr(mpColumns), genConditionStr(mpConditions))
    return mysqlx.excute(sql)
end

-- 插入
function mysqlx.insert(tableName, mpColumns)
    assert(next(mpColumns) ~= nil and tableName ~= "")
    local sql = string.format("insert into `%s` %s;", tableName, genInsertStr(mpColumns))
    return mysqlx.excute(sql, true)
end

-- 替换
function mysqlx.replace(tableName, mpColumns)
    assert(next(mpColumns) ~= nil and tableName ~= "")
    local sql = string.format("replace into `%s` %s;", tableName, genInsertStr(mpColumns))
    return mysqlx.excute(sql)
end

-- 查询
function mysqlx.query(tableName, mpColumns)
    --fixme: 如果指定字段查询 则需要新增接口
    if mpColumns and next(mpColumns) then -- 带条件查询
        local sql = string.format("select * from `%s` where %s;", tableName, genConditionStr(mpColumns))
        return mysqlx.excute(sql, true)
    else -- 不带条件查询
        local sql = string.format("select * from `%s`;", tableName)
        return mysqlx.excute(sql, true)
    end
end

-- 删除(带条件的删除)
function mysqlx.delete(tableName, mpColumns)
    assert(next(mpColumns) ~= nil)
    local sql = string.format("delete from `%s` where %s;", tableName, genConditionStr(mpColumns))
    return mysqlx.excute(sql)
end

-- 清空整张表(不带条件的删除)
function mysqlx.truncate(tableName)
    assert(tableName ~= "")
    local sql = string.format("truncate table `%s`;", tableName)
    return mysqlx.excute(sql)
end

-- 执行sql语句 sync: 同步
function mysqlx.excute(sql, sync)
    assert(sql ~= "")
    if sync then
        local res = skynet.call(MYSQL, 'lua', 'query', sql)
        DEBUG(sql, "|", inspect_log(res, inspect))
        return res
    else
        skynet.send(MYSQL, 'lua', 'query', sql)
        DEBUG(sql)
    end
end

return mysqlx
