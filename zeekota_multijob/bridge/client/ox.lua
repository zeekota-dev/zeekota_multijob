ZeeKotaMultiJob = ZeeKotaMultiJob or {}
ZeeKotaMultiJob.ClientAdapters = ZeeKotaMultiJob.ClientAdapters or {}

local ZK = ZeeKotaMultiJob
local Ox
local adapter = {}

local function getOx()
    if Ox then
        return Ox
    end

    if rawget(_G, 'Ox') then
        Ox = rawget(_G, 'Ox')
        return Ox
    end

    if GetResourceState(Config.FrameworkResources.ox or 'ox_core') == 'started' and type(require) == 'function' then
        local ok, object = pcall(require, '@ox_core.lib.init')
        if ok and object then
            Ox = object
        end
    end

    return Ox
end

function adapter.Notify()
    return false
end

function adapter.GetActiveJob()
    local core = getOx()
    local player = core and core.GetPlayer and core.GetPlayer()
    if player and player.get then
        local active = player.get('activeGroup')
        if type(active) == 'table' then
            return active.name or active[1]
        end
        return active
    end
end

ZK.ClientAdapters.ox = adapter
