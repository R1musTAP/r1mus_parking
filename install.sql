-- Tabla para vehículos personales estacionados
CREATE TABLE IF NOT EXISTS `r1mus_parked_vehicles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `plate` VARCHAR(8) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `coords` TEXT NOT NULL,
    `heading` FLOAT NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `body_health` FLOAT NOT NULL,
    `engine_health` FLOAT NOT NULL,
    `fuel_level` FLOAT NOT NULL,
    `dirt_level` FLOAT NOT NULL,
    `mods` TEXT,
    `locked` BOOLEAN DEFAULT true,
    `last_parked` BIGINT NOT NULL,
    `impounded` BOOLEAN DEFAULT false,
    `impound_date` BIGINT DEFAULT NULL,
    `impound_reason` VARCHAR(255) DEFAULT NULL,
    `impound_fee` INT DEFAULT 500,
    `vehicle_type` VARCHAR(20) DEFAULT 'car',
    UNIQUE KEY `unique_plate` (`plate`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_impounded` (`impounded`),
    INDEX `idx_vehicle_type` (`vehicle_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Crear índices adicionales para optimización
CREATE INDEX IF NOT EXISTS `idx_last_parked` ON `r1mus_parked_vehicles` (`last_parked`);
CREATE INDEX IF NOT EXISTS `idx_model` ON `r1mus_parked_vehicles` (`model`);

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