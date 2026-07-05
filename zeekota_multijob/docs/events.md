# Events

## Public Server Events

- `zeekota_multijob:server:jobAdded`
- `zeekota_multijob:server:jobRemoved`
- `zeekota_multijob:server:jobGradeChanged`
- `zeekota_multijob:server:activeJobChanged`
- `zeekota_multijob:server:dutyChanged`
- `zeekota_multijob:server:jobLimitChanged`

Payloads include the framework, character identifier, job name, grade, duty state, or limit depending on the action.

## Public Client Events

- `zeekota_multijob:client:jobsUpdated`
- `zeekota_multijob:client:activeJobChanged`
- `zeekota_multijob:client:dutyChanged`
- `zeekota_multijob:client:jobLimitChanged`
- `zeekota_multijob:client:notify`

Internal NUI request events use the `zeekota_multijob:internal:*` namespace and should not be triggered by other resources.
