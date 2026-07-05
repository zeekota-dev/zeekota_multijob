# Administrator Panel

Open with `/multijobadmin`.

Access can be granted with:

- ACE permission: `zeekota_multijob.admin`
- Framework groups in `Config.Admin.Groups`
- Explicit identifiers in `Config.Admin.Identifiers`
- Custom assignment and removal hooks in `Config.Restrictions`

The panel supports:

- Dashboard statistics.
- Online player search.
- Offline character search.
- Character job details.
- Add job.
- Remove job.
- Change grade.
- Set active job.
- Set duty.
- Set job limit.
- View job history.

All administrator actions are server-authoritative, rate-limited, permission checked, and written to `zeekota_multijob_history`.
