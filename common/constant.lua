
--- 常量
-- @module constant

local M = {}

-- 性别
M.GENDER = {
    UNKOWN  = 0,
    MAN     = 1,
    WOMAN   = 2,
}

-- 平台类型(sdk)
M.PLATFORM = {
    ANDRIOD = 0, -- 安卓
    IOS     = 1, -- 苹果
    INNER   = 1, -- 未知
}

-- 渠道类型
M.CHANNEL = {
    INNER   = 0,
    -- todo: 其他渠道
}

-- 日志级别
M.LOG_LEVEL = {
    LOG_DEFAULT   = 1,
    LOG_TRACE     = 1,
    LOG_DEBUG     = 2,
    LOG_INFO      = 3,
    LOG_WARN      = 4,
    LOG_ERROR     = 5,
    LOG_FATAL     = 6,
}

-- 错误码
M.ERRORCODE =
{
    success             = {0, "success"}, -- 成功
    sign_failed         = {1, "校验签名失败"}, -- 校验签名失败
    params_failed       = {2, "缺少参数"}, -- 参数校验失败
    user_not_found      = {3, "该用户不存在"}, -- 用户不存在
    account_not_found   = {5, "帐号不存在"}, -- 账号不存在
    not_online          = {6, "用户不在线"}, -- 用户在线
    fun_not_found       = {7, "gm命令没找到"}, -- 命令不存在
    server_id_error     = {8, "服务id错误"}, -- 服ID错误
    server_status_error = {9, "服务器状态错误"}, -- 服务器状态错误
    json_datas_error    = {10, "json数据有错误"}, -- json数据有错
    id_error_or_no_exist= {12, "错误或者不存在"}, -- id 错误或者不存在
    appid_not_found     = {13, "appid未找到"},
}

-- 请求类型
M.REQ_TYPE = {
    RT_COMMITDATA       = 1,
    RT_GETRANKLIST      = 2,
    RT_CLEARRANKLIST    = 3,
}

return M
