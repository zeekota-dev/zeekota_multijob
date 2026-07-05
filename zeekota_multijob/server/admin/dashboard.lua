ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Admin = ZK.Admin or {}

function ZK.Admin.Dashboard()
    local stats = ZK.Database.Single([[
        SELECT
            COUNT(*) AS total_jobs,
            COALESCE(SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END), 0) AS active_jobs,
            COALESCE(SUM(CASE WHEN is_on_duty = 1 THEN 1 ELSE 0 END), 0) AS on_duty_jobs,
            COUNT(DISTINCT character_identifier) AS characters
        FROM zeekota_multijob_jobs
        WHERE framework = ?
    ]], { ZK.Framework }) or {}

    return {
        framework = ZK.Framework,
        onlinePlayers = #GetPlayers(),
        cachedPlayers = ZK.Utils.TableCount(ZK.Cache.BySource),
        totalJobs = tonumber(stats.total_jobs) or 0,
        activeJobs = tonumber(stats.active_jobs) or 0,
        onDutyJobs = tonumber(stats.on_duty_jobs) or 0,
        characters = tonumber(stats.characters) or 0
    }
end
