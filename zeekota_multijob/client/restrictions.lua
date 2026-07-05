ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

local function closeIfConfigured()
    if Config.PlayerMenu.CloseWhenDead and ZK.Client.IsOpen() then
        ZK.Client.ForceCloseUI()
    end
end

AddEventHandler('esx:onPlayerDeath', closeIfConfigured)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ZK.Client.ForceCloseUI()
end)
RegisterNetEvent('esx:onPlayerLogout', function()
    ZK.Client.ForceCloseUI()
end)
