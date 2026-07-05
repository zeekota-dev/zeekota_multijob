# ZeeKota Multi Job

ZeeKota Multi Job is a secure multi-job resource for FiveM servers. It stores character-specific jobs, lets players switch jobs and duty status through a custom NUI, and gives administrators an in-game panel for online and offline character job management.

## Features

- ESX Legacy, QBCore, and ox_core bridge architecture.
- Character-specific storage through ESX identifiers, QBCore citizen IDs, or ox_core character IDs.
- oxmysql persistence with job, limit, and audit-history tables.
- Player `/jobs` menu and configurable key mapping.
- Active job, stored jobs, grade labels, duty state, slot usage, and custom job display data.
- Server-authoritative switching, duty changes, job limits, validation, rate limits, and operation locks.
- Administrator panel for online players, offline search, add job, remove job, grade changes, active job, duty, limits, and history.
- Local HTML/CSS/JS NUI with configurable branding and colors.
- Server exports, client exports, and public integration events.
- Discord webhook audit logging support.

## Dependencies

- FiveM artifact with Lua 5.4 support.
- `oxmysql`.
- One supported framework: `es_extended`, `qb-core`, or `ox_core`.

## Installation

1. Import `sql/install.sql`.
2. Place the folder in your resources directory.
3. Configure `config.lua`.
4. Ensure dependencies before this resource.

ESX:

```cfg
ensure oxmysql
ensure es_extended
ensure zeekota_multijob
```

QBCore:

```cfg
ensure oxmysql
ensure qb-core
ensure zeekota_multijob
```

ox_core:

```cfg
ensure oxmysql
ensure ox_core
ensure zeekota_multijob
```

## Framework Selection

`Config.Framework = 'auto'` detects one running supported framework. If multiple supported frameworks are running, set it manually to `esx`, `qb`, or `ox`.

## Duty Modes

ESX supports:

- `state`: ZeeKota stores duty state through database, exports, events, and state bags.
- `offjob`: ZeeKota maps on-duty jobs to configured off-duty jobs.

QBCore uses `Player.Functions.SetJobDuty`. ox_core uses configured status/group behavior where available.

## Commands

- `/jobs`: player menu.
- `/multijobadmin`: administrator panel.

## Branding

All main UI branding, logo paths, colors, and effects are in `config.lua` under `Config.UI`.

## Documentation

- `INSTALL.md`
- `docs/framework-setup.md`
- `docs/admin-panel.md`
- `docs/offline-management.md`
- `docs/exports.md`
- `docs/events.md`
- `docs/custom-integration.md`
- `docs/testing-checklist.md`

## Troubleshooting

- Missing table errors mean `sql/install.sql` was not imported.
- Multiple framework errors mean more than one supported framework is running while `Config.Framework = 'auto'`.
- ESX off-duty errors mean the mapped off-duty job or grade does not exist.
- Admin access requires ACE permission, framework group, or configured identifier access.
