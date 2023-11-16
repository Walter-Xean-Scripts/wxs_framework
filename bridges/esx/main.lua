ESX = {}

exports('getSharedObject', function()
    return ESX
end)

local timeoutCount = 0
local cancelledTimeouts = {}
ESX.SetTimeout = function(msec, cb)
    local id <const> = timeoutCount + 1

    SetTimeout(msec, function()
        if cancelledTimeouts[id] then
            cancelledTimeouts[id] = nil
            return
        end

        cb()
    end)

    timeoutCount = id

    return id
end

ESX.ClearTimeout = function(id)
    cancelledTimeouts[id] = true
end


