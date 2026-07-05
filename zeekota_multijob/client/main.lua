ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

if Config.PlayerMenu.EnableCommand then
    RegisterCommand(Config.PlayerMenu.Command, function()
        ZK.Client.OpenMenu()
    end, false)
end

if Config.PlayerMenu.EnableKeybind then
    RegisterCommand('+zeekota_multijob_menu', function()
        ZK.Client.OpenMenu()
    end, false)

    RegisterCommand('-zeekota_multijob_menu', function()
        ZK.Client.LastKeyRelease = GetGameTimer()
    end, false)
    RegisterKeyMapping('+zeekota_multijob_menu', 'Open ZeeKota Multi Job', 'keyboard', Config.PlayerMenu.DefaultKey)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == ZK.ResourceName then
        ZK.Client.ForceCloseUI()
    end
end)

CreateThread(function()
    Wait(0)
    ZK.Client.ForceCloseUI()
    Wait(500)
    ZK.Client.ForceCloseUI()
    Wait(1500)
    ZK.Client.ForceCloseUI()
end)

exports('OpenMenu', function()
    ZK.Client.OpenMenu()
end)

exports('CloseMenu', function()
    ZK.Client.ForceCloseUI()
end)

exports('IsMenuOpen', function()
    return ZK.Client.IsOpen()
end)

exports('GetDutyState', function()
    return ZK.Client.DutyState == true
end)

exports('GetActiveJob', function()
    return ZK.Client.ActiveJob
end)
