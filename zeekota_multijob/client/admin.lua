ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

RegisterCommand(Config.Admin.Command, function()
    ZK.Client.OpenAdmin()
end, false)
