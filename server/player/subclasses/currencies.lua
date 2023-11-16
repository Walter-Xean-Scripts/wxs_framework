---@class Currencies
---@field _currencies table<string, number>
local Currencies = {}
local CurrencyMutex = Mutex.new()

function Currencies.new()
    return setmetatable({
        _currencies = {}
    }, {
        __index = Currencies
    })
end

---Create a new currency
---@param name string
---@param default number
function Currencies:CreateCurrency(name, default)
    if self._currencies[name] then
        error("Currency already exists")
    end

    self._currencies[name] = default
end

---Create multiple currencies
---@param currencies table<string, number>
function Currencies:CreateCurrencies(currencies)
    for name, default in pairs(currencies) do
        self:CreateCurrency(name, default)
    end
end

---Get a currency
---@param name string
---@return number
function Currencies:GetCurrency(name)
    if not self._currencies[name] then
        error("Currency does not exist")
    end

    return self._currencies[name]
end

---Get all currencies
function Currencies:GetCurrencies()
    return self._currencies
end

---Set a currency to a value (Will mutex lock)
---@param name string
---@param amount number
---@return number
function Currencies:ModifyCurrency(name, amount)
    if not self._currencies[name] then
        error("Currency does not exist")
    end

    CurrencyMutex:Lock()
    self._currencies[name] = self._currencies[name] + amount
    CurrencyMutex:Unlock()

    return self._currencies[name]
end

---Set multiple currencies to values (Will mutex lock)
---@param currencies table<string, number>
function Currencies:ModifyCurrencies(currencies)
    for name, amount in pairs(currencies) do
        self:ModifyCurrency(name, amount)
    end
end

return Currencies
