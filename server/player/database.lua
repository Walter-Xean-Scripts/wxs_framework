---@class PlayerDB
local playerDB = {}

local INSERT_USER <const> =
'INSERT INTO `users` (`license2`, `steam`, `discord`, `fivem`, `characterSlots`) VALUES (?, ?, ?, ?, ?)'
function playerDB:CreateUser(source)
    local license = GetPlayerIdentifierByType(source, "license2")
    local steam = GetPlayerIdentifierByType(source, "steam")
    local discord = GetPlayerIdentifierByType(source, "discord")
    local fivem = GetPlayerIdentifierByType(source, "fivem")

    local rowsChanged <const> = exports.oxmysql:query_async(INSERT_USER,
        { license, steam, discord, fivem, GeneralConfig.MaximumCharacters })
    if rowsChanged == 0 then
        error("Failed to create user")
        return false
    end

    return true
end

local UPDATE_CHARACTER_SLOTS <const> = 'UPDATE `users` SET `characterSlots` = ? WHERE `id` = ?'
function playerDB:UpdateCharacterSlots(userId, characterSlots)
    local result <const> = exports.oxmysql:query_async(UPDATE_CHARACTER_SLOTS, { characterSlots, userId })
    if not result then
        error("Failed to update character slots for user " .. userId)
        return false
    end

    return true
end

local SELECT_USER <const> = 'SELECT * FROM `users` WHERE `license2` = ?'
function playerDB:FetchUser(source)
    local license = GetPlayerIdentifierByType(source, "license2")

    local result <const> = exports.oxmysql:query_async(SELECT_USER, { license })
    if not result or result[1] == nil then
        return nil
    end

    return result[1]
end

local SELECT_CHARACTERS <const> = 'SELECT * FROM `characters` WHERE `userId` = ?'
function playerDB:FetchCharacters(userId)
    local result <const> = exports.oxmysql:query_async(SELECT_CHARACTERS, { userId })
    if not result then
        return nil
    end

    return result
end

local SELECT_CHARACTER <const> = 'SELECT * FROM `characters` WHERE `id` = ?'
function playerDB:FetchCharacter(characterId)
    local result <const> = exports.oxmysql:query_async(SELECT_CHARACTER, { characterId })
    if not result or result[1] == nil then
        return nil
    end

    return result[1]
end

local INSERT_CHARACTER <const> =
'INSERT INTO `characters` (`userId`, `firstName`, `lastName`, `dateOfBirth`, `height`, `gender`) VALUES (?, ?, ?, ?, ?, ?)'
function playerDB:CreateCharacter(userId, characterData)
    local result <const> = exports.oxmysql:insert_async(INSERT_CHARACTER, {
        userId,
        characterData.firstName,
        characterData.lastName,
        characterData.dateOfBirth,
        characterData.height,
        characterData.gender,
    })

    if not result then
        error("Failed to create character for user " .. userId)
        return false
    end

    return true
end

local DELETE_CHARACTER <const> = 'DELETE FROM `characters` WHERE `id` = ?'
function playerDB:DeleteCharacter(characterId)
    local result <const> = exports.oxmysql:query_async(DELETE_CHARACTER, { characterId })
    if not result then
        error("Failed to delete character " .. characterId)
        return false
    end

    return true
end

local UPDATE_CHARACTER <const> =
'UPDATE `characters` SET `firstName` = ?, `lastName` = ?, `gender` = ?, `currencies` = ?, `inventory` = ?, `metadata` = ? WHERE `id` = ?'
function playerDB:UpdateCharacter(characterData)
    local result <const> = exports.oxmysql:query_async(UPDATE_CHARACTER, {
        characterData.firstName,
        characterData.lastName,
        characterData.gender,
        json.encode(characterData.currencies),
        json.encode(characterData.inventory),
        json.encode(characterData.metadata),
        characterData.id,
    })

    if not result then
        error("Failed to update character " .. characterData.id)
        return false
    end

    return true
end

function playerDB:UpdateCharacterRS(characterData)
    exports.oxmysql:query(UPDATE_CHARACTER, {
        characterData.firstName,
        characterData.lastName,
        characterData.gender,
        json.encode(characterData.currencies),
        json.encode(characterData.inventory),
        json.encode(characterData.metadata),
        characterData.id,
    })

    return true
end

return playerDB
