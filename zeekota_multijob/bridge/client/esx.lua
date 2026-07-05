ZeeKotaMultiJob = ZeeKotaMultiJob or {}
ZeeKotaMultiJob.ClientAdapters = ZeeKotaMultiJob.ClientAdapters or {}

local ZK = ZeeKotaMultiJob
local ESX
local adapter = {}

local function getESX()
    if ESX then
        return ESX
    end

    local resource = Config.FrameworkResources.esx or 'es_extended'
    if GetResourceState(resource) == 'started' or GetResourceState(resource) == 'starting' then
        local ok, object = pcall(function()
            return exports[resource]:getSharedObject()
        end)

        if ok and object then
            ESX = object
        end
    end

    return ESX
end

function adapter.Notify(message, notificationType)
    local core = getESX()
    if core and core.ShowNotification then
        core.ShowNotification(message)
        return true
    end

    return false
end

function adapter.GetActiveJob()
    local core = getESX()
    local job = core and core.PlayerData and core.PlayerData.job
    return job and job.name or nil
end

ZK.ClientAdapters.esx = adapter
