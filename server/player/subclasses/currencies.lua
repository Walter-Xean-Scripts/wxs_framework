---@class Currencies
---@field _currencies table<string, number>
local Currencies = setmetatable({}, {
    __newindex = function(tbl, index, value)
        if not SubFunctions.Currencies then SubFunctions.Currencies = {} end
        table.insert(SubFunctions.Currencies, index)

        rawset(tbl, index, value)
    end
})
local CurrencyMutex = Mutex.new()

function Currencies.new()
    local standardCurrencies = {}
    for currency, default in pairs(GeneralConfig.Currencies) do
        standardCurrencies[currency] = default
    end

    return setmetatable({
        _currencies = standardCurrencies
    }, {
        __index = Currencies
    })
end

function Currencies.SetDefault(self)
    local standardCurrencies = {}
    for currency, default in pairs(GeneralConfig.Currencies) do
        standardCurrencies[currency] = default
    end

    self._currencies = standardCurrencies
end

---Get a currency
---@param name string
---@return number
function Currencies.GetCurrency(self, name)
    if not self._currencies[name] then
        error("Currency does not exist")
        return -1
    end

    return self._currencies[name]
end

---Get all currencies
function Currencies.GetCurrencies(self)
    return self._currencies
end

---Add a value to a currency (Will mutex lock)
---@param name string
---@param amount number
---@return number
function Currencies.AddCurrency(self, name, amount)
    if not self._currencies[name] then
        error("Currency does not exist")
        return -1
    end

    if not tonumber(amount) then
        return -1
    end

    if amount < 0 then
        return -1
    end

    CurrencyMutex:Lock()
    self._currencies[name] = self._currencies[name] + amount
    CurrencyMutex:Unlock()

    return self._currencies[name]
end

---Adds multiple values to multiple currency (Will mutex lock)
---@param currencies table<string, number>
function Currencies.AddCurrencies(self, currencies)
    for name, amount in pairs(currencies) do
        self:AddCurrency(name, amount)
    end
end

---Removes a value from a currency (Will mutex lock)
---@param name string
---@param amount number
---@return number
function Currencies.RemoveCurrency(self, name, amount)
    if not self._currencies[name] then
        error("Currency does not exist")
        return -1
    end

    if not tonumber(amount) then
        return -1
    end

    if amount < 0 then
        return -1
    end

    CurrencyMutex:Lock()
    self._currencies[name] = self._currencies[name] - amount
    CurrencyMutex:Unlock()

    return self._currencies[name]
end

---Removes multiple values from multiple currency (Will mutex lock)
---@param currencies table<string, number>
function Currencies.RemoveCurrencies(self, currencies)
    for name, amount in pairs(currencies) do
        self:RemoveCurrency(name, amount)
    end
end

---Set a currency to a value (Will mutex lock)
---@param name string
---@param amount number
---@return number
function Currencies.SetCurrency(self, name, amount)
    if not self._currencies[name] then
        error("Currency does not exist")
        return -1
    end

    CurrencyMutex:Lock()
    self._currencies[name] = amount
    CurrencyMutex:Unlock()

    return self._currencies[name]
end

---Set multiple currencies to multiple values (Will mutex lock)
---@param currencies table<string, number>
function Currencies.SetCurrencies(self, currencies)
    for name, amount in pairs(currencies) do
        self:SetCurrency(name, amount)
    end
end

return Currencies
