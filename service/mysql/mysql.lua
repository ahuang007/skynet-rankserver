-- mysql服务
-- 更新表结构前要备份一下表，因为更新表结构不能回滚，一般要在自己mysql测试sql的正确性
-- 更新数据开启事务,提交事务,回滚事务
local skynet = require "skynet"
local mysql = require "mysql"
local utils = require "utils"
local settings = require 'settings'
local json  = require 'cjson'
require "logger_api"
local CMD = {}

local db


local function update_version_2()
    --dump_table(t_account)
    -- 更新表结构前要备份一下表
    local sql = "alter table t_account add dust int(11) not null default 0;"
    res = CMD.query(sql)
    if res.errno then
        ERR("mysql.update_version_2:fail:sql="..sql..",error="..res.err)
        return false
    end
    -- 更新表数据 如果错误要rollback()，没有错误就commit()
    ---
    return true
end

local function update_version_3()
    --dump_table(t_account)
    -- 更新表结构前要备份一下表
    local sql = [[
    DROP TABLE IF EXISTS `t_treasure_chests`;
    CREATE TABLE IF NOT EXISTS `t_treasure_chests` (
        `uid` INT(11) NOT NULL COMMENT '玩家id',
        `num` INT(1) NOT NULL COMMENT '宝箱位ID(1,2,3,4),一个玩家最多有4个宝箱',
        `boxType` INT(1) NOT NULL COMMENT '宝箱类型',
        `createTime` INT(11) NULL DEFAULT NULL COMMENT '创建宝箱时间戳',
        `data` VARCHAR(256) COMMENT '宝箱获得数据顺序列表 id_itemType_count,id_itemType_count',
        PRIMARY KEY (`uid`, `num`)
    ) COMMENT='宝箱表' COLLATE='utf8_general_ci' ENGINE=InnoDB AUTO_INCREMENT=1000;
    ]]
    res = CMD.query(sql)
    if res.errno then
        ERR("mysql.update_version_3:fail:sql="..sql..",error="..res.err)
        return false
    end
    -- 更新表数据 如果错误要rollback()，没有错误就commit()
    ---
    return true
end

local updateTableStructureFunc = {
    [2] = {func=update_version_2,remarks="在t_account表增加dust字段"},
    [3] = {func=update_version_3,remarks="在重新创建t_treasure_chests表"},
}
-- 获得当前版本
local function set_version(version, remarks)
    local sql = string.format("insert into t_version(version,remarks)values(%d,'%s');", version, remarks)
    local res = CMD.query(sql)
    if not res then
        return false
    end
    return true
end
-- 获得当前版本
local function get_version()
    local sql = "select max(version) as version from t_version;"
    res = CMD.query(sql)
    local data = res[1]
    if data.version then
        return data.version
    end
    --新的数据库
    local version = 0
    for k,v in pairs(updateTableStructureFunc) do
        set_version(k, v.remarks)
        if version < k then
            version = k
        end
    end
    return version
end
--设置是否自动提交
local function set_auto_commit(auto)
    local sql = string.format("set autocommit=%d;", auto)
    res = CMD.query(sql)
    if res.errno then
        ERR("mysql.autocommit:fail:sql="..sql..",error="..res.err)
        return false
    end
    return true
end
-- 开启事务
local function start_transaction()
    local sql = "start transaction;"
    res = CMD.query(sql)
    if res.errno then
        ERR("mysql.start_transaction:fail:sql="..sql..",error="..res.err)
        return false
    end
    return true
end
-- 提交事务
local function commit()
    local sql = "commit;"
    res = CMD.query(sql)
    if res.errno then
        ERR("mysql.commit:fail:sql="..sql..",error="..res.err)
        return false
    end
    return true
end
--回滚事务
local function rollback()
    local sql = "rollback;"
    res = CMD.query(sql)
    if res.errno then
        ERR("mysql.rollback:fail:sql="..sql..",error="..res.err)
        return false
    end
    return true
end
-- 备份数据
local function dump_table(table_name)
    local table_name_backup = table_name.."_backup"
    local sql_del = string.format("drop table %s;", table_name_backup)
    CMD.query(sql_del)
    local sql_create = string.format("create table %s like %s;", table_name_backup, table_name)
    CMD.query(sql_create)
    local sql = string.format("insert into %s select * from %s;", table_name_backup, table_name)
    res = CMD.query(sql)
    if res.errno then
        ERR("mysql.dump_table:fail:sql="..sql..",error="..res.err)
        return false
    end
end
-- 更新表结构或表数据
local function update_table()
    local version = get_version()
    for k,v in pairs(updateTableStructureFunc) do
        if k > version then
            if v.func(k, v.remarks) then
                set_version(k, v.remarks)
            end
        end
    end
end

-- 数据库保活
local last_check_time = 0
local mysql_keepalive_time = 60 * 100
local function keep_alive()
    skynet.timeout(mysql_keepalive_time, keep_alive)
    local t  = last_check_time + mysql_keepalive_time - skynet.now()
    if t <= 0 then
        CMD.query('select 1')
        last_check_time = skynet.now()
    end
end

function CMD.query(sqlStr)
    local ok, res = pcall(mysql.query, db, sqlStr) -- 捕捉异常
    if not ok then
        ERROR("mysql error: ", res, sqlStr)
        return nil
    else
        return res
    end
end


local traceback = debug.traceback
skynet.start(function()
    skynet.error("Mysql start...")
    db = mysql.connect(settings.mysql_conf)
    if not db then
        logger.trace("failed to connect mysql service")
        return
    end
    db:query("set names utf8")
    skynet.error("success to connect to mysql service")

    last_check_time = skynet.now()
    keep_alive()
    update_table()

    skynet.dispatch("lua", function(_, _, command, ...)
        local f = CMD[command]
        if not f then
            logger.warningf("unhandled message(%s)", command)
            return skynet.ret()
        end

        local ok, ret = xpcall(f, traceback, ...)
        if not ok then
            logger.warningf("handle message(%s) failed : %s", command, ret)
            return skynet.ret()
        end
        skynet.retpack(ret)
    end)
end)
