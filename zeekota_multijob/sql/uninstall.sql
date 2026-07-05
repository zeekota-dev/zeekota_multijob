-- WARNING: This permanently deletes all ZeeKota Multi Job stored jobs, limits, and history.
-- Back up your database before running this script.

DROP TABLE IF EXISTS `zeekota_multijob_history`;
DROP TABLE IF EXISTS `zeekota_multijob_limits`;
DROP TABLE IF EXISTS `zeekota_multijob_jobs`;
