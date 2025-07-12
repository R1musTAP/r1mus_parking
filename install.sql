-- Compatibilidad con MySQL y MariaDB
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Tabla para vehículos personales estacionados
CREATE TABLE IF NOT EXISTS `r1mus_parked_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `plate` varchar(8) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `coords` json NOT NULL,
    `heading` float NOT NULL,
    `model` varchar(50) NOT NULL,
    `body_health` float NOT NULL DEFAULT '1000.0',
    `engine_health` float NOT NULL DEFAULT '1000.0',
    `fuel_level` float NOT NULL DEFAULT '100.0',
    `dirt_level` float NOT NULL DEFAULT '0.0',
    `mods` json DEFAULT NULL,
    `doors` json DEFAULT NULL,
    `windows` json DEFAULT NULL,
    `tires` json DEFAULT NULL,
    `locked` BOOLEAN DEFAULT true,
    `last_parked` BIGINT NOT NULL,
    `impounded` BOOLEAN DEFAULT false,
    `impound_date` BIGINT DEFAULT NULL,
    `impound_reason` VARCHAR(255) DEFAULT NULL,
    `impound_fee` INT DEFAULT 500,
    `impound_location` VARCHAR(50) DEFAULT NULL,
    `vehicle_type` VARCHAR(20) DEFAULT 'car',
    `last_position` json DEFAULT NULL,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_plate` (`plate`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_impounded` (`impounded`),
    INDEX `idx_vehicle_type` (`vehicle_type`),
    INDEX `idx_last_updated` (`last_updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Crear índices adicionales para optimización
CREATE INDEX IF NOT EXISTS `idx_last_parked` ON `r1mus_parked_vehicles` (`last_parked`);
CREATE INDEX IF NOT EXISTS `idx_model` ON `r1mus_parked_vehicles` (`model`);

-- Tabla para historial de incautaciones
CREATE TABLE IF NOT EXISTS `r1mus_impound_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `plate` VARCHAR(8) NOT NULL,
    `officer_id` VARCHAR(50) NOT NULL,
    `reason` TEXT NOT NULL,
    `fee` INT NOT NULL DEFAULT 500,
    `impound_date` BIGINT NOT NULL,
    `release_date` BIGINT DEFAULT NULL,
    `released_by` VARCHAR(50) DEFAULT NULL,
    INDEX `idx_plate` (`plate`),
    INDEX `idx_impound_date` (`impound_date`),
    INDEX `idx_officer` (`officer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla para vehículos de facción
CREATE TABLE IF NOT EXISTS `r1mus_faction_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `plate` VARCHAR(8) NOT NULL,
    `job` VARCHAR(50) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `coords` TEXT NOT NULL,
    `heading` FLOAT NOT NULL,
    `original_coords` TEXT NOT NULL,
    `original_heading` FLOAT NOT NULL,
    `label` VARCHAR(100),
    `livery` INT DEFAULT 0,
    `extras` TEXT,
    `body_health` FLOAT DEFAULT 1000.0,
    `engine_health` FLOAT DEFAULT 1000.0,
    `fuel_level` FLOAT DEFAULT 100.0,
    `dirt_level` FLOAT DEFAULT 0.0,
    `mods` TEXT,
    `in_use` BOOLEAN DEFAULT false,
    `last_used` BIGINT,
    UNIQUE KEY `unique_faction_plate` (`plate`),
    INDEX `idx_job` (`job`),
    INDEX `idx_in_use` (`in_use`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;