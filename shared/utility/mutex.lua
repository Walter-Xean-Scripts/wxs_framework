---@class Mutex
---@field _locked boolean
---@field _queue table
local Mutex = {}

function Mutex.new()
    return setmetatable({
        _locked = false,
        _queue = {}
    }, {
        __index = Mutex
    })
end

function Mutex:Lock()
    local co = coroutine.running()
    if self._locked then
        table.insert(self._queue, co)
        return coroutine.yield()
    end

    self._locked = true
end

function Mutex:Unlock()
    self._locked = false
    local next = table.remove(self._queue, 1)
    if next then
        coroutine.resume(next)
    end
end

return Mutex
