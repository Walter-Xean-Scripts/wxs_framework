local Utils = {}

---Sends a discord log
---@param title string
---@param message string
function Utils:SendDiscordLog(webhook, title, message)
    return exports.wxs_framework:SendDiscordLog(webhook, title, message)
end

---Sends a discord log with fields
---@param title string
---@param fields table
function Utils:SendDiscordLogFields(webhook, title, fields)
    return exports.wxs_framework:SendDiscordLogFields(webhook, title, fields)
end

return Utils
