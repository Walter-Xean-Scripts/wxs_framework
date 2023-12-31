local currencies = require 'server.player.subclasses.currencies'
---@class Inventory
local inventory = require 'server.player.subclasses.inventory'
local db = require 'server.player.database'

---@class CharacterData
---@field currentCharacter table | nil
---@field currencies Currencies
---@field inventory Inventory | nil
---@field metadata table
---@field weapons table

---@class WXPlayer
---@field source number
---@field userData table
---@field character CharacterData
---@field mutex Mutex
local WXPlayer = setmetatable({}, {
    __newindex = function(tbl, key, value)
        table.insert(PlayerFunctions, key)
        rawset(tbl, key, value)
    end,
})

function WXPlayer.new(source, userData, isNew)
    return setmetatable({
        source = source,
        userData = userData,
        isNew = isNew,
        character = {
            currentCharacter = nil,
            ---@type Currencies
            currencies = currencies.new(),
            ---@type Inventory
            inventory = nil,
            metadata = {},
            weapons = {}
        },
        mutex = Mutex.new()
    }, {
        __index = WXPlayer
    })
end

function WXPlayer.UpdateCharacterSlots(self, newSlots)
    self.mutex:Lock()
    local success = db:UpdateCharacterSlots(self.userData.id, newSlots)
    self.mutex:Unlock()

    if success then
        self.userData.characterSlots = newSlots
    end

    return success
end

---Get's the users available characters
---@return table|nil
function WXPlayer.GetCharacters(self)
    return db:FetchCharacters(self.userData.id)
end

---@param characterData CharacterData
local function validateCharacterData(characterData)
    if characterData.firstName == nil or characterData.lastName == nil or characterData.dateOfBirth == nil then
        return false, "Missing required fields"
    end

    if characterData.firstName:len() < GeneralConfig.MinimumNameLength or characterData.firstName:len() > GeneralConfig.MaximumNameLength then
        return false, "First name is too short or too long"
    end

    if characterData.lastName:len() < GeneralConfig.MinimumNameLength or characterData.lastName:len() > GeneralConfig.MaximumNameLength then
        return false, "Last name is too short or too long"
    end

    if type(characterData.firstName) ~= "string" or type(characterData.lastName) ~= "string" or type(characterData.dateOfBirth) ~= "string" then
        return false, "Invalid data types"
    end

    if characterData.gender ~= 1 and characterData.gender ~= 2 then
        return false, "Invalid gender"
    end

    if characterData.height ~= nil and (characterData.height < GeneralConfig.MinimumHeight or characterData.height > GeneralConfig.MaximumHeight) then
        return false, "Invalid height"
    end

    return true
end

---@param characterData CharacterData
---@return boolean
function WXPlayer.CreateCharacter(self, characterData)
    local currentCharacters = db:FetchCharacters(self.userData.id)
    if currentCharacters and #currentCharacters >= self.userData.characterSlots then
        return false
    end

    local success, err = validateCharacterData(characterData)
    if not validateCharacterData(characterData) then
        print("[FW] Failed to create character: " .. err .. " (" .. self.userData.id .. ")")
        return false
    end

    self.mutex:Lock()
    local success = db:CreateCharacter(self.userData.id, characterData)
    self.mutex:Unlock()

    return success
end

---@param characterId number
---@return boolean
function WXPlayer.DeleteCharacter(self, characterId)
    self.mutex:Lock()
    local success = db:DeleteCharacter(characterId)
    self.mutex:Unlock()

    return success
end

---Loads a character by ID
---@param characterId number
---@return boolean
function WXPlayer.LoadCharacter(self, characterId)
    if self.character.currentCharacter then
        return false
    end

    self.mutex:Lock()
    local character <const> = db:FetchCharacter(characterId)
    if not character then
        self.mutex:Unlock()
        return false
    end

    if character.inventory ~= nil then
        character.inventory = json.decode(character.inventory)
    end

    self.character.inventory = inventory.new(character.inventory or {}, GeneralConfig.MaximumPlayerWeight)

    if character.currencies ~= nil then
        character.currencies = json.decode(character.currencies)
    end

    self.character.currencies:SetCurrencies(character.currencies or {})

    if character.metadata ~= nil then
        self.character.metadata = json.decode(character.metadata)
    end

    if self.character.metadata.weapons then
        self.character.weapons = self.character.metadata.weapons
    end

    self.character.metadata.lastSave = os.time()

    self.character.currentCharacter = {
        id = character.id,
        firstName = character.firstName,
        lastName = character.lastName,
        gender = character.gender
    }

    self.mutex:Unlock()

    TriggerEvent("WXS:Server:CharacterLoaded", self.source, self)
    TriggerClientEvent("WXS:Client:CharacterLoaded", self.source, self)
    return true
end

---Unloads (Logs out) a character
---@return boolean
function WXPlayer.UnloadCharacter(self)
    if not self.character.currentCharacter then return false end

    self:Save()

    self.character.currentCharacter = nil
    self.character.currencies:SetDefault()
    self.character.inventory = nil
    self.character.metadata = {}

    return true
end

---Returns true of the player has a loaded character
---@return boolean
function WXPlayer.HasLoadedCharacter(self)
    return self.character.currentCharacter ~= nil
end

---Sets a metadata value
---@param key string
---@param value any
function WXPlayer.SetMetadata(self, key, value)
    if not self.character.currentCharacter then return end

    self.character.metadata[key] = value
end

---Gets a metadata value
---@param key string
---@return unknown
function WXPlayer.GetMetadata(self, key)
    if not self.character.currentCharacter then return nil end

    return self.character.metadata[key]
end

function WXPlayer.UpdateName(self, firstName, lastName)
    if not self.character.currentCharacter then return false end

    self.character.currentCharacter.firstName = firstName
    self.character.currentCharacter.lastName = lastName

    return true
end

---Saves the users character data
---@param onRs boolean|nil on resource stop
---@return boolean
function WXPlayer.Save(self, onRs)
    if not self.character.currentCharacter then return true end

    local ped = GetPlayerPed(self.source)
    local lastCoords = GetEntityCoords(ped)
    self.character.metadata.lastCoords = vector3(lastCoords.x, lastCoords.y, lastCoords.z - 1.0)
    self.character.metadata.lastHeading = GetEntityHeading(ped)

    if not self.character.metadata.playtime then
        self.character.metadata.playtime = 0 + os.time() - self.character.metadata.lastSave
    else
        self.character.metadata.playtime = self.character.metadata.playtime + os.time() -
            self.character.metadata.lastSave
    end
    self.character.metadata.lastSave = nil -- we don't want to store this in the database

    local data = {
        firstName = self.character.currentCharacter.firstName,
        lastName = self.character.currentCharacter.lastName,
        gender = self.character.currentCharacter.gender,
        currencies = self.character.currencies:GetCurrencies(),
        inventory = self.character.inventory:GetItems(),
        metadata = self.character.metadata,
        id = self.character.currentCharacter.id
    }

    self.mutex:Lock()
    local didSave = false
    if onRs then
        didSave = db:UpdateCharacterRS(data)
    else
        didSave = db:UpdateCharacter(data)
    end
    self.mutex:Unlock()

    self.character.metadata.lastSave = os.time()

    return didSave
end

return WXPlayer
