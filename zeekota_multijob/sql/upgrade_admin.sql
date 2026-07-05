ALTER TABLE `zeekota_multijob_jobs`
    ADD COLUMN IF NOT EXISTS `assigned_by` VARCHAR(120) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `assignment_reason` VARCHAR(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `revision` INT UNSIGNED NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `zeekota_multijob_limits` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `framework` VARCHAR(16) NOT NULL,
    `character_identifier` VARCHAR(120) NOT NULL,
    `job_limit` INT NOT NULL DEFAULT 3,
    `changed_by` VARCHAR(120) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `revision` INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_zkmj_limit_character` (`framework`, `character_identifier`),
    KEY `idx_zkmj_limit_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `zeekota_multijob_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `framework` VARCHAR(16) NOT NULL,
    `character_identifier` VARCHAR(120) NOT NULL,
    `action` VARCHAR(48) NOT NULL,
    `job_name` VARCHAR(64) DEFAULT NULL,
    `old_job_name` VARCHAR(64) DEFAULT NULL,
    `old_grade` INT DEFAULT NULL,
    `new_grade` INT DEFAULT NULL,
    `old_duty` TINYINT(1) DEFAULT NULL,
    `new_duty` TINYINT(1) DEFAULT NULL,
    `reason` VARCHAR(255) DEFAULT NULL,
    `actor_identifier` VARCHAR(120) DEFAULT NULL,
    `actor_name` VARCHAR(120) DEFAULT NULL,
    `actor_source` INT DEFAULT NULL,
    `metadata` JSON DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_zkmj_history_character` (`framework`, `character_identifier`, `created_at`),
    KEY `idx_zkmj_history_action` (`action`),
    KEY `idx_zkmj_history_job` (`job_name`),
    KEY `idx_zkmj_history_actor` (`actor_identifier`),
    KEY `idx_zkmj_history_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
