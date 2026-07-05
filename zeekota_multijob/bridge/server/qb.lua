ZeeKotaMultiJob = ZeeKotaMultiJob or {}
ZeeKotaMultiJob.FrameworkAdapters = ZeeKotaMultiJob.FrameworkAdapters or {}

local ZK = ZeeKotaMultiJob
local QBCore
local adapter = {}

local function getCore()
    if QBCore then
        return QBCore
    end

    local resource = Config.FrameworkResources.qb or 'qb-core'

    if ZK.Utils.HasResource(resource) then
        local ok, object = pcall(function()
            return exports[resource]:GetCoreObject({ 'Functions', 'Shared', 'Players' })
        end)

        if ok and object then
            QBCore = object
        end
    end

    return QBCore
end

local function getPlayer(source)
    local core = getCore()
    if not core or not core.Functions then
        return nil
    end

    local ok, player = pcall(core.Functions.GetPlayer, source)
    if ok then
        return player
    end
end

local function getJobs()
    local core = getCore()
    return core and core.Shared and core.Shared.Jobs or {}
end

local function getJob(jobName)
    local jobs = getJobs()
    return jobs and jobs[jobName]
end

local function getGrade(jobName, grade)
    local job = getJob(jobName)
    if not job or type(job.grades) ~= 'table' then
        return nil
    end

    return job.grades[tostring(grade)] or job.grades[tonumber(grade)]
end

local function normalizeJob(job)
    if not job then
        return {
            name = 'unemployed',
            label = 'Unemployed',
            grade = 0,
            grade_label = 'Unemployed',
            onDuty = Config.Switching.DefaultDutyState
        }
    end

    local grade = job.grade or {}
    local level = type(grade) == 'table' and tonumber(grade.level) or tonumber(grade)

    return {
        name = job.name or 'unemployed',
        label = job.label or job.name or 'Unemployed',
        grade = level or 0,
        grade_label = type(grade) == 'table' and (grade.name or tostring(level or 0)) or tostring(level or 0),
        salary = type(grade) == 'table' and tonumber(grade.payment or job.payment or 0) or tonumber(job.payment or 0),
        onDuty = job.onduty == true
    }
end

local function buildOfflineJob(jobName, grade)
    local job = getJob(jobName)
    local gradeData = getGrade(jobName, grade) or {}

    return {
        name = jobName,
        label = job and job.label or jobName,
        type = job and job.type or 'none',
        onduty = Config.QBCore.DefaultDutyWhenMissing == true,
        isboss = gradeData.isboss == true,
        payment = tonumber(gradeData.payment or job and job.payment or 0) or 0,
        grade = {
            name = gradeData.name or tostring(grade),
            level = tonumber(grade) or 0
        }
    }
end

function adapter.Init()
    local resource = Config.FrameworkResources.qb or 'qb-core'

    if not ZK.Utils.HasResource(resource) then
        return false, 'qb-core is not started'
    end

    QBCore = getCore()
    if not QBCore or not QBCore.Functions then
        return false, 'QBCore export GetCoreObject is unavailable'
    end

    return true
end

function adapter.GetPlayer(source)
    return getPlayer(source)
end

function adapter.IsPlayerLoaded(source)
    return getPlayer(source) ~= nil
end

function adapter.GetCharacterIdentifier(source)
    local player = getPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

function adapter.GetCharacterName(source)
    local player = getPlayer(source)
    local charinfo = player and player.PlayerData and player.PlayerData.charinfo

    if type(charinfo) == 'table' then
        local name = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):match('^%s*(.-)%s*$')
        if name ~= '' then
            return name
        end
    end

    return GetPlayerName(source) or 'Unknown'
end

function adapter.GetCurrentJob(source)
    local player = getPlayer(source)
    return normalizeJob(player and player.PlayerData and player.PlayerData.job)
end

function adapter.GetCurrentGrade(source)
    local job = adapter.GetCurrentJob(source)
    return job and job.grade or 0
end

function adapter.GetDutyState(source)
    local job = adapter.GetCurrentJob(source)
    return job and job.onDuty == true
end

function adapter.GetJobLabel(jobName)
    local job = getJob(jobName)
    return job and job.label or jobName
end

function adapter.GetGradeLabel(jobName, grade)
    local gradeData = getGrade(jobName, grade)
    return gradeData and gradeData.name or tostring(grade)
end

function adapter.GetJobData(jobName)
    return getJob(jobName)
end

function adapter.GetGradeData(jobName, grade)
    return getGrade(jobName, grade)
end

function adapter.GetAllJobs()
    return getJobs()
end

function adapter.JobExists(jobName)
    return getJob(jobName) ~= nil
end

function adapter.GradeExists(jobName, grade)
    return getGrade(jobName, grade) ~= nil
end

function adapter.SetPlayerJob(source, jobName, grade)
    local player = getPlayer(source)
    if not player or not player.Functions or not player.Functions.SetJob then
        return false, 'QBCore player unavailable'
    end

    local ok, result = pcall(player.Functions.SetJob, jobName, tonumber(grade) or 0)
    if not ok or result == false then
        return false, tostring(result)
    end

    if Config.QBCore.SavePlayerAfterJobChange and player.Functions.Save then
        pcall(player.Functions.Save)
    end

    return true
end

function adapter.SetDuty(source, state)
    local player = getPlayer(source)
    if player and player.Functions and player.Functions.SetJobDuty then
        local ok = pcall(player.Functions.SetJobDuty, state == true)
        TriggerClientEvent('QBCore:Client:SetDuty', source, state == true)
        return ok
    end

    Player(source).state:set('zeekota_multijob:duty', state == true, true)
    return true
end

function adapter.GetPermissionGroup(source)
    local player = getPlayer(source)

    if player and player.PlayerData then
        return player.PlayerData.permission or player.PlayerData.group
    end

    return nil
end

function adapter.HasAdminPermission(source)
    local core = getCore()

    if core and core.Functions and core.Functions.HasPermission then
        for _, allowed in ipairs(Config.Admin.Groups.qb or {}) do
            local ok, hasPermission = pcall(core.Functions.HasPermission, source, allowed)
            if ok and hasPermission then
                return true
            end
        end
    end

    local group = adapter.GetPermissionGroup(source)
    for _, allowed in ipairs(Config.Admin.Groups.qb or {}) do
        if group == allowed then
            return true
        end
    end

    return false
end

function adapter.GetOfflineCharacters(search, page, limit)
    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.QBPlayers)
    local query = ZK.Utils.SanitizeText(search or '', 64)
    local pageNumber = math.max(1, tonumber(page) or 1)
    local perPage = ZK.Utils.Clamp(limit, 1, Config.Admin.PageSize or 12)
    local offset = (pageNumber - 1) * perPage
    local like = '%' .. query .. '%'
    local where = query ~= '' and [[
        WHERE citizenid LIKE ?
        OR JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) LIKE ?
        OR JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) LIKE ?
    ]] or ''
    local params = query ~= '' and { like, like, like, perPage, offset } or { perPage, offset }

    local rows = ZK.Database.Query(([[
        SELECT citizenid, charinfo, job
        FROM %s
        %s
        ORDER BY citizenid ASC
        LIMIT ? OFFSET ?
    ]]):format(tableName, where), params) or {}

    local countParams = query ~= '' and { like, like, like } or {}
    local total = ZK.Database.Scalar(('SELECT COUNT(*) FROM %s %s'):format(tableName, where), countParams) or 0
    local characters = {}

    for _, row in ipairs(rows) do
        local charinfo = ZK.Utils.JsonDecode(row.charinfo, {})
        local job = normalizeJob(ZK.Utils.JsonDecode(row.job, {}))
        local name = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):match('^%s*(.-)%s*$')

        characters[#characters + 1] = {
            framework = 'qb',
            identifier = row.citizenid,
            name = name ~= '' and name or row.citizenid,
            job = job.name,
            grade = job.grade
        }
    end

    return {
        characters = characters,
        total = tonumber(total) or 0,
        page = pageNumber,
        limit = perPage
    }
end

function adapter.GetOfflineCharacter(identifier)
    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.QBPlayers)
    local row = ZK.Database.Single(('SELECT citizenid, charinfo, job FROM %s WHERE citizenid = ? LIMIT 1'):format(tableName), { identifier })

    if not row then
        return nil
    end

    local charinfo = ZK.Utils.JsonDecode(row.charinfo, {})
    local job = normalizeJob(ZK.Utils.JsonDecode(row.job, {}))
    local name = ((charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')):match('^%s*(.-)%s*$')

    return {
        framework = 'qb',
        identifier = row.citizenid,
        name = name ~= '' and name or row.citizenid,
        job = job.name,
        grade = job.grade
    }
end

function adapter.UpdateOfflineJob(identifier, jobName, grade)
    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.QBPlayers)
    local jobPayload = ZK.Utils.JsonEncode(buildOfflineJob(jobName, grade))
    local affected = ZK.Database.Update(('UPDATE %s SET job = ? WHERE citizenid = ?'):format(tableName), {
        jobPayload,
        identifier
    })

    return tonumber(affected or 0) > 0
end

ZK.FrameworkAdapters.qb = adapter
