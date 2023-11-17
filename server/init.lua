require 'server.player.main'
local FWDB = require 'server.database'
local DiscordLog = require 'server.discordlog'

-- Init the database 🚀
FWDB:CreateIfNotExist()

-- Welcome message
print("^2[FW]^7 Welcome to the WX Framework!")
print("---------------------------------")
print("A framework that values good code, compatability and performance.")
print("Created by WXScripts.")
print("---------------------------------")

--[[
    Exports
]]
local function SendDiscordLog(webhook, title, message)
    DiscordLog:Send(webhook, title, message)
end
exports('SendDiscordLog', SendDiscordLog)

local function SendDiscordLogFields(webhook, title, fields)
    DiscordLog:SendWithFields(webhook, title, fields)
end
exports('SendDiscordLogFields', SendDiscordLogFields)
