---@class Weapons
---@field _equipped table<string, table>
local Weapons = setmetatable({}, {
    __newindex = function(tbl, index, value)
        if not SubFunctions.Weapons then SubFunctions.Weapons = {} end
        table.insert(SubFunctions.Weapons, index)

        rawset(tbl, index, value)
    end
})

function Weapons.new(currentlyEquipped)
    return setmetatable({
        _equipped = currentlyEquipped
    }, {
        __index = Weapons
    })
end

function Weapons.GetEquipped(self)
    return self._equipped
end

function Weapons.EquipWeapon(self, weaponName, weaponData)
    self._equipped[weaponName] = weaponData
end

function Weapons.UnEquipWeapon(self, weaponName)
    self._equipped[weaponName] = nil
end

function Weapons.HasWeapon(self, weaponName)
    return self._equipped[weaponName] ~= nil
end

function Weapons.AddAmmo(self, weaponName, ammoCount)
    if not self._equipped[weaponName] then
        error("Weapon does not exist")
        return
    end

    if not self._equipped[weaponName].ammo then
        self._equipped[weaponName].ammo = 0
    end

    self._equipped[weaponName].ammo = self._equipped[weaponName].ammo + ammoCount
end

function Weapons.EquipAttachment(self, weaponName, attachmentName, attachmentData)
    if not self._equipped[weaponName] then
        error("Weapon does not exist")
        return
    end

    if not self._equipped[weaponName].attachments then
        self._equipped[weaponName].attachments = {}
    end

    self._equipped[weaponName].attachments[attachmentName] = attachmentData
end

function Weapons.UnEquipAttachment(self, weaponName, attachmentName)
    if not self._equipped[weaponName] then
        error("Weapon does not exist")
        return
    end

    if not self._equipped[weaponName].attachments then
        self._equipped[weaponName].attachments = {}
    end

    self._equipped[weaponName].attachments[attachmentName] = nil
end

function Weapons.HasAttachment(self, weaponName, attachmentName)
    if not self._equipped[weaponName] then
        error("Weapon does not exist")
        return
    end

    if not self._equipped[weaponName].attachments then
        self._equipped[weaponName].attachments = {}
    end

    return self._equipped[weaponName].attachments[attachmentName] ~= nil
end

function Weapons.SetTint(self, weaponName, tint)
    if not self._equipped[weaponName] then
        error("Weapon does not exist")
        return
    end

    self._equipped[weaponName].tint = tint
end

return Weapons
