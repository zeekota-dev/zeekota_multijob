ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Admin = ZK.Admin or {}

local function requireTarget(framework, identifier)
    local character = ZK.Admin.ResolveCharacter(framework, identifier)
    if not character then
        return nil, ZK.Locale('admin_character_not_found')
    end

    return character
end

function ZK.Admin.JobCatalog()
    local jobs = {}
    local allJobs = ZK.Bridge.GetAllJobs() or {}

    for name, job in pairs(allJobs) do
        local grades = {}
        local rawGrades = job.grades or job.Grades or {}

        for gradeKey, gradeData in pairs(rawGrades) do
            local grade = tonumber(gradeKey) or tonumber(gradeData.grade) or 0
            grades[#grades + 1] = {
                grade = grade,
                label = gradeData.label or gradeData.name or tostring(grade),
                salary = tonumber(gradeData.salary or gradeData.payment or 0) or 0
            }
        end

        table.sort(grades, function(a, b)
            return a.grade < b.grade
        end)

        jobs[#jobs + 1] = {
            name = name,
            label = job.label or job.name or name,
            grades = grades
        }
    end

    table.sort(jobs, function(a, b)
        return a.label < b.label
    end)

    return jobs
end

function ZK.Admin.AddJob(adminSource, payload)
    local actor = ZK.Security.Actor(adminSource)
    local target, targetMessage = requireTarget(payload.framework, payload.identifier)
    if not target then
        return false, targetMessage
    end

    local validReason, reason = ZK.Security.ValidateReason(payload.reason, Config.Admin.RequireReason)
    if not validReason then
        return false, reason
    end

    local valid, message, jobName, grade = ZK.Security.ValidateJobAndGrade(payload.jobName, payload.grade)
    if not valid then
        return false, message
    end

    local allowed, allowedMessage = ZK.Security.CanAdminAssign(adminSource, target.identifier, jobName, grade)
    if not allowed then
        return false, allowedMessage
    end

    return ZK.Jobs.Add(target.framework, target.identifier, jobName, grade, payload.onDuty == true, payload.active == true, actor, reason)
end

function ZK.Admin.RemoveJob(adminSource, payload)
    local actor = ZK.Security.Actor(adminSource)
    local target, targetMessage = requireTarget(payload.framework, payload.identifier)
    if not target then
        return false, targetMessage
    end

    local jobName = ZK.Utils.NormalizeJobName(payload.jobName)
    if not jobName then
        return false, ZK.Locale('admin_invalid_job')
    end

    local validReason, reason = ZK.Security.ValidateReason(payload.reason, Config.Admin.RequireReason)
    if not validReason then
        return false, reason
    end

    local allowed, allowedMessage = ZK.Security.CanAdminRemove(adminSource, target.identifier, jobName)
    if not allowed then
        return false, allowedMessage
    end

    return ZK.Jobs.Remove(target.framework, target.identifier, jobName, actor, reason)
end

function ZK.Admin.ChangeGrade(adminSource, payload)
    local actor = ZK.Security.Actor(adminSource)
    local target, targetMessage = requireTarget(payload.framework, payload.identifier)
    if not target then
        return false, targetMessage
    end

    local validReason, reason = ZK.Security.ValidateReason(payload.reason, Config.Admin.RequireReason)
    if not validReason then
        return false, reason
    end

    local valid, message, jobName, grade = ZK.Security.ValidateJobAndGrade(payload.jobName, payload.grade)
    if not valid then
        return false, message
    end

    return ZK.Jobs.ChangeGrade(target.framework, target.identifier, jobName, grade, actor, reason)
end

function ZK.Admin.SetActive(adminSource, payload)
    local actor = ZK.Security.Actor(adminSource)
    local target, targetMessage = requireTarget(payload.framework, payload.identifier)
    if not target then
        return false, targetMessage
    end

    local jobName = ZK.Utils.NormalizeJobName(payload.jobName)
    if not jobName then
        return false, ZK.Locale('admin_invalid_job')
    end

    local validReason, reason = ZK.Security.ValidateReason(payload.reason, Config.Admin.RequireReason)
    if not validReason then
        return false, reason
    end

    return ZK.Jobs.SetActive(target.framework, target.identifier, jobName, payload.onDuty, actor, reason)
end

function ZK.Admin.SetDuty(adminSource, payload)
    local actor = ZK.Security.Actor(adminSource)
    local target, targetMessage = requireTarget(payload.framework, payload.identifier)
    if not target then
        return false, targetMessage
    end

    local jobName = ZK.Utils.NormalizeJobName(payload.jobName)
    if not jobName then
        return false, ZK.Locale('admin_invalid_job')
    end

    local validReason, reason = ZK.Security.ValidateReason(payload.reason, Config.Admin.RequireReason)
    if not validReason then
        return false, reason
    end

    return ZK.Jobs.SetDutyForCharacter(target.framework, target.identifier, jobName, payload.onDuty == true, actor, reason)
end

function ZK.Admin.SetLimit(adminSource, payload)
    local actor = ZK.Security.Actor(adminSource)
    local target, targetMessage = requireTarget(payload.framework, payload.identifier)
    if not target then
        return false, targetMessage
    end

    local validReason, reason = ZK.Security.ValidateReason(payload.reason, Config.Admin.RequireReason)
    if not validReason then
        return false, reason
    end

    local ok, normalized = ZK.Limits.Set(target.framework, target.identifier, payload.limit, actor)
    if ok then
        ZK.History.Add({
            framework = target.framework,
            identifier = target.identifier,
            action = ZK.Constants.HistoryActions.Limit,
            reason = reason,
            actor = actor,
            metadata = { limit = normalized }
        })
    end

    return ok, ok and ZK.Locale('admin_limit_updated') or ZK.Locale('error_database')
end
