ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Client = ZK.Client or {}
ZK.Client.Pending = {}
ZK.Client.RequestId = 0
ZK.Client.MenuOpen = false
ZK.Client.AdminOpen = false
ZK.Client.PlayerData = nil
ZK.Client.AdminData = nil
ZK.Client.ActiveJob = nil
ZK.Client.DutyState = false

function ZK.Client.SetStateFromPayload(payload)
    if not payload then
        return
    end

    ZK.Client.PlayerData = payload
    ZK.Client.ActiveJob = payload.activeJob
    ZK.Client.DutyState = payload.activeJob and payload.activeJob.onDuty == true or false
end

function ZK.Client.IsOpen()
    return ZK.Client.MenuOpen == true or ZK.Client.AdminOpen == true
end
