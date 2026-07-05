ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.RateLimits = ZK.RateLimits or {}

local buckets = {}

local function now()
    return GetGameTimer()
end

function ZK.RateLimits.Check(source, action, intervalMs)
    local key = tostring(source or 0) .. ':' .. tostring(action)
    local current = now()
    local nextAllowed = buckets[key] or 0

    if current < nextAllowed then
        return false, nextAllowed - current
    end

    buckets[key] = current + math.max(0, tonumber(intervalMs) or 0)
    return true
end

function ZK.RateLimits.ClearSource(source)
    local prefix = tostring(source or 0) .. ':'

    for key in pairs(buckets) do
        if key:sub(1, #prefix) == prefix then
            buckets[key] = nil
        end
    end
end
