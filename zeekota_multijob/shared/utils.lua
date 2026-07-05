ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Utils = ZK.Utils or {}

function ZK.Utils.Trim(value)
    if type(value) ~= 'string' then
        return ''
    end

    return value:match('^%s*(.-)%s*$')
end

function ZK.Utils.SanitizeText(value, maximumLength)
    local text = ZK.Utils.Trim(value)
    text = text:gsub('[%z\1-\31]', ' ')
    text = text:gsub('%s+', ' ')

    if maximumLength and #text > maximumLength then
        text = text:sub(1, maximumLength)
    end

    return text
end

function ZK.Utils.NormalizeJobName(value)
    local jobName = ZK.Utils.Trim(value):lower()

    if #jobName < 1 or #jobName > 64 then
        return nil
    end

    if not jobName:match('^[%w_%-]+$') then
        return nil
    end

    return jobName
end

function ZK.Utils.NormalizeGrade(value)
    local grade = tonumber(value)

    if not grade or grade ~= grade or grade == math.huge or grade == -math.huge then
        return nil
    end

    grade = math.floor(grade)
    if grade < 0 or grade > 1000 then
        return nil
    end

    return grade
end

function ZK.Utils.ToBoolean(value)
    return value == true or value == 1 or value == '1' or value == 'true'
end

function ZK.Utils.Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum

    if value < minimum then
        return minimum
    end

    if maximum and value > maximum then
        return maximum
    end

    return value
end

function ZK.Utils.Response(success, message, data, code)
    return {
        success = success == true,
        message = message or '',
        data = data or {},
        code = code
    }
end

function ZK.Utils.CopyTable(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}

    for key, item in pairs(value) do
        copy[key] = ZK.Utils.CopyTable(item)
    end

    return copy
end

function ZK.Utils.JsonEncode(value)
    if json and json.encode then
        return json.encode(value or {})
    end

    return '{}'
end

function ZK.Utils.JsonDecode(value, fallback)
    if type(value) ~= 'string' or value == '' or not json or not json.decode then
        return fallback or {}
    end

    local ok, decoded = pcall(json.decode, value)
    if not ok or type(decoded) ~= 'table' then
        return fallback or {}
    end

    return decoded
end

function ZK.Utils.TableCount(tbl)
    local count = 0

    if type(tbl) ~= 'table' then
        return count
    end

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

function ZK.Utils.HasResource(resourceName)
    if type(resourceName) ~= 'string' or resourceName == '' then
        return false
    end

    local state = GetResourceState(resourceName)
    return state == 'started' or state == 'starting'
end

function ZK.Utils.IsExcluded(jobName)
    local rule = Config.ExcludedJobs and Config.ExcludedJobs[jobName]
    return rule ~= nil and rule ~= false, rule
end

function ZK.Utils.CanStoreJob(jobName)
    local excluded, rule = ZK.Utils.IsExcluded(jobName)
    if not excluded then
        return true
    end

    if type(rule) == 'table' then
        return rule.store == true
    end

    return false
end

function ZK.Utils.CanDisplayJob(jobName)
    local excluded, rule = ZK.Utils.IsExcluded(jobName)
    if not excluded then
        return true
    end

    if type(rule) == 'table' then
        return rule.display == true
    end

    return false
end

function ZK.Utils.CanSwitchJob(jobName)
    local excluded, rule = ZK.Utils.IsExcluded(jobName)
    if not excluded then
        return true
    end

    if type(rule) == 'table' then
        return rule.allowSwitch == true
    end

    return false
end

function ZK.Utils.SafeIdentifier(value)
    local text = ZK.Utils.SanitizeText(value or '', 120)
    if text == '' then
        return nil
    end

    return text
end
