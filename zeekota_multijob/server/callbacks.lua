ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Callbacks = ZK.Callbacks or {}
ZK.Callbacks.Handlers = {}

function ZK.Callbacks.Register(name, handler)
    ZK.Callbacks.Handlers[name] = handler
end

local function respond(source, requestId, response)
    TriggerClientEvent(ZK.InternalEvent('client:nuiResponse'), source, requestId, response or ZK.Utils.Response(false, 'No response.'))
end

local function adminResponse(source, payload, action, handler)
    local okSession, message, code = ZK.Admin.RequireSession(source, payload.sessionId, action)
    if not okSession then
        return ZK.Utils.Response(false, message, {}, code)
    end

    local okRate, rateMessage, rateCode = ZK.Security.CheckAdminRate(source, action)
    if not okRate then
        return ZK.Utils.Response(false, rateMessage, {}, rateCode)
    end

    local ok, result, extra = pcall(handler)
    if not ok then
        ZK.Error('ADMIN', result)
        return ZK.Utils.Response(false, ZK.Locale('admin_action_failed'))
    end

    if type(result) == 'table' and result.success ~= nil then
        return result
    end

    if result == false then
        return ZK.Utils.Response(false, extra or ZK.Locale('admin_action_failed'))
    end

    return ZK.Utils.Response(true, extra or ZK.Locale('admin_action_completed'), result or {})
end

ZK.Callbacks.Register('getPlayerData', function(source)
    local okRate, rateMessage, rateCode = ZK.Security.CheckPlayerRate(source, 'OpenMenu')
    if not okRate then
        return ZK.Utils.Response(false, rateMessage, {}, rateCode)
    end

    if Config.Sync.ImportCurrentJob then
        ZK.Jobs.ImportCurrent(source, ZK.Security.Actor(source), 'menu_open_import')
    end

    local payload = ZK.Jobs.BuildPlayerPayload(source)
    if not payload.ready then
        return ZK.Utils.Response(false, payload.message or ZK.Locale('error_not_ready'), {}, ZK.Constants.ErrorCodes.NotReady)
    end

    return ZK.Utils.Response(true, 'ok', payload)
end)

ZK.Callbacks.Register('refreshPlayerData', function(source)
    local okRate, rateMessage, rateCode = ZK.Security.CheckPlayerRate(source, 'RefreshJobs')
    if not okRate then
        return ZK.Utils.Response(false, rateMessage, {}, rateCode)
    end

    ZK.Cache.Refresh(source)
    local payload = ZK.Jobs.BuildPlayerPayload(source)
    if not payload.ready then
        return ZK.Utils.Response(false, payload.message or ZK.Locale('error_not_ready'), {}, ZK.Constants.ErrorCodes.NotReady)
    end

    return ZK.Utils.Response(true, 'ok', payload)
end)

ZK.Callbacks.Register('switchJob', function(source, payload)
    return ZK.Jobs.Switch(source, payload.jobName)
end)

ZK.Callbacks.Register('setDuty', function(source, payload)
    return ZK.Jobs.SetDuty(source, payload.onDuty == true)
end)

ZK.Callbacks.Register('openAdmin', function(source)
    local ok, message, code = ZK.Security.RequireAdmin(source, 'OpenAdmin')
    if not ok then
        return ZK.Utils.Response(false, message, {}, code)
    end

    local sessionId = ZK.Admin.CreateSession(source)
    return ZK.Utils.Response(true, 'ok', {
        sessionId = sessionId,
        dashboard = ZK.Admin.Dashboard(),
        online = ZK.Admin.ListOnline('', 1, Config.Admin.PageSize),
        jobs = ZK.Admin.JobCatalog(),
        ui = ZK.Jobs.BuildUIConfig(),
        locale = ZK.Jobs.GetLocalePayload()
    })
end)

ZK.Callbacks.Register('adminDashboard', function(source, payload)
    return adminResponse(source, payload, 'Search', function()
        return ZK.Admin.Dashboard()
    end)
end)

ZK.Callbacks.Register('adminOnlinePlayers', function(source, payload)
    return adminResponse(source, payload, 'Search', function()
        return ZK.Admin.ListOnline(payload.search, payload.page, payload.limit)
    end)
end)

ZK.Callbacks.Register('adminOfflineSearch', function(source, payload)
    return adminResponse(source, payload, 'Search', function()
        return ZK.Admin.SearchOffline(payload.search, payload.page, payload.limit)
    end)
end)

ZK.Callbacks.Register('adminCharacterDetails', function(source, payload)
    return adminResponse(source, payload, 'ViewCharacter', function()
        local character = ZK.Admin.ResolveCharacter(payload.framework, payload.identifier)
        if not character then
            return false, ZK.Locale('admin_character_not_found')
        end

        return ZK.Jobs.CharacterDetails(character.framework, character.identifier)
    end)
end)

ZK.Callbacks.Register('adminHistory', function(source, payload)
    return adminResponse(source, payload, 'ViewHistory', function()
        return ZK.History.List(payload.framework or ZK.Framework, payload.identifier, payload.page, payload.limit)
    end)
end)

ZK.Callbacks.Register('adminJobCatalog', function(source, payload)
    return adminResponse(source, payload, 'Search', function()
        return { jobs = ZK.Admin.JobCatalog() }
    end)
end)

ZK.Callbacks.Register('adminAddJob', function(source, payload)
    return adminResponse(source, payload, 'AddJob', function()
        local ok, message = ZK.Admin.AddJob(source, payload)
        return ok, message
    end)
end)

ZK.Callbacks.Register('adminRemoveJob', function(source, payload)
    return adminResponse(source, payload, 'RemoveJob', function()
        local ok, message = ZK.Admin.RemoveJob(source, payload)
        return ok, message
    end)
end)

ZK.Callbacks.Register('adminChangeGrade', function(source, payload)
    return adminResponse(source, payload, 'ChangeGrade', function()
        local ok, message = ZK.Admin.ChangeGrade(source, payload)
        return ok, message
    end)
end)

ZK.Callbacks.Register('adminSetActive', function(source, payload)
    return adminResponse(source, payload, 'ChangeActiveJob', function()
        local ok, message = ZK.Admin.SetActive(source, payload)
        return ok, message
    end)
end)

ZK.Callbacks.Register('adminSetDuty', function(source, payload)
    return adminResponse(source, payload, 'ChangeDuty', function()
        local ok, message = ZK.Admin.SetDuty(source, payload)
        return ok, message
    end)
end)

ZK.Callbacks.Register('adminSetLimit', function(source, payload)
    return adminResponse(source, payload, 'ChangeJobLimit', function()
        local ok, message = ZK.Admin.SetLimit(source, payload)
        return ok, message
    end)
end)

RegisterNetEvent(ZK.InternalEvent('server:nuiRequest'), function(requestId, name, payload)
    local source = source
    local handler = ZK.Callbacks.Handlers[name]

    if not handler then
        respond(source, requestId, ZK.Utils.Response(false, 'Unknown request.'))
        return
    end

    local ok, result = pcall(handler, source, payload or {})
    if not ok then
        ZK.Error('ERROR', result)
        respond(source, requestId, ZK.Utils.Response(false, ZK.Locale('admin_action_failed')))
        return
    end

    respond(source, requestId, result)
end)
