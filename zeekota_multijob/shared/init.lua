ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.ResourceName = GetCurrentResourceName()

function ZK.Event(name)
    return ('%s:%s'):format(ZK.Constants.EventPrefix, name)
end

function ZK.InternalEvent(name)
    return ('%s:internal:%s'):format(ZK.Constants.EventPrefix, name)
end

function ZK.PublicServerEvent(name)
    return ('%s:server:%s'):format(ZK.Constants.EventPrefix, name)
end

function ZK.PublicClientEvent(name)
    return ('%s:client:%s'):format(ZK.Constants.EventPrefix, name)
end
