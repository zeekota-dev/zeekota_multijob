ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Security = ZK.Security or {}

local function bridge()
    return ZK.Bridge
end

local function identifiers(source)
    local list = {}

    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        list[#list + 1] = GetPlayerIdentifier(source, i)
    end

    return list
end

function ZK.Security.CheckPlayerRate(source, action)
    local interval = Config.RateLimits[action] or 750
    local ok = ZK.RateLimits.Check(source, 'player:' .. action, interval)

    if not ok then
        return false, ZK.Locale('error_rate_limited'), ZK.Constants.ErrorCodes.RateLimited
    end

    return true
end

function ZK.Security.CheckAdminRate(source, action)
    local interval = Config.Admin.RateLimits[action] or 1000
    local ok = ZK.RateLimits.Check(source, 'admin:' .. action, interval)

    if not ok then
        return false, ZK.Locale('error_rate_limited'), ZK.Constants.ErrorCodes.RateLimited
    end

    return true
end

function ZK.Security.RequireReady()
    if ZK.Ready then
        return true
    end

    return false, ZK.Locale('error_not_ready'), ZK.Constants.ErrorCodes.NotReady
end

function ZK.Security.GetCharacterContext(source)
    local currentBridge = bridge()
    if not currentBridge then
        return nil
    end

    local identifier = currentBridge.GetCharacterIdentifier(source)
    if not identifier then
        return nil
    end

    return {
        source = source,
        framework = ZK.Framework,
        identifier = identifier,
        name = currentBridge.GetCharacterName(source),
        currentJob = currentBridge.GetCurrentJob(source)
    }
end

function ZK.Security.RequireCharacter(source)
    local ok, message, code = ZK.Security.RequireReady()
    if not ok then
        return false, message, code
    end

    if not bridge() or not bridge().IsPlayerLoaded(source) then
        return false, ZK.Locale('error_character'), ZK.Constants.ErrorCodes.Stale
    end

    local context = ZK.Security.GetCharacterContext(source)
    if not context then
        return false, ZK.Locale('error_character'), ZK.Constants.ErrorCodes.Stale
    end

    return true, context
end

function ZK.Security.HasAdminPermission(source)
    if not Config.Admin.Enabled then
        return false
    end

    if source == 0 then
        return true
    end

    if Config.Admin.AllowAce and IsPlayerAceAllowed(source, Config.Admin.AcePermission) then
        return true
    end

    if Config.Admin.AllowIdentifiers then
        local allowed = {}
        for _, identifier in ipairs(Config.Admin.Identifiers or {}) do
            allowed[identifier] = true
        end

        for _, identifier in ipairs(identifiers(source)) do
            if allowed[identifier] then
                return true
            end
        end
    end

    if Config.Admin.AllowFrameworkGroups and bridge() and bridge().HasAdminPermission then
        return bridge().HasAdminPermission(source) == true
    end

    return false
end

function ZK.Security.RequireAdmin(source, action)
    local ok, message, code = ZK.Security.RequireReady()
    if not ok then
        return false, message, code
    end

    if ZK.Security.HasAdminPermission(source) then
        return true
    end

    ZK.SecurityLog(source, action or 'admin_denied', 'Denied administrator action.')
    return false, ZK.Locale('admin_access_denied'), ZK.Constants.ErrorCodes.Permission
end

function ZK.Security.Actor(source)
    if source == 0 then
        return {
            source = 0,
            identifier = 'console',
            name = 'Console'
        }
    end

    local context = ZK.Security.GetCharacterContext(source)
    return {
        source = source,
        identifier = context and context.identifier or GetPlayerIdentifier(source, 0) or tostring(source),
        name = context and context.name or GetPlayerName(source) or tostring(source)
    }
end

function ZK.Security.ValidateReason(reason, required)
    local text = ZK.Utils.SanitizeText(reason or '', Config.Admin.ReasonMaxLength or 180)

    if required and text == '' then
        return false, ZK.Locale('admin_reason_required')
    end

    return true, text
end

function ZK.Security.ValidateJobAndGrade(jobName, grade)
    local normalizedJob = ZK.Utils.NormalizeJobName(jobName)
    if not normalizedJob then
        return false, ZK.Locale('error_invalid_job'), nil, nil, ZK.Constants.ErrorCodes.InvalidJob
    end

    local normalizedGrade = ZK.Utils.NormalizeGrade(grade)
    if normalizedGrade == nil then
        return false, ZK.Locale('error_invalid_grade'), nil, nil, ZK.Constants.ErrorCodes.InvalidGrade
    end

    if not bridge() or not bridge().JobExists(normalizedJob) then
        return false, ZK.Locale('error_invalid_job'), nil, nil, ZK.Constants.ErrorCodes.InvalidJob
    end

    if not bridge().GradeExists(normalizedJob, normalizedGrade) then
        return false, ZK.Locale('error_invalid_grade'), nil, nil, ZK.Constants.ErrorCodes.InvalidGrade
    end

    return true, nil, normalizedJob, normalizedGrade
end

function ZK.Security.IsPlayerDead(source)
    if not source or source == 0 then
        return false
    end

    local state = Player(source).state
    if state and (state.dead == true or state.isDead == true) then
        return true
    end

    local ped = GetPlayerPed(source)
    return ped ~= 0 and GetEntityHealth(ped) <= 0
end

function ZK.Security.CanSwitch(source)
    if Config.Switching.BlockWhileDead and ZK.Security.IsPlayerDead(source) then
        return false, ZK.Locale('player_cannot_switch_dead')
    end

    if Config.Switching.BlockWhileCuffed and Config.Restrictions.IsPlayerCuffed(source) then
        return false, ZK.Locale('player_cannot_switch_cuffed')
    end

    if Config.Switching.BlockDuringCombat and Config.Restrictions.IsPlayerInCombat(source) then
        return false, ZK.Locale('player_cannot_switch_combat')
    end

    return true
end

function ZK.Security.CanAdminAssign(adminSource, targetIdentifier, jobName, grade)
    if Config.ProtectedJobs[jobName] then
        return false, ZK.Locale('admin_protected_job')
    end

    local excluded, rule = ZK.Utils.IsExcluded(jobName)
    if excluded and type(rule) == 'table' and rule.allowAdminAssign == false then
        return false, ZK.Locale('admin_invalid_job')
    end

    local ok, result = pcall(Config.Restrictions.CanAssignJob, adminSource, targetIdentifier, jobName, grade)
    if ok and result == false then
        return false, ZK.Locale('admin_invalid_job')
    end

    return true
end

function ZK.Security.CanAdminRemove(adminSource, targetIdentifier, jobName)
    if Config.ProtectedJobs[jobName] then
        return false, ZK.Locale('admin_protected_job')
    end

    local ok, result = pcall(Config.Restrictions.CanRemoveJob, adminSource, targetIdentifier, jobName)
    if ok and result == false then
        return false, ZK.Locale('admin_protected_job')
    end

    return true
end
