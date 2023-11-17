GeneralConfig = {}

--[[
    General
]]
GeneralConfig.SaveInterval = 600000 -- 10 seconds

GeneralConfig.Currencies = {        -- the different currencies and their defualt values
    ["money"] = 500,
    ["bank"] = 5000,
    ["black_money"] = 0
}

GeneralConfig.ManagementGroup =
"manager"                           -- The group that by default has every permission, will be auto assigned to the first player that joins.

GeneralConfig.DefaultGroup = "user" -- The group that every player will be assigned to by default.

--[[
    Multicharacter
]]
GeneralConfig.MaximumCharacters = 2 -- How many slots a player without granted slots can have

--[[
    Inventory
]]
GeneralConfig.MaximumPlayerWeight = 50000

--[[
    Character Creation
]]
GeneralConfig.MinimumHeight = 120
GeneralConfig.MaximumHeight = 230

GeneralConfig.MinimumAge = 18
GeneralConfig.MaximumAge = 100

GeneralConfig.MinimumNameLength = 3
GeneralConfig.MaximumNameLength = 28
