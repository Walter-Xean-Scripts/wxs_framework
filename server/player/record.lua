PlayerFunctions = {}
local db = require 'server.player.database'
local playerClass = require 'server.player.class'

---@type table<number, WXPlayer>
local currentPlayers = {}
local originalPlayerData = {}
local connectingPlayers = {}
local shouldRunSaveLoop = false

local function createUserObject(source, userData)
    local player = playerClass.new(source, userData)
    originalPlayerData[source] = player
    return originalPlayerData[source]
end

local function createUserIfNotExists(source, deferrals)
    local playerData <const> = db:FetchUser(source)

    if playerData == nil then
        db:CreateUser(source)

        local newPlayerData <const> = db:FetchUser(source)
        if newPlayerData == nil then
            error("Failed to create user: " .. source)
            deferrals.done("Failed to get created player data, please contact the server you're playing on.")
            return false
        end

        createUserObject(source, newPlayerData)
        return true
    else
        createUserObject(source, playerData)
        return true
    end
end

AddEventHandler('playerConnecting', function(username, _, deferrals)
    local tempId = source
    deferrals.defer()

    if createUserIfNotExists(tempId, deferrals) then
        connectingPlayers[tempId] = true

        deferrals.done()
    end
end)

local function startSaveLoop()
    CreateThread(function()
        while shouldRunSaveLoop do
            Wait(GeneralConfig.SaveInterval)

            local totalPlayers = 0
            local playersSaved = 0
            for _, player in pairs(currentPlayers) do
                totalPlayers = totalPlayers + 1

                if player:Save() then
                    playersSaved = playersSaved + 1
                end
            end

            print(string.format("^2[FW]^7 Saved %d/%d players!", playersSaved, totalPlayers))
        end
    end)
end

AddEventHandler('playerJoining', function(tempId)
    local playerId = source
    tempId = tonumber(tempId)

    if tempId and connectingPlayers[tempId] then
        connectingPlayers[tempId] = nil
        currentPlayers[playerId] = originalPlayerData[tempId]
        currentPlayers[playerId].source = playerId
    end

    if not shouldRunSaveLoop then
        shouldRunSaveLoop = true
        startSaveLoop()
    end
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    if currentPlayers[playerId] then
        currentPlayers[playerId] = nil
    end

    if next(currentPlayers) == nil then
        shouldRunSaveLoop = false
    end
end)

-- If the resource restarts, we'll need to re-create the user objects for the players that are currently online.
CreateThread(function()
    for _, source in ipairs(GetPlayers()) do
        local playerId = tonumber(source)
        if not playerId then
            return
        end

        createUserIfNotExists(playerId)

        local playerData = db:FetchUser(playerId)
        if playerData then
            currentPlayers[playerId] = playerClass.new(playerId, playerData)
        end

        if not shouldRunSaveLoop then
            shouldRunSaveLoop = true
            startSaveLoop()
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, player in pairs(currentPlayers) do
            player:Save(true) -- we're attempting to save whatever data we can if the resource stops, so we're passing true to the save function.
        end
    end
end)

--[[
    Sadly we can't export metatables, so we're doing this "hack" to make our GetPlayer function work when exported.
]]
local function readyPlayerObjectForExport(playerObj)
    local newPlayer = {}

    for _, funcName in ipairs(PlayerFunctions) do
        newPlayer[funcName] = function(_, ...)
            return playerObj[funcName](playerObj, ...)
        end
    end

    return newPlayer
end

local function GetPlayerForExport(source)
    local player = currentPlayers[source]

    if player then
        return readyPlayerObjectForExport(player)
    else
        return nil
    end
end
exports("GetPlayer", GetPlayerForExport)