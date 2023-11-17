local Player = {}

function Player:Get(source)
    return exports.wxs_framework:GetPlayer(source)
end

function Player:GetByUserId(userId)
    return exports.wxs_framework:GetPlayerByUserId(userId)
end

function Player:GetByCharacterId(characterId)
    return exports.wxs_framework:GetPlayerByCharacterId(characterId)
end

return Player
