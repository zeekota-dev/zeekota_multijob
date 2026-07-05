ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Cache = ZK.Cache or {}
ZK.Cache.BySource = {}
ZK.Cache.ByIdentifier = {}
ZK.Cache.Locks = {}

local function key(framework, identifier)
    return tostring(framework) .. ':' .. tostring(identifier)
end

function ZK.Cache.Key(framework, identifier)
    return key(framework, identifier)
end

function ZK.Cache.Get(source)
    return ZK.Cache.BySource[tonumber(source)]
end

function ZK.Cache.GetByIdentifier(framework, identifier)
    return ZK.Cache.ByIdentifier[key(framework, identifier)]
end

function ZK.Cache.Set(source, session)
    source = tonumber(source)
    if not source or not session then
        return
    end

    session.source = source
    session.sessionRevision = session.sessionRevision or math.random(100000, 999999)
    ZK.Cache.BySource[source] = session
    ZK.Cache.ByIdentifier[key(session.framework, session.identifier)] = session
end

function ZK.Cache.Refresh(source)
    local ok, context = ZK.Security.RequireCharacter(source)
    if not ok then
        return nil
    end

    local storedJobs = ZK.Jobs and ZK.Jobs.GetStoredJobs(context.framework, context.identifier) or {}
    local activeJob = nil

    for _, job in ipairs(storedJobs) do
        if job.is_active then
            activeJob = job
            break
        end
    end

    local session = {
        framework = context.framework,
        identifier = context.identifier,
        name = context.name,
        activeJob = activeJob,
        dutyState = activeJob and activeJob.is_on_duty or false,
        storedJobs = storedJobs,
        jobLimit = ZK.Limits and ZK.Limits.GetEffective(context.framework, context.identifier) or Config.JobLimits.Default,
        loaded = true,
        sessionRevision = math.random(100000, 999999)
    }

    ZK.Cache.Set(source, session)
    return session
end

function ZK.Cache.UpdateJobs(framework, identifier, jobs)
    local session = ZK.Cache.GetByIdentifier(framework, identifier)
    if not session then
        return
    end

    session.storedJobs = jobs or {}
    session.activeJob = nil

    for _, job in ipairs(session.storedJobs) do
        if job.is_active then
            session.activeJob = job
            session.dutyState = job.is_on_duty == true
            break
        end
    end
end

function ZK.Cache.Clear(source)
    source = tonumber(source)
    local session = source and ZK.Cache.BySource[source]

    if session then
        ZK.Cache.ByIdentifier[key(session.framework, session.identifier)] = nil
    end

    if source then
        ZK.Cache.BySource[source] = nil
        ZK.RateLimits.ClearSource(source)
    end
end

function ZK.Cache.Lock(framework, identifier)
    local lockKey = key(framework, identifier)

    if ZK.Cache.Locks[lockKey] then
        return false
    end

    ZK.Cache.Locks[lockKey] = GetGameTimer()
    return true
end

function ZK.Cache.Unlock(framework, identifier)
    ZK.Cache.Locks[key(framework, identifier)] = nil
end

function ZK.Cache.FindOnlineSource(framework, identifier)
    local session = ZK.Cache.GetByIdentifier(framework, identifier)
    return session and session.source or nil
end
