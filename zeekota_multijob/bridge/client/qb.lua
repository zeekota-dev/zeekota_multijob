ZeeKotaMultiJob = ZeeKotaMultiJob or {}
ZeeKotaMultiJob.ClientAdapters = ZeeKotaMultiJob.ClientAdapters or {}

local ZK = ZeeKotaMultiJob
local QBCore
local adapter = {}

local function getCore()
    if QBCore then
        return QBCore
    end

    local resource = Config.FrameworkResources.qb or 'qb-core'
    if GetResourceState(resource) == 'started' or GetResourceState(resource) == 'starting' then
        local ok, object = pcall(function()
            return exports[resource]:GetCoreObject({ 'Functions' })
        end)

        if ok and object then
            QBCore = object
        end
    end

    return QBCore
end

function adapter.Notify(message, notificationType)
    local core = getCore()
    if core and core.Functions and core.Functions.Notify then
        core.Functions.Notify(message, notificationType or 'primary')
        return true
    end

    return false
end

function adapter.GetActiveJob()
    local core = getCore()
    local data = core and core.Functions and core.Functions.GetPlayerData and core.Functions.GetPlayerData()
    return data and data.job and data.job.name or nil
end

ZK.ClientAdapters.qb = adapter
