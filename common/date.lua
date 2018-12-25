local skynet    = require "skynet"
local os_date   = os.date
local os_time   = os.time
local string_sub = string.sub

local starttime = skynet.starttime()

local date = {}

local TZ = tonumber(skynet.getenv("TZ")) or 8
local TD =  TZ * 3600

function date.now()
    return skynet.now()/100 + starttime
end

function date.second()
    return skynet.now()//100 + starttime
end

function date.format(sec, ms)
    local f = os.date("%Y-%m-%d %H:%M:%S", sec)
    if ms then
        f = string.format("%s.%02d",ms)
    end
    return f
end

function date.localtime(time)
    local t = time or date.second()
    return os.date("!*t", t + TD)
end

function date.get_today_time(hour, min, sec)
    local dt = date.localtime()
    dt.hour = hour or 0
    dt.min = min or 0
    dt.sec = sec or 0
    return os.time(dt)
end

local DAY_SECOND = 24 * 60 * 60
function date.day_internal(stime, etime)
    local function to_day_start(time)
        local t = os_date("*t", time)
        t.hour = 0
        t.min = 0
        t.sec = 0
        return os_time(t)
    end
    stime = to_day_start(stime)
    etime = to_day_start(etime)
    return (stime - etime) // DAY_SECOND
end

-- 字符串转换成时间戳
-- YYYY-MM-DD hh:mm:ss
-- eg: 2016-10-01 12:59:59
function date.str2datetime(time)
    local date = os_date("*t", os_time())
    date.year  = string_sub(time, 1, 4)
    date.month = string_sub(time, 6, 7)
    date.day   = string_sub(time, 9, 10)
    date.hour  = string_sub(time, 12, 13)
    date.min   = string_sub(time, 15, 16)
    date.sec   = string_sub(time, 18, 19)
    return math.floor(os_time(date))
end

-- 时间戳转换成字符串
function date.datetime2str(datetime)
    local date = os_date("*t", datetime)
    local arr = {}
    local sYear = tostring(date.year)
    table.insert(arr, sYear)
    table.insert(arr, "-")
    local sMonth = (date.month < 10) and ("0" .. date.month) or tostring(date.month)
    table.insert(arr, sMonth)
    table.insert(arr, "-")
    local sDay = (date.day < 10) and ("0" .. date.day) or tostring(date.day)
    table.insert(arr, sDay)
    table.insert(arr, " ")
    local sHour = (date.hour < 10) and ("0" .. date.hour) or tostring(date.hour)
    table.insert(arr, sHour)
    table.insert(arr, ":")
    local sMin = (date.min < 10) and ("0" .. date.min) or tostring(date.min)
    table.insert(arr, sMin)
    table.insert(arr, ":")
    local sSec = (date.sec < 10) and ("0" .. date.sec) or tostring(date.sec)
    table.insert(arr, sSec)
    return table.concat(arr, "")
end

-- 判断2个时间戳是否为在同一个星期(时间差不超过24小时)
-- a:前时间戳 b: 后时间戳
function date.isSameWeek(a, b)
    assert((b - a >= 0) and (b-a < DAY_SECOND))
    local ta = os_date("*t", a)
    local tb = os_date("*t", b)
    if ta.wday == 7 and tb.wday == 1 then
        return false
    end
    return true
end

return date
