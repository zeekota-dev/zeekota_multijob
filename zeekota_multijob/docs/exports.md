# Exports

## Server

```lua
local ok, jobs = exports.zeekota_multijob:GetJobs(source)
local ok, job = exports.zeekota_multijob:GetActiveJob(source)
local ok, result = exports.zeekota_multijob:AddJob(source, 'police', 2, 'script', 'promotion')
local ok, result = exports.zeekota_multijob:RemoveJob(source, 'police', 'script', 'removed')
local ok, result = exports.zeekota_multijob:SetActiveJob(source, 'ambulance', 'script')
local ok, result = exports.zeekota_multijob:SetDuty(source, true, 'script')
local onDuty = exports.zeekota_multijob:IsOnDuty(source)
local ok, limit = exports.zeekota_multijob:GetJobLimit(source)
local ok, result = exports.zeekota_multijob:SetCharacterJobLimit('esx', identifier, 5, 'script')
```

Failures return `false, { code = 'ERROR_CODE', message = 'Readable message' }`.

## Client

```lua
exports.zeekota_multijob:OpenMenu()
exports.zeekota_multijob:CloseMenu()
local open = exports.zeekota_multijob:IsMenuOpen()
local onDuty = exports.zeekota_multijob:GetDutyState()
local activeJob = exports.zeekota_multijob:GetActiveJob()
```
