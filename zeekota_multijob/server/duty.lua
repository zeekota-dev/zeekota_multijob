ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Duty = ZK.Duty or {}

function ZK.Duty.ResolveFrameworkJob(jobName, grade, duty)
    if ZK.Framework == 'esx' and Config.ESX.DutyMode == ZK.Constants.DutyModes.OffJob and duty == false then
        local offJob = Config.ESX.OffDutyJobs[jobName]
        if not offJob then
            return nil, nil, ('Missing off-duty job mapping for %s'):format(jobName)
        end

        if not ZK.Bridge.JobExists(offJob) then
            return nil, nil, ('Configured off-duty job %s does not exist'):format(offJob)
        end

        local targetGrade = Config.ESX.PreserveGradeBetweenDutyJobs and grade or 0
        if not ZK.Bridge.GradeExists(offJob, targetGrade) then
            return nil, nil, ('Configured off-duty job %s does not have grade %s'):format(offJob, targetGrade)
        end

        return offJob, targetGrade
    end

    return jobName, grade
end

function ZK.Duty.SetState(source, jobName, duty)
    local state = Player(source).state
    state:set('zeekota_multijob:job', jobName, true)
    state:set('zeekota_multijob:duty', duty == true, true)
end

function ZK.Duty.Apply(source, jobName, grade, duty)
    if not ZK.Bridge then
        return false, 'No framework bridge'
    end

    local applyJob, applyGrade, reason = ZK.Duty.ResolveFrameworkJob(jobName, grade, duty)
    if not applyJob then
        return false, reason
    end

    ZK.Sync.BeginGuard(source)
    local okJob, errJob = ZK.Bridge.SetPlayerJob(source, applyJob, applyGrade)

    if not okJob then
        ZK.Sync.EndGuard(source)
        return false, errJob
    end

    local okDuty, errDuty = ZK.Bridge.SetDuty(source, duty == true)
    ZK.Sync.EndGuard(source)

    if not okDuty then
        return false, errDuty
    end

    ZK.Duty.SetState(source, jobName, duty)
    return true
end

function ZK.Duty.ValidateESXMappings()
    if ZK.Framework ~= 'esx' or Config.ESX.DutyMode ~= ZK.Constants.DutyModes.OffJob then
        return
    end

    for onJob, offJob in pairs(Config.ESX.OffDutyJobs or {}) do
        if not ZK.Bridge.JobExists(onJob) then
            ZK.Log(('Configured on-duty job %s does not exist.'):format(onJob), 'FRAMEWORK')
        end

        if not ZK.Bridge.JobExists(offJob) then
            ZK.Log(('Configured off-duty job %s for %s does not exist.'):format(offJob, onJob), 'FRAMEWORK')
        end
    end
end
