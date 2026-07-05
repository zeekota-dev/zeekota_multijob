ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Sync = ZK.Sync or {}
ZK.Sync.Guards = {}

function ZK.Sync.BeginGuard(source)
    ZK.Sync.Guards[tonumber(source)] = GetGameTimer() + 2500
end

function ZK.Sync.EndGuard(source)
    SetTimeout(500, function()
        ZK.Sync.Guards[tonumber(source)] = nil
    end)
end

function ZK.Sync.IsGuarded(source)
    local expires = ZK.Sync.Guards[tonumber(source)]
    if not expires then
        return false
    end

    if GetGameTimer() > expires then
        ZK.Sync.Guards[tonumber(source)] = nil
        return false
    end

    return true
end

function ZK.Sync.LoadPlayer(source)
    if not ZK.Ready then
        return
    end

    local ok = ZK.Security.RequireCharacter(source)
    if not ok then
        return
    end

    if Config.Sync.ImportCurrentJob then
        ZK.Jobs.ImportCurrent(source, ZK.Security.Actor(source), 'login_import')
    end

    local session = ZK.Cache.Refresh(source)

    if Config.Sync.ReconcileOnLogin and session and session.activeJob then
        ZK.Duty.Apply(source, session.activeJob.job_name, session.activeJob.job_grade, session.activeJob.is_on_duty)
    end
end

function ZK.Sync.CaptureExternalJob(source)
    if not Config.Sync.CaptureExternalJobChanges or ZK.Sync.IsGuarded(source) or not ZK.Ready then
        return
    end

    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return
    end

    local current = ZK.Bridge.GetCurrentJob(source)
    if not current or not current.name then
        return
    end

    local jobName = ZK.Utils.NormalizeJobName(current.name)
    local grade = ZK.Utils.NormalizeGrade(current.grade)
    if not jobName or grade == nil or not ZK.Utils.CanStoreJob(jobName) then
        return
    end

    if not ZK.Bridge.JobExists(jobName) or not ZK.Bridge.GradeExists(jobName, grade) then
        return
    end

    local existing = ZK.Jobs.GetStoredJob(context.framework, context.identifier, jobName)
    local duty = ZK.Bridge.GetDutyState(source)

    if existing then
        ZK.Database.Transaction({
            {
                query = [[
                    UPDATE zeekota_multijob_jobs
                    SET is_active = 0, updated_at = NOW(), revision = revision + 1
                    WHERE framework = ? AND character_identifier = ?
                ]],
                values = { context.framework, context.identifier }
            },
            {
                query = [[
                    UPDATE zeekota_multijob_jobs
                    SET is_active = 1, job_grade = ?, is_on_duty = ?, updated_at = NOW(), revision = revision + 1
                    WHERE framework = ? AND character_identifier = ? AND job_name = ?
                ]],
                values = { grade, duty and 1 or 0, context.framework, context.identifier, jobName }
            }
        })
    else
        local limit = ZK.Limits.GetEffective(context.framework, context.identifier)
        local count = ZK.Jobs.CountStored(context.framework, context.identifier)
        if limit ~= Config.JobLimits.UnlimitedValue and count >= limit then
            return
        end

        ZK.Database.Transaction({
            {
                query = [[
                    UPDATE zeekota_multijob_jobs
                    SET is_active = 0, updated_at = NOW(), revision = revision + 1
                    WHERE framework = ? AND character_identifier = ?
                ]],
                values = { context.framework, context.identifier }
            },
            {
                query = [[
                    INSERT INTO zeekota_multijob_jobs
                        (framework, character_identifier, job_name, job_grade, is_active, is_on_duty, assigned_by, assignment_reason, created_at, updated_at)
                    VALUES
                        (?, ?, ?, ?, 1, ?, 'external', 'external_job_sync', NOW(), NOW())
                ]],
                values = { context.framework, context.identifier, jobName, grade, duty and 1 or 0 }
            }
        })
    end

    ZK.History.Add({
        framework = context.framework,
        identifier = context.identifier,
        action = ZK.Constants.HistoryActions.Sync,
        jobName = jobName,
        newGrade = grade,
        newDuty = duty and 1 or 0,
        reason = 'external_job_sync',
        actor = { source = 0, identifier = 'external', name = 'External Resource' }
    })

    ZK.Cache.Refresh(source)
    TriggerClientEvent(ZK.PublicClientEvent('jobsUpdated'), source, ZK.Jobs.BuildPlayerPayload(source))
end
