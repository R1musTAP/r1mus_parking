Config = {}

--[[ GENERAL CONFIGURATION ]]--
Config.Debug = false                    -- Enable to see debug messages in console
Config.Language = 'es'                  -- System language: 'es' for Spanish, 'en' for English

--[[ OPTIMIZATION SETTINGS ]]--
Config.Optimization = {
    streamingEnabled = true,           -- Enable vehicle streaming system
    streamingRadius = 150.0,           -- Distance to start streaming vehicles (meters)
    maxVehiclesPerPlayer = 10,         -- Maximum vehicles to spawn per player
    spawnDelay = 500,                 -- Delay between vehicle spawns (ms)
    saveInterval = 300000,            -- Auto-save interval (5 minutes)
    maxStreamedVehicles = 50,         -- Maximum vehicles to stream at once
    vehicleCheckInterval = 5000,      -- Interval to check for missing vehicles (ms)
    cleanupInterval = 60000,          -- Interval to cleanup unused vehicle data (ms)
    distanceCheck = 200.0,            -- Distance to check for vehicle existence
    maxRetries = 3,                   -- Maximum retries for vehicle spawning
    positionSaveInterval = 30000,     -- Interval between position saves (30 seconds)
    minDistanceToUpdate = 5.0         -- Minimum distance moved to trigger an update (meters)
}

--[[ DAMAGE PERSISTENCE ]]--
Config.DamagePersistence = {
    enabled = true,                    -- Enable damage persistence system
    saveBodyDamage = true,            -- Save body damage
    saveEngineDamage = true,          -- Save engine damage
    saveDoors = true,                 -- Save door states
    saveWindows = true,               -- Save window states
    saveTires = true,                 -- Save tire states
    minimumHealth = 100.0             -- Minimum health to save (0-1000)
}

--[[ INTERFACE SYSTEMS ]]--
Config.NotificationSystem = {
    type = 'qb',                       -- Notification system: 'qb', 'origen', 'ox', 'esx', 'custom'
    timeout = 5000,                    -- Default notification timeout (ms)
    customNotify = function(message, type)
        -- Function for custom notification systems
        -- exports['your-system']:notify(message, type)
    end
}

Config.MenuSystem = 'qb'               -- 'qb' (default), 'ox', 'custom'

--[[ VEHICLE SETTINGS ]]--
Config.VehicleLock = {
    enabled = true,                    -- Enable/disable lock system
    defaultKey = 'L',                  -- Default key for lock/unlock
    soundEnabled = true,               -- Enable/disable sounds
    lockSound = "lock",                -- Sound for locking
    unlockSound = "unlock"             -- Sound for unlocking
}

--[[ IMPOUND SYSTEM ]]--
Config.Impound = {
    enabled = true,
    fee = 500,                         -- Fee to retrieve vehicle
    policeCanImpound = true,          -- Allow police to impound
    mechanicCanImpound = true,         -- Allow mechanics to impound
    
    -- Davis Police Station Impound Configuration
    location = {
        entrance = vector3(409.25, -1623.08, 29.29),  -- NPC and payment point location
        gate = {
            coords = vector3(405.99, -1627.89, 29.29),
            heading = 229.5,
            model = -1156020871,       -- Gate hash
        },
        spawnPositions = {
            -- Positions inside Davis Police Station impound
            {coords = vector3(374.81, -1620.88, 29.29), heading = 320.0},
            {coords = vector3(378.81, -1618.88, 29.29), heading = 320.0},
            {coords = vector3(382.81, -1616.88, 29.29), heading = 320.0},
            {coords = vector3(386.81, -1614.88, 29.29), heading = 320.0},
            {coords = vector3(374.81, -1625.88, 29.29), heading = 320.0},
            {coords = vector3(378.81, -1623.88, 29.29), heading = 320.0},
            {coords = vector3(382.81, -1621.88, 29.29), heading = 320.0},
            {coords = vector3(386.81, -1619.88, 29.29), heading = 320.0},
        },
    },
    
    -- NPC Configuration
    ped = {
        enabled = true,
        models = {
            'cs_jimmyboston',     -- Primer modelo a intentar
            's_m_m_security_01',  -- Modelo de respaldo 1 (Guardia de seguridad)
            's_m_y_cop_01',       -- Modelo de respaldo 2 (Policía)
            'mp_m_waremech_01'    -- Modelo de respaldo 3 (Mecánico)
        },
        coords = vector3(409.25, -1623.08, 29.29),
        heading = 229.5,
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },
    
    -- Blip Configuration
    blip = {
        enabled = true,
        sprite = 524,
        color = 64,
        scale = 0.7,
        label = 'Depósito Municipal'
    }
}

--[[ FACTION VEHICLES ]]--
Config.FactionVehicles = {
    enabled = true,
    lockToFaction = true,              -- Only faction members can use vehicles
    requireOnDuty = true,              -- Require being on duty
    respawnOnRestart = true,           -- Respawn vehicles on resource restart
    factions = {
        -- Policía
        police = {
            label = "Vehículos Policiales",
            vehicles = {
                {
                    model = "police",
                    label = "Patrulla Estándar",
                    coords = vector4(441.5035, -1024.2858, 28.6974),
                    heading = 91.24,
                    livery = 0,
                    extras = {1, 2, 3, 4}
                },
                {
                    model = "police2",
                    label = "Patrulla SUV",
                    coords = vector4(446.9621, -1023.6602, 28.5908),
                    heading = 91.24,
                    livery = 0,
                    extras = {1, 2, 3}
                },
                {
                    model = "police3",
                    label = "Patrulla Interceptor",
                    coords = vector4(451.7863, -1023.6266, 28.5156),
                    heading = 91.24,
                    livery = 0,
                    extras = {1, 2}
                }
            }
        },
        -- Ambulancia
        ambulance = {
            label = "Vehículos Médicos",
            vehicles = {
                {
                    model = "ambulance",
                    label = "Ambulancia",
                    coords = vector4(291.8515, -612.5726, 43.3986),
                    heading = 338.88,
                    livery = 0,
                    extras = {1, 2, 3, 4}
                },
                {
                    model = "emsnspeedo",
                    label = "Van Médica",
                    coords = vector4(294.1606, -607.0378, 43.3314),
                    heading = 338.88,
                    livery = 0,
                    extras = {1, 2}
                }
            }
        },
        -- Mecánicos
        mechanic = {
            label = "Vehículos de Mecánico",
            vehicles = {
                {
                    model = "towtruck",
                    label = "Grúa",
                    coords = vector4(-200.7378, -1298.1160, 31.2617),
                    heading = 207.61,
                    livery = 0,
                    extras = {}
                },
                {
                    model = "flatbed",
                    label = "Plataforma",
                    coords = vector4(-189.4579, -1287.8645, 31.3531),
                    heading = 207.61,
                    livery = 0,
                    extras = {}
                }
            }
        }
    }
}

--[[ BOAT PARKING SYSTEM ]]--
Config.BoatParking = {
    enabled = true,                    -- Habilitar sistema de barcos
    checkInterval = 5000,             -- Intervalo para verificar posición (ms)
    minWaterDepth = 3.0,              -- Profundidad mínima del agua para considerar "agua profunda"
    requireDock = false,              -- No requerir estar en muelle para estacionar
    allowParkAnywhere = true          -- Permitir estacionar en cualquier lugar fuera del agua
}