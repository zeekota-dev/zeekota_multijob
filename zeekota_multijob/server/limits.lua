ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Limits = ZK.Limits or {}

function ZK.Limits.GetEffective(framework, identifier)
    local row = ZK.Database.Single([[
        SELECT job_limit
        FROM zeekota_multijob_limits
        WHERE framework = ? AND character_identifier = ?
        LIMIT 1
    ]], { framework, identifier })

    if row and tonumber(row.job_limit) then
        return tonumber(row.job_limit)
    end

    return Config.JobLimits.Default
end

function ZK.Limits.Set(framework, identifier, limit, actor)
    local normalized

    if tonumber(limit) == Config.JobLimits.UnlimitedValue then
        normalized = Config.JobLimits.UnlimitedValue
    else
        normalized = ZK.Utils.Clamp(limit, Config.JobLimits.Minimum, Config.JobLimits.Maximum)
    end

    local affected = ZK.Database.Update([[
        INSERT INTO zeekota_multijob_limits
            (framework, character_identifier, job_limit, changed_by, updated_at)
        VALUES
            (?, ?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE
            job_limit = VALUES(job_limit),
            changed_by = VALUES(changed_by),
            updated_at = NOW(),
            revision = revision + 1
    ]], {
        framework,
        identifier,
        normalized,
        actor and actor.identifier or 'system'
    })

    if affected then
        local source = ZK.Cache.FindOnlineSource(framework, identifier)
        if source then
            local session = ZK.Cache.Get(source)
            if session then
                session.jobLimit = normalized
            end
            TriggerClientEvent(ZK.PublicClientEvent('jobLimitChanged'), source, { limit = normalized })
        end

        TriggerEvent(ZK.PublicServerEvent('jobLimitChanged'), framework, identifier, normalized)
    end

    return affected ~= nil, normalized
end
