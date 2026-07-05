ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Admin = ZK.Admin or {}

function ZK.Admin.ListOnline(search, page, limit)
    local query = ZK.Utils.SanitizeText(search or '', 64):lower()
    local pageNumber = math.max(1, tonumber(page) or 1)
    local perPage = ZK.Utils.Clamp(limit, 1, Config.Admin.PageSize or 12)
    local players = {}

    for _, playerId in ipairs(GetPlayers()) do
        local source = tonumber(playerId)
        local session = ZK.Cache.Get(source) or ZK.Cache.Refresh(source)

        if session then
            local active = session.activeJob
            local haystack = (session.name .. ' ' .. session.identifier .. ' ' .. tostring(source)):lower()

            if query == '' or haystack:find(query, 1, true) then
                players[#players + 1] = {
                    source = source,
                    framework = session.framework,
                    identifier = session.identifier,
                    name = session.name,
                    job = active and active.job_name or 'none',
                    grade = active and active.job_grade or 0,
                    onDuty = active and active.is_on_duty == true or false,
                    count = #(session.storedJobs or {}),
                    limit = session.jobLimit
                }
            end
        end
    end

    table.sort(players, function(a, b)
        return a.name < b.name
    end)

    local total = #players
    local offset = (pageNumber - 1) * perPage
    local paged = {}

    for i = offset + 1, math.min(total, offset + perPage) do
        paged[#paged + 1] = players[i]
    end

    return {
        players = paged,
        total = total,
        page = pageNumber,
        limit = perPage
    }
end
