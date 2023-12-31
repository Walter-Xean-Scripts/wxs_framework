---@class Inventory
---@field items table
---@field weight number
---@field maxWeight number
local Inventory = setmetatable({}, {
    __newindex = function(tbl, index, value)
        if not SubFunctions.Inventory then SubFunctions.Inventory = {} end
        table.insert(SubFunctions.Inventory, index)

        rawset(tbl, index, value)
    end
})
local InventoryMutex = Mutex.new()

function Inventory.new(items, maxWeight)
    return setmetatable({
        items = items,
        weight = 0,
        maxWeight = maxWeight
    }, {
        __index = Inventory
    })
end

local function compareMetadata(self, meta1, meta2)
    if meta1 == nil and meta2 == nil then
        return true
    end

    if meta1 == nil or meta2 == nil then
        return false
    end

    for k, v in pairs(meta1) do
        if meta2[k] ~= v then
            return false
        end
    end

    return true
end

function Inventory.UpdateMaxWeight(self, newMaxWeight)
    self.maxWeight = newMaxWeight
end

---Check is the inventory has an item, with an optional amount
---@param item string
---@param amount? number
---@param metadata? table
---@return boolean
function Inventory.HasItem(self, item, amount, metadata)
    local has = false
    for _, v in pairs(self.items) do
        if not metadata or compareMetadata(v.metadata, metadata) then
            if v.name == item and amount == nil or v.amount >= amount then
                has = true
                break
            end
        end
    end

    return has
end

function Inventory.GetItem(self, itemName)
    for _, v in pairs(self.items) do
        if v.name == itemName then
            return v
        end
    end
end

---Adds an item to the inventory, with an optional amount and metadata (Will mutex lock)
---@param item string
---@param amount? number
---@param metadata? table
---@return boolean
function Inventory.AddItem(self, item, amount, metadata)
    local itemData = Items[item]
    if not itemData then
        error("Item does not exist")
        return false
    end

    if not amount then
        amount = 1
    end

    InventoryMutex:Lock()
    local itemsWeight = itemData.weight * amount
    if self.weight + itemsWeight > self.maxWeight then
        InventoryMutex:Unlock()
        return false
    end

    local found = false
    if not itemData.unique then
        for _, v in pairs(self.items) do
            if v.name == item and compareMetadata(v.metadata, metadata) then
                v.amount = v.amount + amount
                found = true
                break
            end
        end
    end

    if not found then
        table.insert(self.items, {
            name = item,
            amount = amount,
            metadata = metadata
        })
    end

    self.weight = self.weight + itemsWeight
    InventoryMutex:Unlock()

    return true
end

---Removes an item from the inventory, with an optional amount (Will mutex lock)
---@param item string
---@param amount number
---@return boolean
function Inventory.RemoveItem(self, item, amount)
    local itemData = Items[item]
    if not itemData then
        error("Item does not exist")
        return false
    end

    InventoryMutex:Lock()

    local found = false
    for _, v in pairs(self.items) do
        if v.name == item then
            if v.amount < amount then
                return false
            end

            v.amount = v.amount - amount
            found = true
            break
        end
    end

    if found then self.weight = self.weight - (itemData.weight * amount) end

    InventoryMutex:Unlock()

    return found
end

---Modifies an item (or a stack) in the inventory, with an optional amount and metadata (Will mutex lock)
---@param item string
---@param oldMetadata? table
---@param newMetadata? table
---@param newAmount? number
---@return boolean
function Inventory.ModifyItem(self, item, oldMetadata, newMetadata, newAmount)
    local itemData = Items[item]
    if not itemData then
        error("Item does not exist")
        return false
    end

    InventoryMutex:Lock()

    local found = false
    for _, v in pairs(self.items) do
        if v.name == item and compareMetadata(v.metadata, oldMetadata) then
            if newMetadata then
                v.metadata = newMetadata
            end

            if newAmount then
                v.amount = newAmount
            end

            found = true
            break
        end
    end

    InventoryMutex:Unlock()

    return found
end

---Get all items in the inventory
---@return table
function Inventory.GetItems(self)
    return self.items
end

function Inventory.CanCarryItem(self, item, count)
    local itemData = Items[item]
    if not itemData then
        error("Item does not exist")
        return false
    end

    if not count then
        count = 1
    end

    return self.weight + (itemData.weight * count) <= self.maxWeight
end

function Inventory.GetWeight(self)
    return self.weight
end

return Inventory
