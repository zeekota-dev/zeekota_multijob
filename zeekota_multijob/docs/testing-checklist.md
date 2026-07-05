# Testing Checklist

## Startup

- ESX, QBCore, and ox_core manual modes reject missing frameworks.
- Auto mode rejects zero frameworks.
- Auto mode rejects multiple frameworks.
- Missing SQL tables block startup with a clear message.
- Resource restart closes open UI.

## Player

- `/jobs` opens.
- Key mapping opens.
- Escape and close button release focus.
- Current job imports on first open/login.
- Stored job switches.
- Invalid and unowned jobs are rejected.
- Duty toggles and persists according to config.
- Reconnect restores active job.

## Admin

- Unauthorized players are rejected.
- Online search works.
- Offline search works.
- Add job enforces limit and duplicates.
- Change grade rejects invalid grades.
- Active job changes keep one active row.
- Removal applies fallback when possible.
- Job limit changes persist.
- History records actions.

## Security

- Forged NUI actions cannot add jobs without admin permission.
- Client-provided grades are ignored for player switching.
- Rate limits trigger.
- Operation locks prevent duplicate rapid mutations.
