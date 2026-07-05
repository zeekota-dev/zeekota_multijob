ZeeKotaMultiJob = ZeeKotaMultiJob or {}
ZeeKotaMultiJob.FrameworkAdapters = ZeeKotaMultiJob.FrameworkAdapters or {}

local ZK = ZeeKotaMultiJob
local Ox
local adapter = {}

local function getOx()
    if Ox then
        return Ox
    end

    if rawget(_G, 'Ox') then
        Ox = rawget(_G, 'Ox')
        return Ox
    end

    if ZK.Utils.HasResource(Config.FrameworkResources.ox or 'ox_core') and type(require) == 'function' then
        local ok, object = pcall(require, '@ox_core.lib.init')
        if ok and object then
            Ox = object
        elseif rawget(_G, 'Ox') then
            Ox = rawget(_G, 'Ox')
        end
    end

    return Ox
end

local function call(object, method, ...)
    if object and type(object[method]) == 'function' then
        local ok, result, extra = pcall(object[method], object, ...)
        if ok then
            return result, extra
        end
    end
end

local function getPlayer(source)
    local core = getOx()
    if not core or not core.GetPlayer then
        return nil
    end

    local ok, player = pcall(core.GetPlayer, source)
    if ok then
        return player
    end
end

local function read(player, key)
    if not player then
        return nil
    end

    if player[key] ~= nil then
        return player[key]
    end

    if type(player.get) == 'function' then
        local ok, value = pcall(player.get, player, key)
        if ok then
            return value
        end
    end
end

local function getActiveGroup(player)
    if not player then
        return nil, nil
    end

    local active = read(player, 'activeGroup')
    if type(active) == 'table' then
        return active.name or active[1], tonumber(active.grade or active[2]) or 0
    elseif type(active) == 'string' then
        local grade = call(player, 'getGroup', active)
        return active, tonumber(grade) or 0
    end

    local groupName, grade = call(player, 'getGroupByType', Config.Ox.JobGroupType or 'job')
    if groupName then
        return groupName, tonumber(grade) or 0
    end
end

local function getGroup(jobName)
    local core = getOx()
    if core and core.GetGroup then
        local ok, group = pcall(core.GetGroup, jobName)
        if ok then
            return group
        end
    end
end

local function getGrade(group, grade)
    if not group then
        return nil
    end

    local grades = group.grades or group.Grades
    if type(grades) == 'table' then
        return grades[tostring(grade)] or grades[tonumber(grade)]
    end

    return { label = tostring(grade), name = tostring(grade) }
end

function adapter.Init()
    if not ZK.Utils.HasResource(Config.FrameworkResources.ox or 'ox_core') then
        return false, 'ox_core is not started'
    end

    Ox = getOx()
    if not Ox or not Ox.GetPlayer then
        return false, 'ox_core Lua API unavailable; ensure ox_core is started before zeekota_multijob'
    end

    return true
end

function adapter.GetPlayer(source)
    return getPlayer(source)
end

function adapter.IsPlayerLoaded(source)
    local player = getPlayer(source)
    return player and adapter.GetCharacterIdentifier(source) ~= nil
end

function adapter.GetCharacterIdentifier(source)
    local player = getPlayer(source)
    local charId = read(player, 'charId') or read(player, 'characterId')
    return charId and tostring(charId) or nil
end

function adapter.GetCharacterName(source)
    local player = getPlayer(source)
    local first = read(player, 'firstName') or read(player, 'firstname')
    local last = read(player, 'lastName') or read(player, 'lastname')
    local name = ((first or '') .. ' ' .. (last or '')):match('^%s*(.-)%s*$')

    if name ~= '' then
        return name
    end

    return GetPlayerName(source) or 'Unknown'
end

function adapter.GetCurrentJob(source)
    local player = getPlayer(source)
    local jobName, grade = getActiveGroup(player)
    jobName = jobName or 'unemployed'
    grade = tonumber(grade) or 0

    return {
        name = jobName,
        label = adapter.GetJobLabel(jobName),
        grade = grade,
        grade_label = adapter.GetGradeLabel(jobName, grade),
        salary = 0,
        onDuty = adapter.GetDutyState(source)
    }
end

function adapter.GetCurrentGrade(source)
    local job = adapter.GetCurrentJob(source)
    return job and job.grade or 0
end

function adapter.GetDutyState(source)
    local player = getPlayer(source)
    local statusName = Config.Ox.DutyStatusName or 'duty'
    local status = call(player, 'getStatus', statusName)

    if status ~= nil then
        return tonumber(status) and tonumber(status) > 0 or status == true
    end

    local state = Player(source).state
    return state and state['zeekota_multijob:duty'] == true or Config.Switching.DefaultDutyState == true
end

function adapter.GetJobLabel(jobName)
    local group = getGroup(jobName)
    return group and (group.label or group.name) or jobName
end

function adapter.GetGradeLabel(jobName, grade)
    local gradeData = getGrade(getGroup(jobName), grade)
    return gradeData and (gradeData.label or gradeData.name) or tostring(grade)
end

function adapter.GetJobData(jobName)
    return getGroup(jobName)
end

function adapter.GetGradeData(jobName, grade)
    return getGrade(getGroup(jobName), grade)
end

function adapter.GetAllJobs()
    local core = getOx()
    local groups = {}

    if core and core.GetGroupsByType then
        local ok, names = pcall(core.GetGroupsByType, Config.Ox.JobGroupType or 'job')
        if ok and type(names) == 'table' then
            for _, name in ipairs(names) do
                groups[name] = getGroup(name) or { name = name, label = name }
            end
        end
    end

    return groups
end

function adapter.JobExists(jobName)
    return getGroup(jobName) ~= nil
end

function adapter.GradeExists(jobName, grade)
    return getGrade(getGroup(jobName), grade) ~= nil
end

function adapter.SetPlayerJob(source, jobName, grade)
    local player = getPlayer(source)
    if not player then
        return false, 'ox_core player unavailable'
    end

    local okGroup = call(player, 'setGroup', jobName, tonumber(grade) or 0)
    if okGroup == false or okGroup == nil then
        return false, 'setGroup failed'
    end

    local okActive = call(player, 'setActiveGroup', jobName)
    if okActive == false or okActive == nil then
        return false, 'setActiveGroup failed'
    end

    return true
end

function adapter.SetDuty(source, state)
    local player = getPlayer(source)
    local statusName = Config.Ox.DutyStatusName or 'duty'

    if player and type(player.setStatus) == 'function' then
        local ok = pcall(player.setStatus, player, statusName, state and 100 or 0)
        if ok then
            Player(source).state:set('zeekota_multijob:duty', state == true, true)
            return true
        end
    end

    Player(source).state:set('zeekota_multijob:duty', state == true, true)
    return true
end

function adapter.GetPermissionGroup(source)
    local player = getPlayer(source)
    local groups = call(player, 'getGroups')
    if type(groups) == 'table' then
        for groupName in pairs(groups) do
            return groupName
        end
    end
end

function adapter.HasAdminPermission(source)
    local player = getPlayer(source)

    if player and type(player.hasPermission) == 'function' then
        for _, group in ipairs(Config.Admin.Groups.ox or {}) do
            local ok, allowed = pcall(player.hasPermission, player, 'group.' .. group)
            if ok and allowed then
                return true
            end
        end
    end

    local group = adapter.GetPermissionGroup(source)
    for _, allowed in ipairs(Config.Admin.Groups.ox or {}) do
        if group == allowed then
            return true
        end
    end

    return false
end

function adapter.GetOfflineCharacters(search, page, limit)
    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.OxCharacters)
    local idColumn = ZK.Database.EscapeIdentifier(Config.Ox.CharacterIdColumn or 'charid')
    local query = ZK.Utils.SanitizeText(search or '', 64)
    local pageNumber = math.max(1, tonumber(page) or 1)
    local perPage = ZK.Utils.Clamp(limit, 1, Config.Admin.PageSize or 12)
    local offset = (pageNumber - 1) * perPage
    local like = '%' .. query .. '%'
    local where = query ~= '' and ('WHERE CAST(%s AS CHAR) LIKE ? OR firstName LIKE ? OR lastName LIKE ?'):format(idColumn) or ''
    local params = query ~= '' and { like, like, like, perPage, offset } or { perPage, offset }

    local rows = ZK.Database.Query(('SELECT %s AS identifier, firstName, lastName FROM %s %s ORDER BY %s ASC LIMIT ? OFFSET ?'):format(idColumn, tableName, where, idColumn), params) or {}
    local countParams = query ~= '' and { like, like, like } or {}
    local total = ZK.Database.Scalar(('SELECT COUNT(*) FROM %s %s'):format(tableName, where), countParams) or 0
    local characters = {}

    for _, row in ipairs(rows) do
        local name = ((row.firstName or '') .. ' ' .. (row.lastName or '')):match('^%s*(.-)%s*$')
        characters[#characters + 1] = {
            framework = 'ox',
            identifier = tostring(row.identifier),
            name = name ~= '' and name or tostring(row.identifier),
            job = 'unknown',
            grade = 0
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
    local tableName = ZK.Database.EscapeIdentifier(Config.Database.FrameworkTables.OxCharacters)
    local idColumn = ZK.Database.EscapeIdentifier(Config.Ox.CharacterIdColumn or 'charid')
    local row = ZK.Database.Single(('SELECT %s AS identifier, firstName, lastName FROM %s WHERE %s = ? LIMIT 1'):format(idColumn, tableName, idColumn), {
        identifier
    })

    if not row then
        return nil
    end

    local name = ((row.firstName or '') .. ' ' .. (row.lastName or '')):match('^%s*(.-)%s*$')

    return {
        framework = 'ox',
        identifier = tostring(row.identifier),
        name = name ~= '' and name or tostring(row.identifier),
        job = 'unknown',
        grade = 0
    }
end

function adapter.UpdateOfflineJob()
    return true
end

ZK.FrameworkAdapters.ox = adapter
