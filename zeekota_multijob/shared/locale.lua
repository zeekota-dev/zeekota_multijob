ZeeKotaMultiJob = ZeeKotaMultiJob or {}

local ZK = ZeeKotaMultiJob

function ZK.Locale(key, replacements)
    local locale = Config.Locale or 'en'
    local phrase = Locales
        and Locales[locale]
        and Locales[locale][key]
        or Locales
        and Locales.en
        and Locales.en[key]
        or key

    if type(replacements) == 'table' then
        for name, value in pairs(replacements) do
            phrase = phrase:gsub('{' .. name .. '}', tostring(value))
        end
    end

    return phrase
end
