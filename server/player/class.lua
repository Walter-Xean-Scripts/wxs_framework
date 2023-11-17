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
local WXPlayer = setmetatable({}, {
    __newindex = function(tbl, key, value)
        table.insert(PlayerFunctions, key)
        rawset(tbl, key, value)
    end,
})

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
    if self.currentCharacter then
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

    self.inventory = inventory.new(character.inventory or {}, GeneralConfig.MaximumPlayerWeight)

    if character.currencies ~= nil then
        character.currencies = json.decode(character.currencies)
    end

    self.currencies:SetCurrencies(character.currencies or {})

    if character.metadata ~= nil then
        self.metadata = json.decode(character.metadata)
    end
    self.metadata.lastSave = os.time()

    self.currentCharacter = {
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
    if not self.currentCharacter then return false end

    self:Save()

    self.currentCharacter = nil
    self.currencies:SetDefault()
    self.inventory = nil
    self.metadata = {}

    return true
end

---Returns true of the player has a loaded character
---@return boolean
function WXPlayer.HasLoadedCharacter(self)
    return self.currentCharacter ~= nil
end

---Sets a metadata value
---@param key string
---@param value any
function WXPlayer.SetMetadata(self, key, value)
    if not self.currentCharacter then return end

    self.metadata[key] = value
end

---Gets a metadata value
---@param key string
---@return unknown
function WXPlayer.GetMetadata(self, key)
    if not self.currentCharacter then return nil end

    return self.metadata[key]
end

---Saves the users character data
---@param onRs boolean|nil on resource stop
---@return boolean
function WXPlayer.Save(self, onRs)
    if not self.currentCharacter then return true end

    local ped = GetPlayerPed(self.source)
    local lastCoords = GetEntityCoords(ped)
    self.metadata.lastCoords = vector3(lastCoords.x, lastCoords.y, lastCoords.z - 1.0)
    self.metadata.lastHeading = GetEntityHeading(ped)

    if not self.metadata.playtime then
        self.metadata.playtime = 0 + os.time() - self.metadata.lastSave
    else
        self.metadata.playtime = self.metadata.playtime + os.time() - self.metadata.lastSave
    end
    self.metadata.lastSave = nil -- we don't want to store this in the database

    local data = {
        firstName = self.currentCharacter.firstName,
        lastName = self.currentCharacter.lastName,
        gender = self.currentCharacter.gender,
        currencies = self.currencies:GetCurrencies(),
        inventory = self.inventory:GetItems(),
        metadata = self.metadata,
        id = self.currentCharacter.id
    }

    self.mutex:Lock()
    local didSave = false
    if onRs then
        didSave = db:UpdateCharacterRS(data)
    else
        didSave = db:UpdateCharacter(data)
    end
    self.mutex:Unlock()

    self.metadata.lastSave = os.time()

    return didSave
end

return WXPlayer
