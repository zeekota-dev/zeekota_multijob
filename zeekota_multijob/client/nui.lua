ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

local function nui(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

local function setFocus(enabled)
    SetNuiFocus(enabled, enabled)
    SetNuiFocusKeepInput(false)
end

function ZK.Client.Request(name, payload, cb)
    ZK.Client.RequestId = ZK.Client.RequestId + 1
    local requestId = ZK.Client.RequestId

    if cb then
        ZK.Client.Pending[requestId] = cb
    end

    TriggerServerEvent(ZK.InternalEvent('server:nuiRequest'), requestId, name, payload or {})
end

RegisterNetEvent(ZK.InternalEvent('client:nuiResponse'), function(requestId, response)
    local cb = ZK.Client.Pending[requestId]
    ZK.Client.Pending[requestId] = nil

    if cb then
        cb(response or ZK.Utils.Response(false, 'No response.'))
    end
end)

function ZK.Client.OpenMenu()
    if ZK.Client.AdminOpen then
        ZK.Client.ForceCloseUI()
    end

    ZK.Client.Request('getPlayerData', {}, function(response)
        if not response or not response.success then
            ZK.Client.Notify(response and response.message or ZK.Locale('error_not_ready'), 'error')
            return
        end

        ZK.Client.SetStateFromPayload(response.data)
        ZK.Client.MenuOpen = true
        ZK.Client.AdminOpen = false
        setFocus(true)
        nui('openPlayer', response.data)
    end)
end

function ZK.Client.OpenAdmin()
    if ZK.Client.MenuOpen then
        ZK.Client.ForceCloseUI()
    end

    ZK.Client.Request('openAdmin', {}, function(response)
        if not response or not response.success then
            ZK.Client.Notify(response and response.message or ZK.Locale('admin_access_denied'), 'error')
            return
        end

        ZK.Client.AdminData = response.data
        ZK.Client.AdminOpen = true
        ZK.Client.MenuOpen = false
        setFocus(true)
        nui('openAdmin', response.data)
    end)
end

function ZK.Client.ForceCloseUI()
    ZK.Client.MenuOpen = false
    ZK.Client.AdminOpen = false
    setFocus(false)
    nui('close')
end

function ZK.Client.Notify(message, notificationType)
    local adapter

    if Config.Framework ~= 'auto' then
        adapter = ZK.ClientAdapters and ZK.ClientAdapters[Config.Framework]
    else
        for framework, resource in pairs(Config.FrameworkResources or {}) do
            if GetResourceState(resource) == 'started' or GetResourceState(resource) == 'starting' then
                adapter = ZK.ClientAdapters and ZK.ClientAdapters[framework]
                break
            end
        end
    end

    if Config.Notify == 'framework' and adapter and adapter.Notify and adapter.Notify(message, notificationType) then
        return
    end

    if not ZK.Client.IsOpen() then
        TriggerEvent('chat:addMessage', {
            color = { 230, 57, 70 },
            multiline = false,
            args = { 'ZeeKota', message }
        })
        return
    end

    nui('toast', {
        type = notificationType or 'info',
        message = message
    })
end

RegisterNUICallback('close', function(_, cb)
    ZK.Client.ForceCloseUI()
    cb(ZK.Utils.Response(true, 'closed'))
end)

RegisterNUICallback('request', function(data, cb)
    local name = data and data.name
    local payload = data and data.payload or {}

    if type(name) ~= 'string' then
        cb(ZK.Utils.Response(false, ZK.Locale('error_invalid_payload')))
        return
    end

    ZK.Client.Request(name, payload, function(response)
        if response and response.success and response.data then
            if name == 'switchJob' or name == 'setDuty' or name == 'refreshPlayerData' then
                ZK.Client.SetStateFromPayload(response.data)
            end
        end

        cb(response or ZK.Utils.Response(false, 'No response.'))
    end)
end)

RegisterNetEvent(ZK.InternalEvent('client:forceClose'), function()
    ZK.Client.ForceCloseUI()
end)

RegisterNetEvent(ZK.InternalEvent('client:openAdmin'), function()
    ZK.Client.OpenAdmin()
end)

RegisterNetEvent(ZK.PublicClientEvent('notify'), function(data)
    data = data or {}
    ZK.Client.Notify(data.message or '', data.type or 'info')
end)

RegisterNetEvent(ZK.PublicClientEvent('jobsUpdated'), function(payload)
    ZK.Client.SetStateFromPayload(payload)
    nui('playerData', payload)
end)

RegisterNetEvent(ZK.PublicClientEvent('activeJobChanged'), function(job)
    ZK.Client.ActiveJob = job
    nui('activeJobChanged', job)
end)

RegisterNetEvent(ZK.PublicClientEvent('dutyChanged'), function(data)
    ZK.Client.DutyState = data and data.onDuty == true
    nui('dutyChanged', data or {})
end)

RegisterNetEvent(ZK.PublicClientEvent('jobLimitChanged'), function(data)
    nui('jobLimitChanged', data or {})
end)
