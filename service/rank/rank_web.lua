--- login 服务
-- 登录服web接口
-- @module login.login_web

local skynet        = require "skynet"
require 'skynet.manager'
local socket        = require "socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local utils         = require "utils"
local constant      = require "constant"
local ErrorCode     = constant.ERRORCODE
local json          = require "json"
local settings      = require 'settings'
local crypt         = require 'crypt'
local md5           = require 'md5'

require "logger_api"

local mode = ...
local rankservice
local ranksrvs

if mode == "agent" then

local function response(id, statuscode, bodyfunc, header)
    if not header then header = {} end
    header["Access-Control-Allow-Origin"] = "*" -- 解决跨域问题

    local ok, err = httpd.write_response(sockethelper.writefunc(id), statuscode, bodyfunc, header)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        INFO(string.format("fd = %d, %s", id, err))
    end
end

--[[
排行榜服务器文档
port: 7210
1 提交数据 http://192.168.1.201:7100/CommitData?
    {"cmd":"CommitData", "appid":1, data:{"uid":1001, "name":"andy", "headIcon":"", "score":99}
2 查看排行榜 http://192.168.1.201:7100/GetRankList?
    {"cmd":"GetRankList", "appid":1, data:{"uid":1001, "startindex":1, "endindex":100}
3 重置排行榜 http://192.168.1.201:7100/ClearRankList?
    {"cmd":"ClearRankList", "appid":1}

-- 目前支持的http请求
1 CommitData
2 GetRankList
3 ClearRankList
--]]

local function handle_CommitData(req)
    local appid = req.appid
    local ranksrv = ranksrvs[tonumber(appid)]
    if not ranksrv then
        WARN("ranksrv not exist", appid)
        return {
            status      = ErrorCode.appid_not_found[1],
            errorMsg    = ErrorCode.appid_not_found[1]
        }
    end

    local ok, err = skynet.call(ranksrv, "lua", "CommitData", req.data)
    if ok then
        return {
            status      = ErrorCode.success[1],
            errorMsg    = ErrorCode.success[1]
        }
    else
        return {
            status      = err[1],
            errorMsg    = err[2],
        }
    end
end

local function handle_GetRankList(req)
    local appid = req.appid
    local ranksrv = ranksrvs[tonumber(appid)]
    if not ranksrv then
        WARN("ranksrv not exist", appid)
        return ErrorCode.appid_not_found
    end

    local ok, err, lists = skynet.call(ranksrv, "lua", "GetRankList", req.data)
    if ok then
        return {
            status      = ErrorCode.success[1],
            lists       = lists,
        }
    else
        return {
            status      = err[1],
            errorMsg    = err[2],
        }
    end
end

local function handle_ClearRankList(req)
    local appid = req.appid
    local ranksrv = ranksrvs[tonumber(appid)]
    if not ranksrv then
        WARN("ranksrv not exist", appid)
        return ErrorCode.appid_not_found
    end

    local ok, err = skynet.call(ranksrv, "lua", "ClearRankList", req.data)
    if ok then
        return {
            status      = ErrorCode.success[1],
            errorMsg    = ErrorCode.success[1],
        }
    else
        return {
            status      = err[1],
            errorMsg    = err[2],
        }
    end
end

local http_req_tb = {
    ["CommitData"]      = handle_CommitData,
    ["GetRankList"]     = handle_GetRankList,
    ["ClearRankList"]   = handle_ClearRankList,
}

skynet.start(function()
    rankservice = skynet.localname(".rankservice")
    ranksrvs = skynet.call(rankservice, "lua", "GetRankSrvs")

    skynet.dispatch("lua", function (_, _, id, addr)
        socket.start(id)
        -- limit request body size to 8192 (you can pass nil to unlimit)
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
        DEBUG("request data:", code, url)
        if code then
            if code ~= 200 then  -- 如果协议解析有问题，就回应一个错误码 code 。
                response(id, code)
            else
                -- 这是一个示范的回应过程，你可以根据你的实际需要解析 url, method 和 header 做出回应。
                local tmp = {}
                local path, query = urllib.parse(url)
                local ismatch = false
                for cmd, func in pairs(http_req_tb) do
                    if string.match(path, cmd) then -- 只要找到就算数
                        ismatch = true
                        local req = urllib.parse_query(query)
                        local resp = func(req, addr)
                        response(id, code, json.encode(resp))
                        break
                    end
                end

                if not ismatch then
                    response(id, 404) -- 未知请求
                end
            end
        else
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(id)
    end)
end)

else

skynet.start(function()
    local agent = {}
    for i= 1, settings.rank_conf.rank_web_slave_count do
        agent[i] = skynet.newservice(SERVICE_NAME, "agent")
    end

    local balance = 1
    local id = socket.listen("0.0.0.0", settings.rank_conf.rank_web_port)
    socket.start(id , function(id, addr)
        INFO(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        skynet.send(agent[balance], "lua", id, addr)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end)

end
