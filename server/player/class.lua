local currencies = require 'server.player.subclasses.currencies'
---@class Inventory
local inventory = require 'server.player.subclasses.inventory'
local db = require 'server.player.database'

---@class WXPlayer
---@field source number
---@field userData table
---@field currentCharacter table | nil
---@field currencies Currencies
---@field inventory Inventory | nil
---@field metadata table
---@field mutex Mutex
local WXPlayer = {}

function WXPlayer.new(source, userData)
    return setmetatable({
        source = source,
        userData = userData,
        currentCharacter = nil,
        ---@type Currencies
        currencies = currencies.new(),
        ---@type Inventory
        inventory = nil,
        metadata = {},
        mutex = Mutex.new()
    }, {
        __index = WXPlayer
    })
end

---Get's the users available characters
---@return table|nil
function WXPlayer:GetCharacters()
    return db:FetchCharacters(self.userData.id)
end

---@param characterData CharacterData
local function validateCharacterData(characterData)
    if characterData.firstName == nil or characterData.lastName == nil or characterData.dateOfBirth == nil then
        return false
    end

    if characterData.firstName:len() < GeneralConfig.MinimumNameLength or characterData.firstName:len() > GeneralConfig.MaximumNameLength then
        return false
    end

    if characterData.lastName:len() < GeneralConfig.MinimumNameLength or characterData.lastName:len() > GeneralConfig.MaximumNameLength then
        return false
    end

    if type(characterData.firstName) ~= "string" or type(characterData.lastName) ~= "string" or type(characterData.dateOfBirth) ~= "string" then
        return false
    end

    if characterData.gender ~= 1 and characterData.gender ~= 2 then
        return false
    end

    if characterData.height ~= nil and (characterData.height < GeneralConfig.MinimumHeight or characterData.height > GeneralConfig.MaximumHeight) then
        return false
    end

    return true
end

---@param characterData CharacterData
---@return boolean
function WXPlayer:CreateCharacter(characterData)
    if not validateCharacterData(characterData) then
        print("[FW] Invalid character data provided by license: " .. self.userData.license2)
        return false
    end

    self.mutex:Lock()
    local success = db:CreateCharacter(self.userData.id, characterData)
    self.mutex:Unlock()

    return success
end

---@param characterId number
---@return boolean
function WXPlayer:DeleteCharacter(characterId)
    self.mutex:Lock()
    local success = db:DeleteCharacter(characterId)
    self.mutex:Unlock()

    return success
end

---Loads a character by ID
---@param characterId number
---@return boolean
function WXPlayer:LoadCharacter(characterId)
    self.mutex:Lock()
    local character <const> = db:FetchCharacter(characterId)
    if not character then
        self.mutex:Unlock()
        return false
    end

    if character.inventory ~= nil then
        character.inventory = json.decode(character.inventory)
    end

    self.inventory = inventory.new(character.inventory | {}, GeneralConfig.MaximumPlayerWeight)

    if character.currencies ~= nil then
        character.currencies = json.decode(character.currencies)
    end

    self.currencies:CreateCurrencies(character.currencies)

    if character.metadata ~= nil then
        self.metadata = json.decode(character.metadata)
    end

    self.currentCharacter = {
        id = character.id,
        firstName = character.firstName,
        lastName = character.lastName,
        gender = character.gender
    }

    self.mutex:Unlock()
    return true
end

function WXPlayer:Save()
    self.mutex:Lock()
    local didSave = db:UpdateCharacter({
        firstName = self.currentCharacter.firstName,
        lastName = self.currentCharacter.lastName,
        gender = self.currentCharacter.gender,
        currencies = self.currencies:GetCurrencies(),
        inventory = self.inventory:GetItems(),
        metadata = self.metadata,
        id = self.currentCharacter.id
    })
    self.mutex:Unlock()

    return didSave
end

return WXPlayer
