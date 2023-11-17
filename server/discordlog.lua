--[[
    Since I've read that a webhook without a bot token can do 30 requests per minute, I've decided to make a queue system.
    This way we should avoid being rate limited. Hopefully. (You hopefully won't need to send that many requests per minute anyway)
]]
local DiscordLog = {}
local queue = {}
local requestsPerMinute = 30
local requestsMade = {}
local shouldRunQueueChecks = false

local noop = function() end
local function sendToDiscord(webhook, embed)
    PerformHttpRequest(webhook, noop, 'POST', json.encode({
        username = 'WXS Logs',
        embeds = embed
    }), {
        ['Content-Type'] = 'application/json'
    })
end

local function messageEmbed(title, message)
    return { {
        ['title'] = title,
        ['color'] = 255,
        ['description'] = message,
        ['footer'] = {
            ['text'] = "" .. os.date()
        },
        ['author'] = {
            ['name'] = "WXS Framework",
            ['icon_url'] = "https://i.imgur.com/OzEiOS9.png"
        }
    } }
end

local function fieldsEmbed(title, fields)
    return { {
        ['title'] = title,
        ['color'] = 255,
        ['fields'] = fields,
        ['footer'] = {
            ['text'] = "" .. os.date()
        },
        ['author'] = {
            ['name'] = "WXS Framework",
            ['icon_url'] = "https://i.imgur.com/OzEiOS9.png"
        }
    } }
end

local function processQueue()
    for webhook, requests in pairs(requestsMade) do
        for i = #requests, 1, -1 do
            if os.time() - requests[i] > 60 then
                table.remove(requests, i)
            end
        end
    end

    for i = #queue, 1, -1 do
        local webhook = queue[i].webhook
        local title = queue[i].title
        local message = queue[i].message

        if requestsMade[webhook] < requestsPerMinute then
            table.insert(requestsMade[webhook], os.time())
            sendToDiscord(webhook, messageEmbed(title, message))

            table.remove(queue, i)
        end
    end

    if #queue == 0 then
        shouldRunQueueChecks = false
    end
end

local function startQueueThread()
    CreateThread(function()
        while shouldRunQueueChecks do
            Wait(1000)

            processQueue()
        end
    end)
end

function DiscordLog:Send(webhook, title, message)
    if requestsMade[webhook] == nil then
        requestsMade[webhook] = {}
    end

    processQueue()

    if #requestsMade[webhook] < requestsPerMinute then
        table.insert(requestsMade[webhook], os.time())

        sendToDiscord(webhook, messageEmbed(title, message))
    else
        table.insert(queue, {
            webhook = webhook,
            title = title,
            message = message
        })

        if not shouldRunQueueChecks then
            shouldRunQueueChecks = true
            startQueueThread()
        end
    end
end

function DiscordLog:SendWithFields(webhook, title, fields)
    if requestsMade[webhook] == nil then
        requestsMade[webhook] = {}
    end

    processQueue()

    if #requestsMade[webhook] < requestsPerMinute then
        table.insert(requestsMade[webhook], os.time())

        sendToDiscord(webhook, fieldsEmbed(title, fields))
    else
        table.insert(queue, {
            webhook = webhook,
            title = title,
            fields = fields
        })

        if not shouldRunQueueChecks then
            shouldRunQueueChecks = true
            startQueueThread()
        end
    end
end

return DiscordLog
