# Offline Management

Offline search uses the selected framework bridge:

- ESX: `users.identifier`, `firstname`, `lastname`, `job`, `job_grade`
- QBCore: `players.citizenid`, `charinfo`, `job`
- ox_core: configured character table and character ID column

Offline add, remove, grade, active, duty, and limit changes update ZeeKota storage immediately. When the character next loads, the active ZeeKota job is reconciled back into the framework.

For ESX and QBCore, active offline job changes also update the framework-owned player table through the bridge where practical.
