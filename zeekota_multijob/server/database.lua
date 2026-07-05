ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

ZK.Database = ZK.Database or {}

local function dbReady()
    return MySQL ~= nil
        and MySQL.query
        and MySQL.query.await
        and MySQL.single
        and MySQL.single.await
        and MySQL.scalar
        and MySQL.scalar.await
        and MySQL.update
        and MySQL.update.await
        and MySQL.insert
        and MySQL.insert.await
        and true
end

function ZK.Database.IsAvailable()
    return dbReady() == true
end

function ZK.Database.EscapeIdentifier(identifier)
    local value = tostring(identifier or '')

    if not value:match('^[%w_]+$') then
        error(('Unsafe SQL identifier: %s'):format(value))
    end

    return ('`%s`'):format(value)
end

function ZK.Database.Query(query, params)
    if not dbReady() then
        return nil, 'oxmysql unavailable'
    end

    local ok, result = pcall(function()
        return MySQL.query.await(query, params or {}) or {}
    end)

    if not ok then
        ZK.Error('DATABASE', result)
        return nil, result
    end

    return result
end

function ZK.Database.Single(query, params)
    if not dbReady() then
        return nil, 'oxmysql unavailable'
    end

    local ok, result = pcall(function()
        return MySQL.single.await(query, params or {})
    end)

    if not ok then
        ZK.Error('DATABASE', result)
        return nil, result
    end

    return result
end

function ZK.Database.Scalar(query, params)
    if not dbReady() then
        return nil, 'oxmysql unavailable'
    end

    local ok, result = pcall(function()
        return MySQL.scalar.await(query, params or {})
    end)

    if not ok then
        ZK.Error('DATABASE', result)
        return nil, result
    end

    return result
end

function ZK.Database.Update(query, params)
    if not dbReady() then
        return nil, 'oxmysql unavailable'
    end

    local ok, result = pcall(function()
        return MySQL.update.await(query, params or {}) or 0
    end)

    if not ok then
        ZK.Error('DATABASE', result)
        return nil, result
    end

    return result
end

function ZK.Database.Insert(query, params)
    if not dbReady() then
        return nil, 'oxmysql unavailable'
    end

    local ok, result = pcall(function()
        return MySQL.insert.await(query, params or {})
    end)

    if not ok then
        ZK.Error('DATABASE', result)
        return nil, result
    end

    return result
end

function ZK.Database.Transaction(queries)
    if not dbReady() or not MySQL.transaction or not MySQL.transaction.await then
        return false, 'oxmysql transaction unavailable'
    end

    local ok, result = pcall(function()
        return MySQL.transaction.await(queries)
    end)

    if not ok then
        ZK.Error('DATABASE', result)
        return false, result
    end

    return result == true
end

function ZK.Database.TableExists(tableName)
    local count = ZK.Database.Scalar([[
        SELECT COUNT(*)
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?
    ]], { tableName })

    return tonumber(count or 0) > 0
end

function ZK.Database.ValidateRequiredTables()
    if not Config.Database.ValidateTables then
        return true
    end

    for _, tableName in ipairs(Config.Database.RequiredTables or {}) do
        if not ZK.Database.TableExists(tableName) then
            return false, ZK.Locale('startup_missing_table', { table = tableName })
        end
    end

    return true
end
