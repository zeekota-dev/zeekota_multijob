ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

RegisterCommand(Config.Admin.Command, function(source)
    if source == 0 then
        ZK.Log('Open the administrator panel in-game with /' .. Config.Admin.Command, 'ADMIN')
        return
    end

    local ok, message = ZK.Security.RequireAdmin(source, 'OpenAdminCommand')
    if not ok then
        ZK.Notify(source, 'error', message)
        return
    end

    TriggerClientEvent(ZK.InternalEvent('client:openAdmin'), source)
end, false)
