ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Admin = ZK.Admin or {}
ZK.Admin.Sessions = ZK.Admin.Sessions or {}

function ZK.Admin.CreateSession(source)
    local id = ('%d:%d:%d'):format(source, GetGameTimer(), math.random(100000, 999999))
    ZK.Admin.Sessions[source] = {
        id = id,
        expires = GetGameTimer() + 1800000
    }

    return id
end

function ZK.Admin.RequireSession(source, sessionId, action)
    local ok, message, code = ZK.Security.RequireAdmin(source, action)
    if not ok then
        return false, message, code
    end

    local session = ZK.Admin.Sessions[source]
    if not session or session.id ~= sessionId or GetGameTimer() > session.expires then
        return false, ZK.Locale('admin_stale_character_data'), ZK.Constants.ErrorCodes.Stale
    end

    session.expires = GetGameTimer() + 1800000
    return true
end

function ZK.Admin.ClearSession(source)
    ZK.Admin.Sessions[source] = nil
end
