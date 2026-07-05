ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Admin = ZK.Admin or {}

function ZK.Admin.SearchOffline(search, page, limit)
    if not ZK.Bridge or not ZK.Bridge.GetOfflineCharacters then
        return {
            characters = {},
            total = 0,
            page = tonumber(page) or 1,
            limit = tonumber(limit) or Config.Admin.PageSize
        }
    end

    return ZK.Bridge.GetOfflineCharacters(search, page, limit)
end

function ZK.Admin.ResolveCharacter(framework, identifier)
    framework = framework or ZK.Framework
    identifier = ZK.Utils.SafeIdentifier(identifier)

    if not identifier or framework ~= ZK.Framework then
        return nil
    end

    local source = ZK.Cache.FindOnlineSource(framework, identifier)
    if source then
        local session = ZK.Cache.Get(source)
        if session then
            return {
                framework = framework,
                identifier = identifier,
                name = session.name,
                online = true,
                source = source
            }
        end
    end

    local offline = ZK.Bridge.GetOfflineCharacter and ZK.Bridge.GetOfflineCharacter(identifier) or nil
    if offline then
        offline.online = false
        return offline
    end

    local hasRows = ZK.Jobs.CountStored(framework, identifier) > 0
    if hasRows then
        return {
            framework = framework,
            identifier = identifier,
            name = identifier,
            online = false
        }
    end
end
