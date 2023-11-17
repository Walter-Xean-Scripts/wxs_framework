RegisterCommand("SetCharacterSlots", function(_, args)
    if not args[1] then
        print("^1[FW]^7 You must provide a user id to set slots to.")
        return
    end

    local player = exports.wxs_framework:GetPlayerByUserId(tonumber(args[1]))

    if not args[2] then
        print("^1[FW]^7 You must provide a number of slots to set to user.")
        return
    end

    local newSlots = tonumber(args[2])

    if player then
        player:UpdateCharacterSlots(newSlots)
        print("^2[FW]^7 Updated character slots for user " .. args[1] .. " to " .. newSlots)
    end
end, true)
