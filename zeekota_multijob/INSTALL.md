# Installation

1. Stop the server.
2. Import `sql/install.sql` into the server database used by `oxmysql`.
3. Review `config.lua`.
4. Set `Config.Framework` manually when more than one supported framework is running.
5. Add `ensure zeekota_multijob` after `oxmysql` and the selected framework.
6. Start the server and verify the console prints `ZeeKota Multi Job is ready.`

For upgrades from a build that only had player jobs, run `sql/upgrade_admin.sql`.

For removal, run `sql/uninstall.sql` only after backing up the database.
