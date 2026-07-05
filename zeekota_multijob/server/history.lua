ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.History = ZK.History or {}

function ZK.History.Add(data)
    data = data or {}

    local metadata = data.metadata and ZK.Utils.JsonEncode(data.metadata) or '{}'

    local id = ZK.Database.Insert([[
        INSERT INTO zeekota_multijob_history
            (framework, character_identifier, action, job_name, old_job_name, old_grade, new_grade,
             old_duty, new_duty, reason, actor_identifier, actor_name, actor_source, metadata, created_at)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ]], {
        data.framework,
        data.identifier,
        data.action,
        data.jobName,
        data.oldJobName,
        data.oldGrade,
        data.newGrade,
        data.oldDuty,
        data.newDuty,
        data.reason or '',
        data.actor and data.actor.identifier or 'system',
        data.actor and data.actor.name or 'System',
        data.actor and data.actor.source or 0,
        metadata
    })

    if id then
        ZK.SendWebhook('Multi Job Audit', ('%s for %s'):format(data.action or 'action', data.identifier or 'unknown'), 15163718, {
            { name = 'Framework', value = tostring(data.framework or 'unknown'), inline = true },
            { name = 'Job', value = tostring(data.jobName or data.oldJobName or 'none'), inline = true },
            { name = 'Actor', value = tostring(data.actor and data.actor.name or 'System'), inline = true },
            { name = 'Reason', value = tostring(data.reason or 'None'), inline = false }
        })
    end

    return id
end

function ZK.History.List(framework, identifier, page, limit)
    local pageNumber = math.max(1, tonumber(page) or 1)
    local perPage = ZK.Utils.Clamp(limit, 1, Config.Admin.HistoryPageSize or 10)
    local offset = (pageNumber - 1) * perPage

    local rows = ZK.Database.Query([[
        SELECT *
        FROM zeekota_multijob_history
        WHERE framework = ? AND character_identifier = ?
        ORDER BY created_at DESC, id DESC
        LIMIT ? OFFSET ?
    ]], { framework, identifier, perPage, offset }) or {}

    local total = ZK.Database.Scalar([[
        SELECT COUNT(*)
        FROM zeekota_multijob_history
        WHERE framework = ? AND character_identifier = ?
    ]], { framework, identifier }) or 0

    for _, row in ipairs(rows) do
        row.id = tonumber(row.id)
        row.old_grade = tonumber(row.old_grade)
        row.new_grade = tonumber(row.new_grade)
        row.old_duty = ZK.Utils.ToBoolean(row.old_duty)
        row.new_duty = ZK.Utils.ToBoolean(row.new_duty)
        row.metadata = ZK.Utils.JsonDecode(row.metadata, {})
    end

    return {
        history = rows,
        total = tonumber(total) or 0,
        page = pageNumber,
        limit = perPage
    }
end
