ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Ready = false
ZK.Framework = nil
ZK.Bridge = nil

local function runningFrameworks()
    local running = {}

    for framework, resource in pairs(Config.FrameworkResources or {}) do
        if ZK.Constants.SupportedFrameworks[framework] and ZK.Utils.HasResource(resource) then
            running[#running + 1] = framework
        end
    end

    table.sort(running)
    return running
end

local function selectFramework()
    if Config.Framework ~= 'auto' then
        if not ZK.Constants.SupportedFrameworks[Config.Framework] then
            return nil, ('Unsupported framework mode: %s'):format(tostring(Config.Framework))
        end

        return Config.Framework
    end

    local running = runningFrameworks()
    if #running == 0 then
        return nil, ZK.Locale('startup_missing_framework')
    end

    if #running > 1 then
        return nil, ZK.Locale('startup_multiple_frameworks', { frameworks = table.concat(running, ', ') })
    end

    return running[1]
end

local function initialize()
    ZK.Ready = false

    if not ZK.Database.IsAvailable() then
        ZK.Error('DATABASE', 'oxmysql was not available.')
        return false
    end

    local okTables, tableMessage = ZK.Database.ValidateRequiredTables()
    if not okTables then
        ZK.Error('DATABASE', tableMessage)
        return false
    end

    local framework, frameworkError = selectFramework()
    if not framework then
        ZK.Error('FRAMEWORK', frameworkError)
        return false
    end

    local adapter = ZK.FrameworkAdapters and ZK.FrameworkAdapters[framework]
    if not adapter then
        ZK.Error('FRAMEWORK', 'No bridge adapter for ' .. framework)
        return false
    end

    local okBridge, bridgeError = adapter.Init()
    if not okBridge then
        ZK.Error('FRAMEWORK', bridgeError)
        return false
    end

    ZK.Framework = framework
    ZK.Bridge = adapter
    ZK.Ready = true

    ZK.Log(ZK.Locale('startup_framework', { framework = framework }), 'FRAMEWORK')
    ZK.Log(ZK.Locale('startup_db_ready'), 'DATABASE')
    ZK.Duty.ValidateESXMappings()

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        SetTimeout(1000, function()
            ZK.Sync.LoadPlayer(source)
        end)
    end

    ZK.Log(ZK.Locale('startup_ready'), 'INFO')
    return true
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= ZK.ResourceName then
        return
    end

    CreateThread(function()
        Wait(1000)
        initialize()
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= ZK.ResourceName then
        return
    end

    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent(ZK.InternalEvent('client:forceClose'), tonumber(playerId))
    end
end)

AddEventHandler('playerDropped', function()
    ZK.Cache.Clear(source)
    ZK.Admin.ClearSession(source)
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    if ZK.Framework ~= 'esx' then
        return
    end

    SetTimeout(1000, function()
        ZK.Sync.LoadPlayer(tonumber(playerId))
    end)
end)

AddEventHandler('esx:playerLogout', function(playerId)
    local target = tonumber(playerId) or source
    ZK.Cache.Clear(target)
    ZK.Admin.ClearSession(target)
    TriggerClientEvent(ZK.InternalEvent('client:forceClose'), target)
end)

AddEventHandler('esx:setJob', function(playerId)
    if ZK.Framework ~= 'esx' then
        return
    end

    SetTimeout(250, function()
        ZK.Sync.CaptureExternalJob(tonumber(playerId))
    end)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if ZK.Framework ~= 'qb' then
        return
    end

    local target = player and player.PlayerData and player.PlayerData.source
    if target then
        SetTimeout(1000, function()
            ZK.Sync.LoadPlayer(target)
        end)
    end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(playerId)
    local target = tonumber(playerId) or source
    ZK.Cache.Clear(target)
    ZK.Admin.ClearSession(target)
    TriggerClientEvent(ZK.InternalEvent('client:forceClose'), target)
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(playerId)
    if ZK.Framework ~= 'qb' then
        return
    end

    local target = tonumber(playerId) or source
    SetTimeout(250, function()
        ZK.Sync.CaptureExternalJob(target)
    end)
end)

AddEventHandler('ox:playerLoaded', function(playerId)
    if ZK.Framework ~= 'ox' then
        return
    end

    SetTimeout(1000, function()
        ZK.Sync.LoadPlayer(tonumber(playerId))
    end)
end)

AddEventHandler('ox:playerLogout', function(playerId)
    local target = tonumber(playerId) or source
    ZK.Cache.Clear(target)
    ZK.Admin.ClearSession(target)
    TriggerClientEvent(ZK.InternalEvent('client:forceClose'), target)
end)

exports('GetJobs', function(source)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false, { code = ZK.Constants.ErrorCodes.Stale, message = context }
    end

    return true, ZK.Jobs.GetStoredJobs(context.framework, context.identifier)
end)

exports('GetActiveJob', function(source)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false, { code = ZK.Constants.ErrorCodes.Stale, message = context }
    end

    return true, ZK.Jobs.GetActiveJob(context.framework, context.identifier)
end)

exports('AddJob', function(source, jobName, grade, assignedBy, reason)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false, { code = ZK.Constants.ErrorCodes.Stale, message = context }
    end

    local valid, message, normalizedJob, normalizedGrade, code = ZK.Security.ValidateJobAndGrade(jobName, grade)
    if not valid then
        return false, { code = code, message = message }
    end

    local actor = { source = 0, identifier = tostring(assignedBy or 'export'), name = tostring(assignedBy or 'Export') }
    local added, addMessage = ZK.Jobs.Add(context.framework, context.identifier, normalizedJob, normalizedGrade, false, false, actor, reason or 'export')
    return added, added and { job = normalizedJob, grade = normalizedGrade } or { code = ZK.Constants.ErrorCodes.Database, message = addMessage }
end)

exports('RemoveJob', function(source, jobName, removedBy, reason)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false, { code = ZK.Constants.ErrorCodes.Stale, message = context }
    end

    local normalizedJob = ZK.Utils.NormalizeJobName(jobName)
    if not normalizedJob then
        return false, { code = ZK.Constants.ErrorCodes.InvalidJob, message = ZK.Locale('error_invalid_job') }
    end

    local actor = { source = 0, identifier = tostring(removedBy or 'export'), name = tostring(removedBy or 'Export') }
    local removed, removeMessage = ZK.Jobs.Remove(context.framework, context.identifier, normalizedJob, actor, reason or 'export')
    return removed, removed and { job = normalizedJob } or { code = ZK.Constants.ErrorCodes.Database, message = removeMessage }
end)

exports('SetActiveJob', function(source, jobName, reason)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false, { code = ZK.Constants.ErrorCodes.Stale, message = context }
    end

    local normalizedJob = ZK.Utils.NormalizeJobName(jobName)
    if not normalizedJob then
        return false, { code = ZK.Constants.ErrorCodes.InvalidJob, message = ZK.Locale('error_invalid_job') }
    end

    local actor = { source = 0, identifier = 'export', name = 'Export' }
    local active, activeMessage = ZK.Jobs.SetActive(context.framework, context.identifier, normalizedJob, nil, actor, reason or 'export')
    return active, active and { job = normalizedJob, active = true } or { code = ZK.Constants.ErrorCodes.Database, message = activeMessage }
end)

exports('SetDuty', function(source, state, reason)
    local response = ZK.Jobs.SetDuty(source, state == true)
    return response.success, response.success and response.data or { code = response.code, message = response.message, reason = reason }
end)

exports('IsOnDuty', function(source)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false
    end

    local active = ZK.Jobs.GetActiveJob(context.framework, context.identifier)
    return active and active.is_on_duty == true or false
end)

exports('GetJobLimit', function(source)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false, { code = ZK.Constants.ErrorCodes.Stale, message = context }
    end

    return true, ZK.Limits.GetEffective(context.framework, context.identifier)
end)

exports('SetCharacterJobLimit', function(framework, identifier, limit, changedBy)
    if framework ~= ZK.Framework then
        return false, { code = ZK.Constants.ErrorCodes.InvalidJob, message = 'Framework mismatch.' }
    end

    local ok, normalized = ZK.Limits.Set(framework, identifier, limit, {
        source = 0,
        identifier = tostring(changedBy or 'export'),
        name = tostring(changedBy or 'Export')
    })

    return ok, ok and { limit = normalized } or { code = ZK.Constants.ErrorCodes.Database, message = ZK.Locale('error_database') }
end)
