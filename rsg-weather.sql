-- ==========================================
--           RSG WEATHER SYSTEM
--           DATABASE SCHEMA
-- ==========================================
-- 
-- This SQL file creates all necessary tables for the RSG Weather System
-- Compatible with MySQL 5.7+ and MariaDB 10.3+
--
-- FOREIGN KEY CONSTRAINT ISSUE - FIXED:
-- The original foreign key constraint on rsg_player_weather_settings
-- has been removed to prevent installation errors (errno: 150).
-- The table will still function correctly without the constraint.
-- See bottom of file for optional foreign key setup instructions.
--
-- DATETIME DEFAULT VALUE ISSUE - FIXED:
-- Removed GENERATED ALWAYS AS column for end_time in rsg_weather_cycles
-- and replaced with triggers for MySQL 5.7+ and MariaDB compatibility.
-- Fixed timestamp fields in rsg_weather_events to use NULL DEFAULT NULL.
--
-- Installation:
-- 1. Import this file into your database
-- 2. Ensure the rsg-core tables exist
-- 3. Run the resource
-- 4. Optionally add foreign key constraint (see end of file)
--
-- ==========================================

-- Set character set and collation for consistency
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================
--            WEATHER CYCLES TABLE
-- ==========================================
-- Stores active weather cycles and their durations
-- Used for tracking current weather patterns across different zones
-- 
-- NOTE: end_time is calculated via trigger instead of GENERATED column
-- to ensure MySQL 5.7+ and MariaDB compatibility

CREATE TABLE IF NOT EXISTS `rsg_weather_cycles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `weather_type` varchar(50) NOT NULL DEFAULT 'SUNNY',
    `temperature` decimal(5,2) NOT NULL DEFAULT 20.00,
    `humidity` decimal(5,2) DEFAULT 50.00,
    `wind_speed` decimal(5,2) DEFAULT 0.50,
    `wind_direction` decimal(6,2) DEFAULT 0.00,
    `zone` varchar(50) DEFAULT NULL,
    `start_time` timestamp DEFAULT CURRENT_TIMESTAMP,
    `duration` int(11) NOT NULL DEFAULT 3600,
    `end_time` timestamp NULL DEFAULT NULL,
    `active` tinyint(1) DEFAULT 1,
    `created_by` varchar(50) DEFAULT 'system',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_weather_type` (`weather_type`),
    KEY `idx_zone` (`zone`),
    KEY `idx_active_start` (`active`, `start_time`),
    KEY `idx_end_time` (`end_time`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default global weather cycle (end_time will be calculated by trigger)
INSERT IGNORE INTO `rsg_weather_cycles` (`id`, `weather_type`, `temperature`, `zone`, `duration`, `created_by`) 
VALUES (1, 'SUNNY', 22.00, NULL, 7200, 'system');

-- ==========================================
--            WEATHER ZONES TABLE
-- ==========================================
-- Stores current weather state for each defined zone
-- Enables regional weather variations

CREATE TABLE IF NOT EXISTS `rsg_weather_zones` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `zone_name` varchar(50) NOT NULL,
    `zone_display_name` varchar(100) NOT NULL,
    `current_weather` varchar(50) NOT NULL DEFAULT 'SUNNY',
    `temperature` decimal(5,2) NOT NULL DEFAULT 20.00,
    `humidity` decimal(5,2) DEFAULT 50.00,
    `wind_speed` decimal(5,2) DEFAULT 0.50,
    `wind_direction` decimal(6,2) DEFAULT 0.00,
    `center_x` decimal(10,2) DEFAULT 0.00,
    `center_y` decimal(10,2) DEFAULT 0.00,
    `center_z` decimal(10,2) DEFAULT 0.00,
    `radius` decimal(8,2) DEFAULT 500.00,
    `climate_type` enum('temperate','mountain','swamp','desert','tundra','coastal') DEFAULT 'temperate',
    `elevation` decimal(8,2) DEFAULT 0.00,
    `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `active` tinyint(1) DEFAULT 1,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_zone_name` (`zone_name`),
    KEY `idx_current_weather` (`current_weather`),
    KEY `idx_last_updated` (`last_updated`),
    KEY `idx_climate_type` (`climate_type`),
    KEY `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default zones based on config
INSERT IGNORE INTO `rsg_weather_zones` (`zone_name`, `zone_display_name`, `current_weather`, `temperature`, `center_x`, `center_y`, `center_z`, `radius`, `climate_type`) VALUES
('valentine', 'Valentine', 'SUNNY', 22.00, -298.00, 791.00, 118.00, 500.00, 'temperate'),
('strawberry', 'Strawberry', 'CLOUDS', 18.00, -1759.00, -388.00, 157.00, 400.00, 'mountain'),
('saint_denis', 'Saint Denis', 'OVERCAST', 24.00, 2635.00, -1225.00, 53.00, 600.00, 'swamp'),
('armadillo', 'Armadillo', 'SUNNY', 35.00, -3685.00, -2623.00, -14.00, 450.00, 'desert');

-- ==========================================
--           WEATHER HISTORY TABLE
-- ==========================================
-- Stores historical weather data for analytics and patterns
-- Automatically cleaned up after configured retention period

CREATE TABLE IF NOT EXISTS `rsg_weather_history` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `weather_type` varchar(50) NOT NULL,
    `temperature` decimal(5,2) NOT NULL,
    `humidity` decimal(5,2) DEFAULT NULL,
    `wind_speed` decimal(5,2) DEFAULT NULL,
    `wind_direction` decimal(6,2) DEFAULT NULL,
    `zone` varchar(50) DEFAULT NULL,
    `season` enum('spring','summer','autumn','winter') DEFAULT NULL,
    `player_count` int(11) DEFAULT 0,
    `recorded_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `data_source` enum('automatic','manual','admin') DEFAULT 'automatic',
    PRIMARY KEY (`id`),
    KEY `idx_recorded_at` (`recorded_at`),
    KEY `idx_weather_type` (`weather_type`),
    KEY `idx_zone` (`zone`),
    KEY `idx_season` (`season`),
    KEY `idx_zone_recorded` (`zone`, `recorded_at`),
    KEY `idx_cleanup` (`recorded_at`, `data_source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Partitioning for better performance (optional, requires MySQL 5.1+)
-- ALTER TABLE `rsg_weather_history` 
-- PARTITION BY RANGE (TO_DAYS(`recorded_at`)) (
--     PARTITION p_old VALUES LESS THAN (TO_DAYS('2024-01-01')),
--     PARTITION p_current VALUES LESS THAN MAXVALUE
-- );

-- ==========================================
--       PLAYER WEATHER SETTINGS TABLE
-- ==========================================
-- Stores individual player preferences for weather system
-- Linked to RSG-Core player data via citizenid
-- Foreign key constraint removed to avoid installation issues
-- Manual cleanup can be handled via stored procedures or triggers

CREATE TABLE IF NOT EXISTS `rsg_player_weather_settings` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `notifications_enabled` tinyint(1) DEFAULT 1,
    `temperature_unit` enum('celsius','fahrenheit') DEFAULT 'celsius',
    `effects_enabled` tinyint(1) DEFAULT 1,
    `hud_enabled` tinyint(1) DEFAULT 1,
    `hud_position` enum('top-left','top-right','bottom-left','bottom-right') DEFAULT 'top-right',
    `auto_shelter_seek` tinyint(1) DEFAULT 1,
    `weather_alerts` tinyint(1) DEFAULT 1,
    `forecast_hours` int(2) DEFAULT 6,
    `last_zone` varchar(50) DEFAULT NULL,
    `total_playtime_weather` int(11) DEFAULT 0,
    `favorite_weather` varchar(50) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `last_login` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_citizenid` (`citizenid`),
    KEY `idx_temperature_unit` (`temperature_unit`),
    KEY `idx_last_zone` (`last_zone`),
    KEY `idx_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
--           WEATHER EVENTS TABLE
-- ==========================================
-- Stores special weather events (storms, extreme weather, etc.)
-- Used for triggering special mechanics or notifications

CREATE TABLE IF NOT EXISTS `rsg_weather_events` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `event_type` enum('storm','heatwave','blizzard','drought','flood','tornado') NOT NULL,
    `severity` enum('minor','moderate','severe','extreme') DEFAULT 'moderate',
    `weather_type` varchar(50) NOT NULL,
    `zone` varchar(50) DEFAULT NULL,
    `start_time` timestamp NULL DEFAULT NULL,
    `end_time` timestamp NULL DEFAULT NULL,
    `temperature_min` decimal(5,2) DEFAULT NULL,
    `temperature_max` decimal(5,2) DEFAULT NULL,
    `wind_speed_max` decimal(5,2) DEFAULT NULL,
    `description` text DEFAULT NULL,
    `effects` json DEFAULT NULL,
    `triggered` tinyint(1) DEFAULT 0,
    `completed` tinyint(1) DEFAULT 0,
    `player_notifications_sent` tinyint(1) DEFAULT 0,
    `created_by` varchar(50) DEFAULT 'system',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_event_type` (`event_type`),
    KEY `idx_severity` (`severity`),
    KEY `idx_zone` (`zone`),
    KEY `idx_start_time` (`start_time`),
    KEY `idx_end_time` (`end_time`),
    KEY `idx_triggered` (`triggered`),
    KEY `idx_active_events` (`start_time`, `end_time`, `triggered`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
--        WEATHER STATISTICS TABLE
-- ==========================================
-- Stores aggregated weather statistics for server analytics
-- Updated periodically by the weather system

CREATE TABLE IF NOT EXISTS `rsg_weather_statistics` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `date` date NOT NULL,
    `zone` varchar(50) DEFAULT NULL,
    `weather_type` varchar(50) NOT NULL,
    `duration_minutes` int(11) DEFAULT 0,
    `avg_temperature` decimal(5,2) DEFAULT NULL,
    `min_temperature` decimal(5,2) DEFAULT NULL,
    `max_temperature` decimal(5,2) DEFAULT NULL,
    `avg_players_affected` decimal(8,2) DEFAULT 0,
    `weather_changes` int(11) DEFAULT 0,
    `extreme_events` int(11) DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_date_zone_weather` (`date`, `zone`, `weather_type`),
    KEY `idx_date` (`date`),
    KEY `idx_zone` (`zone`),
    KEY `idx_weather_type` (`weather_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
--              STORED PROCEDURES
-- ==========================================

-- Procedure to clean up old weather history
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS `CleanupWeatherHistory`(IN `retention_days` INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    DELETE FROM `rsg_weather_history` 
    WHERE `recorded_at` < DATE_SUB(NOW(), INTERVAL retention_days DAY);
    
    -- Also clean up completed weather events older than retention period
    DELETE FROM `rsg_weather_events` 
    WHERE `completed` = 1 AND `end_time` < DATE_SUB(NOW(), INTERVAL retention_days DAY);
    
    COMMIT;
    
    SELECT ROW_COUNT() as 'Records Cleaned';
END //
DELIMITER ;

-- Procedure to get weather statistics for a date range
DELIMITER //
CREATE PROCEDURE IF NOT EXISTS `GetWeatherStats`(
    IN `start_date` DATE, 
    IN `end_date` DATE, 
    IN `zone_filter` VARCHAR(50)
)
BEGIN
    SELECT 
        ws.date,
        ws.zone,
        ws.weather_type,
        ws.duration_minutes,
        ws.avg_temperature,
        ws.min_temperature,
        ws.max_temperature,
        ws.avg_players_affected,
        ws.weather_changes,
        ws.extreme_events
    FROM `rsg_weather_statistics` ws
    WHERE ws.date BETWEEN start_date AND end_date
        AND (zone_filter IS NULL OR ws.zone = zone_filter)
    ORDER BY ws.date DESC, ws.zone ASC;
END //
DELIMITER ;

-- ==========================================
--                 TRIGGERS
-- ==========================================

-- Trigger to calculate end_time for weather cycles (replaces GENERATED column)
DELIMITER //
CREATE TRIGGER IF NOT EXISTS `CalculateWeatherCycleEndTime` 
BEFORE INSERT ON `rsg_weather_cycles`
FOR EACH ROW
BEGIN
    SET NEW.end_time = DATE_ADD(NEW.start_time, INTERVAL NEW.duration SECOND);
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER IF NOT EXISTS `UpdateWeatherCycleEndTime` 
BEFORE UPDATE ON `rsg_weather_cycles`
FOR EACH ROW
BEGIN
    -- Only recalculate if start_time or duration changed
    IF NEW.start_time != OLD.start_time OR NEW.duration != OLD.duration THEN
        SET NEW.end_time = DATE_ADD(NEW.start_time, INTERVAL NEW.duration SECOND);
    END IF;
END //
DELIMITER ;

-- Trigger to automatically update weather statistics when history is inserted
DELIMITER //
CREATE TRIGGER IF NOT EXISTS `UpdateWeatherStats` 
AFTER INSERT ON `rsg_weather_history`
FOR EACH ROW
BEGIN
    INSERT INTO `rsg_weather_statistics` (
        `date`, `zone`, `weather_type`, `duration_minutes`, 
        `avg_temperature`, `min_temperature`, `max_temperature`, `weather_changes`
    ) VALUES (
        DATE(NEW.recorded_at), NEW.zone, NEW.weather_type, 60,
        NEW.temperature, NEW.temperature, NEW.temperature, 1
    ) ON DUPLICATE KEY UPDATE
        `duration_minutes` = `duration_minutes` + 60,
        `avg_temperature` = ((`avg_temperature` * (`duration_minutes` - 60) / 60) + NEW.temperature) / ((`duration_minutes` / 60) + 1),
        `min_temperature` = LEAST(`min_temperature`, NEW.temperature),
        `max_temperature` = GREATEST(`max_temperature`, NEW.temperature),
        `weather_changes` = `weather_changes` + 1,
        `updated_at` = CURRENT_TIMESTAMP;
END //
DELIMITER ;

-- ==========================================
--                  VIEWS
-- ==========================================

-- View for current active weather in all zones
CREATE OR REPLACE VIEW `view_current_weather` AS
SELECT 
    wz.zone_name,
    wz.zone_display_name,
    wz.current_weather,
    wz.temperature,
    wz.humidity,
    wz.wind_speed,
    wz.climate_type,
    wz.last_updated,
    wc.duration,
    wc.end_time,
    CASE 
        WHEN wc.end_time > NOW() THEN 'active'
        ELSE 'expired'
    END AS cycle_status
FROM `rsg_weather_zones` wz
LEFT JOIN `rsg_weather_cycles` wc ON wz.zone_name = wc.zone AND wc.active = 1
WHERE wz.active = 1;

-- View for weather history with zone information
CREATE OR REPLACE VIEW `view_weather_history_detailed` AS
SELECT 
    wh.*,
    wz.zone_display_name,
    wz.climate_type,
    DATE_FORMAT(wh.recorded_at, '%Y-%m-%d %H:%i') as formatted_time,
    CASE 
        WHEN wh.temperature <= 0 THEN 'Freezing'
        WHEN wh.temperature <= 10 THEN 'Cold'
        WHEN wh.temperature <= 20 THEN 'Cool'
        WHEN wh.temperature <= 30 THEN 'Warm'
        ELSE 'Hot'
    END AS temperature_category
FROM `rsg_weather_history` wh
LEFT JOIN `rsg_weather_zones` wz ON wh.zone = wz.zone_name
ORDER BY wh.recorded_at DESC;

-- ==========================================
--               INDEXES FOR PERFORMANCE
-- ==========================================

-- Additional indexes for common queries
ALTER TABLE `rsg_weather_history` 
ADD INDEX `idx_weather_zone_date` (`weather_type`, `zone`, `recorded_at`),
ADD INDEX `idx_temperature_range` (`temperature`, `recorded_at`);

ALTER TABLE `rsg_weather_zones`
ADD INDEX `idx_coords` (`center_x`, `center_y`, `radius`);

ALTER TABLE `rsg_weather_cycles`
ADD INDEX `idx_active_zone_time` (`active`, `zone`, `start_time`, `end_time`);

-- ==========================================
--              INITIAL DATA
-- ==========================================

-- Insert initial weather statistics for current date
INSERT IGNORE INTO `rsg_weather_statistics` (`date`, `zone`, `weather_type`, `duration_minutes`, `avg_temperature`) 
SELECT 
    CURDATE(), 
    NULL, 
    'SUNNY', 
    0, 
    22.00
WHERE NOT EXISTS (
    SELECT 1 FROM `rsg_weather_statistics` 
    WHERE `date` = CURDATE() AND `zone` IS NULL AND `weather_type` = 'SUNNY'
);

-- ==========================================
--                MAINTENANCE
-- ==========================================

-- Event to automatically clean up old data (requires MySQL Event Scheduler)
SET GLOBAL event_scheduler = ON;

DELIMITER //
CREATE EVENT IF NOT EXISTS `weather_cleanup_event`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- Clean up weather history older than 7 days
    CALL CleanupWeatherHistory(7);
    
    -- Clean up old player settings for inactive players (optional)
    -- Note: Without foreign key constraint, manual cleanup is performed
    DELETE ps FROM `rsg_player_weather_settings` ps
    LEFT JOIN `players` p ON ps.citizenid = p.citizenid
    WHERE p.citizenid IS NULL;
    
    -- Optimize tables periodically
    OPTIMIZE TABLE `rsg_weather_history`;
    OPTIMIZE TABLE `rsg_weather_statistics`;
END //
DELIMITER ;

-- ==========================================
--               SAMPLE QUERIES
-- ==========================================

-- Get current weather for all zones
-- SELECT * FROM view_current_weather;

-- Get weather history for last 24 hours
-- SELECT * FROM view_weather_history_detailed WHERE recorded_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- Get temperature statistics by zone
-- SELECT zone, AVG(temperature) as avg_temp, MIN(temperature) as min_temp, MAX(temperature) as max_temp 
-- FROM rsg_weather_history WHERE recorded_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY zone;

-- Get player weather preferences
-- SELECT p.charinfo->>'$.firstname' as firstname, p.charinfo->>'$.lastname' as lastname, 
--        pws.temperature_unit, pws.notifications_enabled 
-- FROM rsg_player_weather_settings pws 
-- JOIN players p ON pws.citizenid = p.citizenid;

SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================
--          OPTIONAL FOREIGN KEY SETUP
-- ==========================================
-- 
-- If you want to add the foreign key constraint after installation,
-- run this command AFTER both rsg-core and rsg-weather are installed:
--
-- ALTER TABLE `rsg_player_weather_settings` 
-- ADD CONSTRAINT `fk_weather_settings_players` 
--     FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) 
--     ON DELETE CASCADE ON UPDATE CASCADE;
--
-- This ensures referential integrity but is optional for functionality.
-- The system will work without the foreign key constraint.
--
-- To remove the constraint later (if needed):
-- ALTER TABLE `rsg_player_weather_settings` DROP FOREIGN KEY `fk_weather_settings_players`;
--

-- ==========================================
--                 COMPLETE
-- ==========================================
-- RSG Weather System Database Schema Installation Complete
-- 
-- DATETIME COMPATIBILITY CHANGES:
-- - Replaced GENERATED ALWAYS AS column with triggers for end_time calculation
-- - Changed NOT NULL timestamp fields to NULL DEFAULT NULL where appropriate
-- - Added triggers to automatically calculate weather cycle end times
-- - All datetime fields now use MySQL/MariaDB compatible default values
--
-- Next Steps:
-- 1. Ensure your RSG-Core is properly installed
-- 2. Start the rsg-weather resource
-- 3. Check server console for any errors
-- 4. Test weather commands and functionality
--
-- For support, check the documentation or contact the development team
-- ==========================================