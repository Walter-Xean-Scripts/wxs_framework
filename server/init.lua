require 'server.player.main'
local FWDB = require 'server.database'
local DiscordLog = require 'server.discordlog'
local PermissionSystem = require 'server.permissions.main'

print("---------------------------------")
print("^2[FW]^7 Initializing WXScripts Framework...")

-- Init the database 🚀
print("^2[FW]^7 Initializing database...")
FWDB:CreateIfNotExist()

-- Fetch saved groups 🧑‍🤝‍🧑
print("^2[FW]^7 Fetching saved groups...")
PermissionSystem:FetchSavedGroups()

-- Welcome message
print("---------------------------------")
print("^2[FW] WXScripts Framework is ready to rumble!^7")
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

local function Permissions()
    ---@class PermissionsExport
    return {
        CreateGroup = function(name, startPermissions)
            return PermissionSystem:CreateGroup(name, startPermissions)
        end,
        AddPermissionToGroup = function(group, permission)
            return PermissionSystem:AddPermissionToGroup(group, permission)
        end,
        AddPermissionsToGroup = function(group, permissions)
            return PermissionSystem:AddPermissionsToGroup(group, permissions)
        end,
        RemovePermissionFromGroup = function(group, permission)
            return PermissionSystem:RemovePermissionFromGroup(group, permission)
        end,
        RemovePermissionsFromGroup = function(group, permissions)
            return PermissionSystem:RemovePermissionsFromGroup(group, permissions)
        end,
        InherietFromGroup = function(group, inherietGroup)
            return PermissionSystem:AddInheriet(group, inherietGroup)
        end,
        RemoveInherietFromGroup = function(group, inherietGroup)
            return PermissionSystem:RemoveInheriet(group, inherietGroup)
        end,
        SetUserGroup = function(source, group)
            return PermissionSystem:SetUserGroup(source, group)
        end,
    }
end
exports('Permissions', Permissions)
