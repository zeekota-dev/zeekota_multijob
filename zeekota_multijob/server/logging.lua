ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

local function prefix(scope)
    return ('[%s] [%s]'):format(ZK.Constants.DisplayName, scope or 'INFO')
end

function ZK.Log(message, scope)
    print(('%s %s'):format(prefix(scope or 'INFO'), tostring(message)))
end

function ZK.Debug(message)
    if Config.Debug then
        ZK.Log(message, 'DEBUG')
    end
end

function ZK.Error(scope, message)
    ZK.Log(tostring(message), scope or 'ERROR')
end

function ZK.SecurityLog(source, action, message)
    local safeMessage = tostring(message or '')
    ZK.Log(('source=%s action=%s %s'):format(tostring(source or 'console'), tostring(action or 'unknown'), safeMessage), 'SECURITY')
end

function ZK.SendWebhook(title, description, color, fields)
    if not Config.Webhooks.Enabled or Config.Webhooks.Url == '' then
        return
    end

    local payload = {
        username = Config.Webhooks.Username,
        avatar_url = Config.Webhooks.AvatarUrl ~= '' and Config.Webhooks.AvatarUrl or nil,
        content = Config.Webhooks.MentionRole ~= '' and Config.Webhooks.MentionRole or nil,
        embeds = {
            {
                title = tostring(title or ZK.Constants.DisplayName),
                description = tostring(description or ''),
                color = tonumber(color or 15163718),
                fields = fields or {},
                footer = { text = ZK.Constants.DisplayName },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
    }

    PerformHttpRequest(Config.Webhooks.Url, function(statusCode)
        if Config.Debug and tonumber(statusCode) and tonumber(statusCode) >= 300 then
            ZK.Debug(('webhook returned HTTP %s'):format(statusCode))
        end
    end, 'POST', ZK.Utils.JsonEncode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

function ZK.Notify(source, notificationType, message)
    if not source or source == 0 then
        return
    end

    if Config.Notify == 'custom' and type(Config.CustomNotify) == 'function' then
        Config.CustomNotify(source, message, notificationType)
        return
    end

    TriggerClientEvent(ZK.PublicClientEvent('notify'), source, {
        type = notificationType or 'info',
        message = message
    })
end
