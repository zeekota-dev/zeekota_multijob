ZeeKotaMultiJob = ZeeKotaMultiJob or {}
ZeeKotaMultiJob.FrameworkAdapters = ZeeKotaMultiJob.FrameworkAdapters or {}

local ZK = ZeeKotaMultiJob
local ESX
local adapter = {}

local function getESX()
    if ESX then
        return ESX
    end

    local resource = Config.FrameworkResources.esx or 'es_extended'

    if GetResourceState(resource) == 'started' or GetResourceState(resource) == 'starting' then
        local ok, object = pcall(function()
            return exports[resource]:getSharedObject()
        end)

        if ok and object then
            ESX = object
            return ESX
        end
    end

    pcall(function()
        TriggerEvent('esx:getSharedObject', function(object)
            ESX = object
        end)
    end)

    return ESX
end

local function getJobs()
    local core = getESX()
    if not core then
        return {}
    end

    if core.GetJobs then
        local ok, jobs = pcall(core.GetJobs)
        if ok and type(jobs) == 'table' then
            return jobs
        end
    end

    return core.Jobs or {}
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

    local grade = tonumber(job.grade) or 0

    return {
        name = job.name or 'unemployed',
        label = job.label or job.name or 'Unemployed',
        grade = grade,
        grade_label = job.grade_label or job.gradeLabel or job.grade_name or tostring(grade),
        salary = tonumber(job.grade_salary or job.salary or 0) or 0,
        onDuty = nil
    }
end

local function getPlayer(source)
    local core = getESX()
    if not core or not core.GetPlayerFromId then
        return nil
    end

    local ok, player = pcall(core.GetPlayerFromId, source)
    if ok then
        return player
    end
end

function adapter.Init()
    local resource = Config.FrameworkResources.esx or 'es_extended'

    if not ZK.Utils.HasResource(resource) then
        return false, 'es_extended is not started'
    end

    ESX = getESX()
    if not ESX or not ESX.GetPlayerFromId then
        return false, 'es_extended export getSharedObject is unavailable'
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
    if not player then
        return nil
    end

    if player.getIdentifier then
        return player.getIdentifier()
    end

    return player.identifier
end

function adapter.GetCharacterName(source)
    local player = getPlayer(source)
    if not player then
        return 'Unknown'
    end

    if player.getName then
        local name = player.getName()
        if name and name ~= '' then
            return name
        end
    end

    local first = player.get and player.get('firstName') or player.firstname
    local last = player.get and player.get('lastName') or player.lastname

    if first or last then
        return (tostring(first or '') .. ' ' .. tostring(last or '')):match('^%s*(.-)%s*$')
    end

    return GetPlayerName(source) or 'Unknown'
end

function adapter.GetCurrentJob(source)
    local player = getPlayer(source)
    if not player then
        return nil
    end

    local job = player.getJob and player.getJob() or player.job
    return normalizeJob(job)
end

function adapter.GetCurrentGrade(source)
    local job = adapter.GetCurrentJob(source)
    return job and job.grade or 0
end

function adapter.GetDutyState(source)
    local state = Player(source).state
    if state and state['zeekota_multijob:duty'] ~= nil then
        return state['zeekota_multijob:duty'] == true
    end

    return Config.Switching.DefaultDutyState == true
end

function adapter.GetJobLabel(jobName)
    local job = getJob(jobName)
    return job and job.label or jobName
end

function adapter.GetGradeLabel(jobName, grade)
    local gradeData = getGrade(jobName, grade)
    return gradeData and (gradeData.label or gradeData.name) or tostring(grade)
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
    if not player or not player.setJob then
        return false, 'ESX player unavailable'
    end

    local ok, err = pcall(function()
        player.setJob(jobName, tonumber(grade) or 0)
    end)

    if not ok then
        return false, tostring(err)
    end

    return true
end

function adapter.SetDuty(source, state)
    Player(source).state:set('zeekota_multijob:duty', state == true, true)
    return true
end

function adapter.GetPermissionGroup(source)
    local player = getPlayer(source)
    if not player then
        return nil
    end

    if player.getGroup then
        return player.getGroup()
    end

    return player.group
end

function adapter.HasAdminPermission(source)
    local group = adapter.GetPermissionGroup(source)
    if not group then
        return false
    end

    for _, allowed in ipairs(Config.Admin.Groups.esx or {}) do
        if group == allowed then
            return true
        end
    end

    return false
end

function adapter.GetOfflineCharacters(search, page, limit)
    if not ZK.Database then
        return {}
    end

    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.ESXUsers)
    local query = ZK.Utils.SanitizeText(search or '', 64)
    local pageNumber = math.max(1, tonumber(page) or 1)
    local perPage = ZK.Utils.Clamp(limit, 1, Config.Admin.PageSize or 12)
    local offset = (pageNumber - 1) * perPage
    local like = '%' .. query .. '%'

    local where = query ~= '' and 'WHERE identifier LIKE ? OR firstname LIKE ? OR lastname LIKE ? OR CONCAT(firstname, " ", lastname) LIKE ?' or ''
    local params = query ~= '' and { like, like, like, like, perPage, offset } or { perPage, offset }

    local rows = ZK.Database.Query(([[
        SELECT identifier, firstname, lastname, job, job_grade
        FROM %s
        %s
        ORDER BY lastname ASC, firstname ASC
        LIMIT ? OFFSET ?
    ]]):format(tableName, where), params) or {}

    local countParams = query ~= '' and { like, like, like, like } or {}
    local total = ZK.Database.Scalar(('SELECT COUNT(*) FROM %s %s'):format(tableName, where), countParams) or 0
    local characters = {}

    for _, row in ipairs(rows) do
        local name = ((row.firstname or '') .. ' ' .. (row.lastname or '')):match('^%s*(.-)%s*$')
        characters[#characters + 1] = {
            framework = 'esx',
            identifier = row.identifier,
            name = name ~= '' and name or row.identifier,
            job = row.job,
            grade = tonumber(row.job_grade) or 0
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
    if not ZK.Database then
        return nil
    end

    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.ESXUsers)
    local row = ZK.Database.Single(('SELECT identifier, firstname, lastname, job, job_grade FROM %s WHERE identifier = ? LIMIT 1'):format(tableName), { identifier })

    if not row then
        return nil
    end

    local name = ((row.firstname or '') .. ' ' .. (row.lastname or '')):match('^%s*(.-)%s*$')

    return {
        framework = 'esx',
        identifier = row.identifier,
        name = name ~= '' and name or row.identifier,
        job = row.job,
        grade = tonumber(row.job_grade) or 0
    }
end

function adapter.UpdateOfflineJob(identifier, jobName, grade)
    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.ESXUsers)
    local affected = ZK.Database.Update(('UPDATE %s SET job = ?, job_grade = ? WHERE identifier = ?'):format(tableName), {
        jobName,
        tonumber(grade) or 0,
        identifier
    })

    return tonumber(affected or 0) > 0
end

ZK.FrameworkAdapters.esx = adapter
