# Framework Setup

## ESX

Modern ESX Legacy is supported through `exports.es_extended:getSharedObject()`.

For state duty mode:

```lua
Config.Framework = 'esx'
Config.ESX.DutyMode = 'state'
```

For off-job duty mode, create the mapped off-duty jobs and matching grades in ESX:

```lua
Config.ESX.DutyMode = 'offjob'
Config.ESX.OffDutyJobs = {
    police = 'offpolice',
    ambulance = 'offambulance'
}
```

## QBCore

QBCore uses citizen IDs, `QBCore.Shared.Jobs`, `Player.Functions.SetJob`, and `Player.Functions.SetJobDuty`.

```lua
Config.Framework = 'qb'
```

## ox_core

ox_core uses character IDs and group APIs. Configure the group type if your server uses a custom one:

```lua
Config.Framework = 'ox'
Config.Ox.JobGroupType = 'job'
```

Offline ox_core management stores ZeeKota job records and reconciles active jobs on login. If your ox_core schema uses a different character table or ID column, update `Config.Database.FrameworkTables.OxCharacters` and `Config.Ox.CharacterIdColumn`.
