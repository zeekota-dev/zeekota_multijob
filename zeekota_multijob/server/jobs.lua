ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Jobs = ZK.Jobs or {}

local function bool(value)
    return ZK.Utils.ToBoolean(value)
end

local function normalizeRow(row)
    if not row then
        return nil
    end

    local jobName = row.job_name
    local grade = tonumber(row.job_grade) or 0
    local display = Config.JobDisplay[jobName] or {}
    local gradeData = ZK.Bridge and ZK.Bridge.GetGradeData(jobName, grade) or nil

    return {
        id = tonumber(row.id),
        framework = row.framework,
        character_identifier = row.character_identifier,
        job_name = jobName,
        job_grade = grade,
        is_active = bool(row.is_active),
        is_on_duty = bool(row.is_on_duty),
        assigned_by = row.assigned_by,
        assignment_reason = row.assignment_reason,
        created_at = row.created_at,
        updated_at = row.updated_at,
        revision = tonumber(row.revision) or 0,
        label = display.label or (ZK.Bridge and ZK.Bridge.GetJobLabel(jobName)) or jobName,
        grade_label = gradeData and (gradeData.label or gradeData.name) or (ZK.Bridge and ZK.Bridge.GetGradeLabel(jobName, grade)) or tostring(grade),
        salary = gradeData and tonumber(gradeData.salary or gradeData.payment or 0) or 0,
        description = display.description or '',
        icon = display.icon or 'briefcase',
        color = display.color or Config.UI.Colors.Accent,
        visible = ZK.Utils.CanDisplayJob(jobName),
        can_switch = ZK.Utils.CanSwitchJob(jobName),
        available = ZK.Bridge and ZK.Bridge.JobExists(jobName) and ZK.Bridge.GradeExists(jobName, grade) or false
    }
end

local function normalizeRows(rows)
    local jobs = {}

    for _, row in ipairs(rows or {}) do
        jobs[#jobs + 1] = normalizeRow(row)
    end

    table.sort(jobs, function(a, b)
        if a.is_active ~= b.is_active then
            return a.is_active
        end

        return a.label < b.label
    end)

    return jobs
end

local function publicJob(job)
    return {
        id = job.id,
        name = job.job_name,
        grade = job.job_grade,
        label = job.label,
        gradeLabel = job.grade_label,
        salary = job.salary,
        active = job.is_active,
        onDuty = job.is_on_duty,
        description = job.description,
        icon = job.icon,
        color = job.color,
        visible = job.visible,
        canSwitch = job.can_switch,
        available = job.available,
        revision = job.revision
    }
end

local function updateOnline(framework, identifier)
    local source = ZK.Cache.FindOnlineSource(framework, identifier)
    local jobs = ZK.Jobs.GetStoredJobs(framework, identifier)
    ZK.Cache.UpdateJobs(framework, identifier, jobs)

    if source then
        TriggerClientEvent(ZK.PublicClientEvent('jobsUpdated'), source, ZK.Jobs.BuildPlayerPayload(source))
    end
end

function ZK.Jobs.GetStoredJobs(framework, identifier)
    local rows = ZK.Database.Query([[
        SELECT *
        FROM zeekota_multijob_jobs
        WHERE framework = ? AND character_identifier = ?
        ORDER BY is_active DESC, job_name ASC
    ]], { framework, identifier }) or {}

    return normalizeRows(rows)
end

function ZK.Jobs.GetStoredJob(framework, identifier, jobName)
    local row = ZK.Database.Single([[
        SELECT *
        FROM zeekota_multijob_jobs
        WHERE framework = ? AND character_identifier = ? AND job_name = ?
        LIMIT 1
    ]], { framework, identifier, jobName })

    return normalizeRow(row)
end

function ZK.Jobs.GetActiveJob(framework, identifier)
    local row = ZK.Database.Single([[
        SELECT *
        FROM zeekota_multijob_jobs
        WHERE framework = ? AND character_identifier = ? AND is_active = 1
        ORDER BY updated_at DESC, id DESC
        LIMIT 1
    ]], { framework, identifier })

    return normalizeRow(row)
end

function ZK.Jobs.CountStored(framework, identifier)
    return tonumber(ZK.Database.Scalar([[
        SELECT COUNT(*)
        FROM zeekota_multijob_jobs
        WHERE framework = ? AND character_identifier = ?
    ]], { framework, identifier }) or 0) or 0
end

function ZK.Jobs.BuildUIConfig()
    local colors = {}
    for key, value in pairs(Config.UI.Colors or {}) do
        colors[key] = tostring(value):sub(1, 48)
    end

    local effects = {}
    for key, value in pairs(Config.UI.Effects or {}) do
        effects[key] = value
    end

    return {
        serverName = ZK.Utils.SanitizeText(Config.UI.ServerName, 64),
        serverSubtitle = ZK.Utils.SanitizeText(Config.UI.ServerSubtitle, 80),
        menuTitle = ZK.Utils.SanitizeText(Config.UI.MenuTitle, 40),
        adminMenuTitle = ZK.Utils.SanitizeText(Config.UI.AdminMenuTitle, 60),
        logo = ZK.Utils.SanitizeText(Config.UI.Logo, 180),
        logoFallback = ZK.Utils.SanitizeText(Config.UI.LogoFallback, 180),
        logoWidth = ZK.Utils.Clamp(Config.UI.LogoWidth, 24, 160),
        logoHeight = ZK.Utils.Clamp(Config.UI.LogoHeight, 24, 160),
        showServerName = Config.UI.ShowServerName == true,
        showServerSubtitle = Config.UI.ShowServerSubtitle == true,
        showZeeKotaBranding = Config.UI.ShowZeeKotaBranding == true,
        showSalary = Config.UI.ShowSalary == true,
        showInternalJobName = Config.UI.ShowInternalJobName == true,
        showGradeNumber = Config.UI.ShowGradeNumber == true,
        showJobDescription = Config.UI.ShowJobDescription == true,
        footerText = ZK.Utils.SanitizeText(Config.UI.FooterText, 140),
        colors = colors,
        effects = effects,
        version = Config.Version
    }
end

function ZK.Jobs.GetLocalePayload()
    local locale = Config.Locale or 'en'
    return Locales and (Locales[locale] or Locales.en) or {}
end

function ZK.Jobs.BuildPlayerPayload(source)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return {
            ready = false,
            message = context
        }
    end

    local jobs = ZK.Jobs.GetStoredJobs(context.framework, context.identifier)
    local active = nil
    local visible = {}

    for _, job in ipairs(jobs) do
        if job.is_active then
            active = publicJob(job)
        end

        if job.visible then
            visible[#visible + 1] = publicJob(job)
        end
    end

    local limit = ZK.Limits.GetEffective(context.framework, context.identifier)

    return {
        ready = true,
        framework = context.framework,
        character = {
            identifier = context.identifier,
            name = context.name
        },
        activeJob = active,
        jobs = visible,
        allJobCount = #jobs,
        jobLimit = limit,
        ui = ZK.Jobs.BuildUIConfig(),
        locale = ZK.Jobs.GetLocalePayload()
    }
end

function ZK.Jobs.ImportCurrent(source, actor, reason)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return false, context
    end

    local current = ZK.Bridge.GetCurrentJob(source)
    if not current or not current.name then
        return false, ZK.Locale('error_character')
    end

    local jobName = ZK.Utils.NormalizeJobName(current.name)
    local grade = ZK.Utils.NormalizeGrade(current.grade)

    if not jobName or grade == nil or not ZK.Utils.CanStoreJob(jobName) then
        return true
    end

    if not ZK.Bridge.JobExists(jobName) or not ZK.Bridge.GradeExists(jobName, grade) then
        return false, ZK.Locale('error_invalid_job')
    end

    local existing = ZK.Jobs.GetStoredJob(context.framework, context.identifier, jobName)
    local duty = Config.Sync.ImportDutyState and ZK.Bridge.GetDutyState(source) or Config.Switching.DefaultDutyState
    local activeExists = ZK.Jobs.GetActiveJob(context.framework, context.identifier) ~= nil

    if existing then
        ZK.Database.Update([[
            UPDATE zeekota_multijob_jobs
            SET job_grade = ?, is_active = IF(? = 1, is_active, 1), is_on_duty = ?, updated_at = NOW(), revision = revision + 1
            WHERE framework = ? AND character_identifier = ? AND job_name = ?
        ]], {
            grade,
            activeExists and 1 or 0,
            duty and 1 or 0,
            context.framework,
            context.identifier,
            jobName
        })
    else
        if not activeExists then
            ZK.Database.Update([[
                UPDATE zeekota_multijob_jobs
                SET is_active = 0
                WHERE framework = ? AND character_identifier = ?
            ]], { context.framework, context.identifier })
        end

        ZK.Database.Insert([[
            INSERT INTO zeekota_multijob_jobs
                (framework, character_identifier, job_name, job_grade, is_active, is_on_duty, assigned_by, assignment_reason, created_at, updated_at)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
            ON DUPLICATE KEY UPDATE
                job_grade = VALUES(job_grade),
                is_active = VALUES(is_active),
                is_on_duty = VALUES(is_on_duty),
                updated_at = NOW(),
                revision = revision + 1
        ]], {
            context.framework,
            context.identifier,
            jobName,
            grade,
            activeExists and 0 or 1,
            duty and 1 or 0,
            actor and actor.identifier or 'system',
            reason or 'current_job_import'
        })

        ZK.History.Add({
            framework = context.framework,
            identifier = context.identifier,
            action = ZK.Constants.HistoryActions.Import,
            jobName = jobName,
            newGrade = grade,
            newDuty = duty and 1 or 0,
            reason = reason or 'current_job_import',
            actor = actor
        })
    end

    local jobs = ZK.Jobs.GetStoredJobs(context.framework, context.identifier)
    ZK.Cache.UpdateJobs(context.framework, context.identifier, jobs)
    return true
end

function ZK.Jobs.Switch(source, requestedJobName)
    local rateOk, rateMessage, rateCode = ZK.Security.CheckPlayerRate(source, 'SwitchJob')
    if not rateOk then
        return ZK.Utils.Response(false, rateMessage, {}, rateCode)
    end

    local ok, contextOrMessage, code = ZK.Security.RequireCharacter(source)
    if not ok then
        return ZK.Utils.Response(false, contextOrMessage, {}, code)
    end

    local canSwitch, switchMessage = ZK.Security.CanSwitch(source)
    if not canSwitch then
        return ZK.Utils.Response(false, switchMessage)
    end

    local context = contextOrMessage
    local jobName = ZK.Utils.NormalizeJobName(requestedJobName)
    if not jobName then
        return ZK.Utils.Response(false, ZK.Locale('error_invalid_job'), {}, ZK.Constants.ErrorCodes.InvalidJob)
    end

    if not ZK.Utils.CanSwitchJob(jobName) then
        return ZK.Utils.Response(false, ZK.Locale('player_job_unavailable'), {}, ZK.Constants.ErrorCodes.InvalidJob)
    end

    if not ZK.Cache.Lock(context.framework, context.identifier) then
        return ZK.Utils.Response(false, ZK.Locale('error_operation_busy'), {}, ZK.Constants.ErrorCodes.Busy)
    end

    local previousActive = ZK.Jobs.GetActiveJob(context.framework, context.identifier)
    local target = ZK.Jobs.GetStoredJob(context.framework, context.identifier, jobName)

    if not target then
        ZK.Cache.Unlock(context.framework, context.identifier)
        return ZK.Utils.Response(false, ZK.Locale('error_not_owned'), {}, ZK.Constants.ErrorCodes.NotOwned)
    end

    if not target.available then
        ZK.Cache.Unlock(context.framework, context.identifier)
        return ZK.Utils.Response(false, ZK.Locale('player_job_unavailable'), {}, ZK.Constants.ErrorCodes.InvalidJob)
    end

    if previousActive and previousActive.is_on_duty and Config.Switching.AllowWhileOnDuty ~= true then
        ZK.Cache.Unlock(context.framework, context.identifier)
        return ZK.Utils.Response(false, ZK.Locale('player_cooldown_active'))
    end

    local duty = Config.Switching.RestoreDutyWhenSwitching and target.is_on_duty or Config.Switching.DefaultDutyState
    if Config.Switching.AutoOffDutyWhenSwitching then
        duty = false
    end

    local tx = ZK.Database.Transaction({
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
                SET is_active = 1, is_on_duty = ?, updated_at = NOW(), revision = revision + 1
                WHERE framework = ? AND character_identifier = ? AND job_name = ?
            ]],
            values = { duty and 1 or 0, context.framework, context.identifier, jobName }
        }
    })

    if not tx then
        ZK.Cache.Unlock(context.framework, context.identifier)
        return ZK.Utils.Response(false, ZK.Locale('error_database'), {}, ZK.Constants.ErrorCodes.Database)
    end

    local applied, applyError = ZK.Duty.Apply(source, target.job_name, target.job_grade, duty)
    if not applied then
        if previousActive then
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
                        SET is_active = 1, updated_at = NOW(), revision = revision + 1
                        WHERE framework = ? AND character_identifier = ? AND job_name = ?
                    ]],
                    values = { context.framework, context.identifier, previousActive.job_name }
                }
            })
            ZK.Duty.Apply(source, previousActive.job_name, previousActive.job_grade, previousActive.is_on_duty)
        end

        ZK.Cache.Unlock(context.framework, context.identifier)
        ZK.Error('FRAMEWORK', applyError)
        return ZK.Utils.Response(false, ZK.Locale('error_framework'), {}, ZK.Constants.ErrorCodes.NoFramework)
    end

    ZK.History.Add({
        framework = context.framework,
        identifier = context.identifier,
        action = ZK.Constants.HistoryActions.ActiveJob,
        jobName = target.job_name,
        oldJobName = previousActive and previousActive.job_name or nil,
        oldGrade = previousActive and previousActive.job_grade or nil,
        newGrade = target.job_grade,
        oldDuty = previousActive and (previousActive.is_on_duty and 1 or 0) or nil,
        newDuty = duty and 1 or 0,
        reason = 'player_switch',
        actor = ZK.Security.Actor(source)
    })

    updateOnline(context.framework, context.identifier)
    ZK.Cache.Unlock(context.framework, context.identifier)

    TriggerEvent(ZK.PublicServerEvent('activeJobChanged'), source, target.job_name, target.job_grade)
    TriggerClientEvent(ZK.PublicClientEvent('activeJobChanged'), source, publicJob(ZK.Jobs.GetStoredJob(context.framework, context.identifier, target.job_name)))
    ZK.Notify(source, 'success', ZK.Locale('player_job_switched'))

    return ZK.Utils.Response(true, ZK.Locale('player_job_switched'), ZK.Jobs.BuildPlayerPayload(source))
end

function ZK.Jobs.SetDuty(source, state)
    local rateOk, rateMessage, rateCode = ZK.Security.CheckPlayerRate(source, 'ChangeDuty')
    if not rateOk then
        return ZK.Utils.Response(false, rateMessage, {}, rateCode)
    end

    local ok, contextOrMessage, code = ZK.Security.RequireCharacter(source)
    if not ok then
        return ZK.Utils.Response(false, contextOrMessage, {}, code)
    end

    local context = contextOrMessage
    local active = ZK.Jobs.GetActiveJob(context.framework, context.identifier)
    if not active then
        return ZK.Utils.Response(false, ZK.Locale('player_no_jobs_available'))
    end

    if not ZK.Cache.Lock(context.framework, context.identifier) then
        return ZK.Utils.Response(false, ZK.Locale('error_operation_busy'), {}, ZK.Constants.ErrorCodes.Busy)
    end

    local desired = state == true
    local previous = active.is_on_duty == true
    local updated = ZK.Database.Update([[
        UPDATE zeekota_multijob_jobs
        SET is_on_duty = ?, updated_at = NOW(), revision = revision + 1
        WHERE framework = ? AND character_identifier = ? AND job_name = ?
    ]], { desired and 1 or 0, context.framework, context.identifier, active.job_name })

    if not updated then
        ZK.Cache.Unlock(context.framework, context.identifier)
        return ZK.Utils.Response(false, ZK.Locale('error_database'), {}, ZK.Constants.ErrorCodes.Database)
    end

    local applied, applyError = ZK.Duty.Apply(source, active.job_name, active.job_grade, desired)
    if not applied then
        ZK.Database.Update([[
            UPDATE zeekota_multijob_jobs
            SET is_on_duty = ?, updated_at = NOW(), revision = revision + 1
            WHERE framework = ? AND character_identifier = ? AND job_name = ?
        ]], { previous and 1 or 0, context.framework, context.identifier, active.job_name })

        ZK.Cache.Unlock(context.framework, context.identifier)
        ZK.Error('FRAMEWORK', applyError)
        return ZK.Utils.Response(false, ZK.Locale('error_framework'), {}, ZK.Constants.ErrorCodes.NoFramework)
    end

    ZK.History.Add({
        framework = context.framework,
        identifier = context.identifier,
        action = ZK.Constants.HistoryActions.Duty,
        jobName = active.job_name,
        oldGrade = active.job_grade,
        newGrade = active.job_grade,
        oldDuty = previous and 1 or 0,
        newDuty = desired and 1 or 0,
        reason = 'player_duty',
        actor = ZK.Security.Actor(source)
    })

    updateOnline(context.framework, context.identifier)
    ZK.Cache.Unlock(context.framework, context.identifier)

    TriggerEvent(ZK.PublicServerEvent('dutyChanged'), source, active.job_name, desired)
    TriggerClientEvent(ZK.PublicClientEvent('dutyChanged'), source, { job = active.job_name, onDuty = desired })
    ZK.Notify(source, 'success', ZK.Locale('player_duty_updated'))

    return ZK.Utils.Response(true, ZK.Locale('player_duty_updated'), ZK.Jobs.BuildPlayerPayload(source))
end

function ZK.Jobs.Add(framework, identifier, jobName, grade, duty, active, actor, reason)
    local existing = ZK.Jobs.GetStoredJob(framework, identifier, jobName)
    if existing then
        return false, ZK.Locale('admin_job_already_owned')
    end

    local limit = ZK.Limits.GetEffective(framework, identifier)
    local count = ZK.Jobs.CountStored(framework, identifier)
    if limit ~= Config.JobLimits.UnlimitedValue and count >= limit then
        return false, ZK.Locale('player_maximum_jobs_reached')
    end

    local queries = {}
    if active then
        queries[#queries + 1] = {
            query = [[
                UPDATE zeekota_multijob_jobs
                SET is_active = 0, updated_at = NOW(), revision = revision + 1
                WHERE framework = ? AND character_identifier = ?
            ]],
            values = { framework, identifier }
        }
    end

    queries[#queries + 1] = {
        query = [[
            INSERT INTO zeekota_multijob_jobs
                (framework, character_identifier, job_name, job_grade, is_active, is_on_duty, assigned_by, assignment_reason, created_at, updated_at)
            VALUES
                (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ]],
        values = {
            framework,
            identifier,
            jobName,
            grade,
            active and 1 or 0,
            duty and 1 or 0,
            actor and actor.identifier or 'system',
            reason or ''
        }
    }

    local ok = ZK.Database.Transaction(queries)
    if not ok then
        return false, ZK.Locale('error_database')
    end

    local online = ZK.Cache.FindOnlineSource(framework, identifier)
    if online and active then
        ZK.Duty.Apply(online, jobName, grade, duty)
    end

    ZK.History.Add({
        framework = framework,
        identifier = identifier,
        action = ZK.Constants.HistoryActions.AddJob,
        jobName = jobName,
        newGrade = grade,
        newDuty = duty and 1 or 0,
        reason = reason,
        actor = actor
    })

    updateOnline(framework, identifier)
    TriggerEvent(ZK.PublicServerEvent('jobAdded'), framework, identifier, jobName, grade)
    return true
end

function ZK.Jobs.ChangeGrade(framework, identifier, jobName, grade, actor, reason)
    local existing = ZK.Jobs.GetStoredJob(framework, identifier, jobName)
    if not existing then
        return false, ZK.Locale('error_not_owned')
    end

    local updated = ZK.Database.Update([[
        UPDATE zeekota_multijob_jobs
        SET job_grade = ?, updated_at = NOW(), revision = revision + 1
        WHERE framework = ? AND character_identifier = ? AND job_name = ?
    ]], { grade, framework, identifier, jobName })

    if not updated then
        return false, ZK.Locale('error_database')
    end

    local online = ZK.Cache.FindOnlineSource(framework, identifier)
    if online and existing.is_active then
        ZK.Duty.Apply(online, jobName, grade, existing.is_on_duty)
    end

    ZK.History.Add({
        framework = framework,
        identifier = identifier,
        action = ZK.Constants.HistoryActions.ChangeGrade,
        jobName = jobName,
        oldGrade = existing.job_grade,
        newGrade = grade,
        reason = reason,
        actor = actor
    })

    updateOnline(framework, identifier)
    TriggerEvent(ZK.PublicServerEvent('jobGradeChanged'), framework, identifier, jobName, existing.job_grade, grade)
    return true
end

function ZK.Jobs.SetActive(framework, identifier, jobName, duty, actor, reason)
    local target = ZK.Jobs.GetStoredJob(framework, identifier, jobName)
    if not target then
        return false, ZK.Locale('error_not_owned')
    end

    local previous = ZK.Jobs.GetActiveJob(framework, identifier)
    local desiredDuty = duty
    if desiredDuty == nil then
        desiredDuty = target.is_on_duty
    end

    local ok = ZK.Database.Transaction({
        {
            query = [[
                UPDATE zeekota_multijob_jobs
                SET is_active = 0, updated_at = NOW(), revision = revision + 1
                WHERE framework = ? AND character_identifier = ?
            ]],
            values = { framework, identifier }
        },
        {
            query = [[
                UPDATE zeekota_multijob_jobs
                SET is_active = 1, is_on_duty = ?, updated_at = NOW(), revision = revision + 1
                WHERE framework = ? AND character_identifier = ? AND job_name = ?
            ]],
            values = { desiredDuty and 1 or 0, framework, identifier, jobName }
        }
    })

    if not ok then
        return false, ZK.Locale('error_database')
    end

    local online = ZK.Cache.FindOnlineSource(framework, identifier)
    if online then
        local applied, applyError = ZK.Duty.Apply(online, jobName, target.job_grade, desiredDuty)
        if not applied then
            ZK.Error('FRAMEWORK', applyError)
            return false, ZK.Locale('error_framework')
        end
    elseif ZK.Bridge.UpdateOfflineJob then
        ZK.Bridge.UpdateOfflineJob(identifier, jobName, target.job_grade)
    end

    ZK.History.Add({
        framework = framework,
        identifier = identifier,
        action = ZK.Constants.HistoryActions.ActiveJob,
        jobName = jobName,
        oldJobName = previous and previous.job_name or nil,
        oldGrade = previous and previous.job_grade or nil,
        newGrade = target.job_grade,
        newDuty = desiredDuty and 1 or 0,
        reason = reason,
        actor = actor
    })

    updateOnline(framework, identifier)
    TriggerEvent(ZK.PublicServerEvent('activeJobChanged'), framework, identifier, jobName, target.job_grade)
    return true
end

function ZK.Jobs.SetDutyForCharacter(framework, identifier, jobName, duty, actor, reason)
    local target = ZK.Jobs.GetStoredJob(framework, identifier, jobName)
    if not target then
        return false, ZK.Locale('error_not_owned')
    end

    local updated = ZK.Database.Update([[
        UPDATE zeekota_multijob_jobs
        SET is_on_duty = ?, updated_at = NOW(), revision = revision + 1
        WHERE framework = ? AND character_identifier = ? AND job_name = ?
    ]], { duty and 1 or 0, framework, identifier, jobName })

    if not updated then
        return false, ZK.Locale('error_database')
    end

    local online = ZK.Cache.FindOnlineSource(framework, identifier)
    if online and target.is_active then
        local applied, applyError = ZK.Duty.Apply(online, jobName, target.job_grade, duty)
        if not applied then
            ZK.Error('FRAMEWORK', applyError)
            return false, ZK.Locale('error_framework')
        end
    end

    ZK.History.Add({
        framework = framework,
        identifier = identifier,
        action = ZK.Constants.HistoryActions.Duty,
        jobName = jobName,
        oldGrade = target.job_grade,
        newGrade = target.job_grade,
        oldDuty = target.is_on_duty and 1 or 0,
        newDuty = duty and 1 or 0,
        reason = reason,
        actor = actor
    })

    updateOnline(framework, identifier)
    TriggerEvent(ZK.PublicServerEvent('dutyChanged'), framework, identifier, jobName, duty == true)
    return true
end

function ZK.Jobs.Remove(framework, identifier, jobName, actor, reason)
    local target = ZK.Jobs.GetStoredJob(framework, identifier, jobName)
    if not target then
        return false, ZK.Locale('error_not_owned')
    end

    local fallback
    if target.is_active then
        local jobs = ZK.Jobs.GetStoredJobs(framework, identifier)
        for _, job in ipairs(jobs) do
            if job.job_name ~= jobName and job.available then
                fallback = job
                break
            end
        end
    end

    local queries = {
        {
            query = [[
                DELETE FROM zeekota_multijob_jobs
                WHERE framework = ? AND character_identifier = ? AND job_name = ?
            ]],
            values = { framework, identifier, jobName }
        }
    }

    if fallback then
        queries[#queries + 1] = {
            query = [[
                UPDATE zeekota_multijob_jobs
                SET is_active = 1, updated_at = NOW(), revision = revision + 1
                WHERE framework = ? AND character_identifier = ? AND job_name = ?
            ]],
            values = { framework, identifier, fallback.job_name }
        }
    end

    local ok = ZK.Database.Transaction(queries)
    if not ok then
        return false, ZK.Locale('error_database')
    end

    local online = ZK.Cache.FindOnlineSource(framework, identifier)
    if online and fallback then
        ZK.Duty.Apply(online, fallback.job_name, fallback.job_grade, fallback.is_on_duty)
    elseif online and target.is_active and ZK.Bridge.JobExists('unemployed') and ZK.Bridge.GradeExists('unemployed', 0) then
        ZK.Duty.Apply(online, 'unemployed', 0, false)
    end

    ZK.History.Add({
        framework = framework,
        identifier = identifier,
        action = ZK.Constants.HistoryActions.RemoveJob,
        jobName = jobName,
        oldGrade = target.job_grade,
        oldDuty = target.is_on_duty and 1 or 0,
        reason = reason,
        actor = actor
    })

    updateOnline(framework, identifier)
    TriggerEvent(ZK.PublicServerEvent('jobRemoved'), framework, identifier, jobName)
    return true
end

function ZK.Jobs.CharacterDetails(framework, identifier)
    local jobs = ZK.Jobs.GetStoredJobs(framework, identifier)
    local publicJobs = {}
    for _, job in ipairs(jobs) do
        publicJobs[#publicJobs + 1] = publicJob(job)
    end

    local onlineSource = ZK.Cache.FindOnlineSource(framework, identifier)
    local offline = nil
    if not onlineSource and ZK.Bridge.GetOfflineCharacter then
        offline = ZK.Bridge.GetOfflineCharacter(identifier)
    end

    return {
        framework = framework,
        identifier = identifier,
        online = onlineSource ~= nil,
        source = onlineSource,
        name = onlineSource and (ZK.Cache.Get(onlineSource) and ZK.Cache.Get(onlineSource).name) or (offline and offline.name or identifier),
        jobs = publicJobs,
        jobLimit = ZK.Limits.GetEffective(framework, identifier),
        revision = os.time()
    }
end
