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
    maxRetries = 3                    -- Maximum retries for vehicle spawning
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

--[[ SISTEMAS DE INTERFAZ ]]--
-- Sistema de Notificaciones
Config.NotificationSystem = {
    type = 'qb',                       -- Sistema de notificación: 'qb', 'origen', 'ox', 'esx', 'custom'
    timeout = 5000,                    -- Tiempo predeterminado para notificaciones (ms)
    customNotify = function(message, type)
        -- Función para sistemas de notificación personalizados
        -- exports['tu-sistema']:notify(message, type)
    end
}

-- Sistema de Menús
Config.MenuSystem = 'qb'               -- 'qb' (default), 'ox', 'custom'

--[[ CONFIGURACIÓN DE VEHÍCULOS ]]--
-- Sistema de Bloqueo
Config.VehicleLock = {
    enabled = true,                    -- Activar/desactivar sistema de bloqueo
    defaultKey = 'L',                  -- Tecla predeterminada para bloquear/desbloquear
    soundEnabled = true,               -- Activar/desactivar sonidos
    lockSound = "door-bolt-4",         -- Sonido al bloquear
    unlockSound = "door-bolt-4"        -- Sonido al desbloquear
}


--[[ SISTEMA DE DEGRADACIÓN ]]--
Config.VehicleDegradation = {
    enabled = false,                   -- Activar/desactivar sistema de degradación
    interval = 3600000,               -- Intervalo de comprobación (1 hora)
    healthDecrease = 0.5,             -- % de salud que pierde por hora
    fuelDecrease = 0.2,              -- % de combustible que pierde por hora
    minimumHealth = 500.0,            -- Salud mínima del vehículo
    minimumFuel = 5.0,               -- Combustible mínimo
    notifications = {
        enabled = true,               -- Activar notificaciones de estado
        healthThreshold = 600.0,      -- Notificar cuando la salud baje de este valor
        fuelThreshold = 20.0         -- Notificar cuando el combustible baje de este %
    }
}



--[[ SISTEMA DE RESPAWN ]]--
Config.VehicleRespawn = {
    enabled = true,                    -- Activar/desactivar sistema de respawn
    maxDistance = 100.0,              -- Distancia máxima para hacer respawn
    checkInterval = 10000,            -- Intervalo de comprobación (10 segundos)
}

--[[ SISTEMA DE DEPÓSITO/INCAUTACIÓN ]]--
Config.Impound = {
    enabled = true,                    -- Activar/desactivar sistema de depósito
    fee = 500,                        -- Costo para recuperar vehículo ($)
    autoImpoundAfterDays = 7,         -- Auto-incautar después de X días sin uso
    
    -- Permisos de incautación
    permissions = {
        police = true,                -- Policía puede incautar
        mechanic = true              -- Mecánicos pueden incautar
    },

    -- Ubicación principal y posiciones de spawn
    location = {
        coords = vector3(409.0, -1625.0, 29.3),
        heading = 230.0
    },

    -- Posiciones de spawn para vehículos incautados
    spawnPositions = {
        -- Fila 1
        {coords = vector3(407.12, -1645.67, 29.29), heading = 320.0},
        {coords = vector3(404.43, -1643.86, 29.29), heading = 320.0},
        {coords = vector3(401.65, -1642.15, 29.29), heading = 320.0},
        {coords = vector3(398.77, -1640.34, 29.29), heading = 320.0},
        {coords = vector3(395.89, -1638.53, 29.29), heading = 320.0},
        -- Fila 2
        {coords = vector3(409.81, -1639.82, 29.29), heading = 320.0},
        {coords = vector3(407.03, -1638.01, 29.29), heading = 320.0},
        {coords = vector3(404.25, -1636.20, 29.29), heading = 320.0},
        {coords = vector3(401.37, -1634.39, 29.29), heading = 320.0}
    },
    
    -- Configuración del NPC
    ped = {
        enabled = true,
        model = "s_m_y_cop_01",
        coords = vector3(409.0, -1625.0, 28.3),
        heading = 230.0,
        scenario = "WORLD_HUMAN_CLIPBOARD"
    },
    
    -- Configuración del blip en el mapa
    blip = {
        enabled = true,
        sprite = 68,
        color = 3,
        scale = 0.8,
        label = "Depósito Municipal"
    }
}

--[[ SISTEMA DE BOTES ]]--
Config.BoatParking = {
    enabled = true,                    -- Activar/desactivar sistema de botes
    checkInterval = 5000,             -- Intervalo de verificación (5 segundos)
    minWaterDepth = 1.5,             -- Profundidad mínima del agua requerida
    requireDock = false,              -- false = estacionar en cualquier parte del agua
    
    -- Ubicaciones de muelles (solo para blips si requireDock = false)
    docks = {
        {
            name = "Puerto Principal",
            coords = vector3(-794.75, -1510.83, 1.6),
            blip = {
                sprite = 410,
                color = 3,
                scale = 0.8
            }
        },
        {
            name = "Marina Chumash",
            coords = vector3(-3426.77, 955.66, 8.35),
            blip = {
                sprite = 410,
                color = 3,
                scale = 0.8
            }
        },
        {
            name = "Muelle Paleto",
            coords = vector3(-275.52, 6635.84, 7.51),
            blip = {
                sprite = 410,
                color = 3,
                scale = 0.8
            }
        }
    }
}

--[[ OPTIMIZACIÓN Y RENDIMIENTO ]]--
Config.Optimization = {
    -- Intervalos de actualización (en milisegundos)
    intervals = {
        vehicleCheck = 5000,         -- Verificación de vehículos (5 segundos)
        positionSave = 30000,        -- Guardado de posición (30 segundos)
        stoppedSave = 2000,          -- Delay después de detenerse (2 segundos)
        streamCheck = 2000           -- Verificación de streaming (2 segundos)
    },
    
    -- Distancias (en metros)
    distances = {
        minUpdate = 5.0,             -- Mínima para actualizar posición
        maxSpawn = 300.0,            -- Máxima para spawn de vehículos
        streaming = 150.0            -- Distancia de streaming
    },
    
    -- Límites y restricciones
    limits = {
        maxVehiclesPerPlayer = 10,   -- Máximo de vehículos por jugador
        spawnDelay = 1000           -- Delay entre spawns (1 segundo)
    },
    
    -- Sistema de caché
    cache = {
        enabled = true,              -- Habilitar sistema de caché
        timeout = 60000             -- Tiempo de expiración (1 minuto)
    },
    
    -- Streaming para servidores grandes
    streaming = {
        enabled = true              -- Activar sistema de streaming
    }
}

--[[ SISTEMA DE VEHÍCULOS DE FACCIÓN ]]--
Config.FactionVehicles = {
    -- Configuración general
    enabled = true,                  -- Activar sistema de vehículos de facción
    respawnOnRestart = false,        -- Restaurar posiciones al reiniciar
    lockToFaction = true,           -- Solo miembros pueden usar los vehículos
    requireOnDuty = false,          -- Requerir estar en servicio
    alwaysVisible = true,           -- Vehículos visibles para todos
    
    -- Definición de vehículos por trabajo
    factions = {
        ['police'] = {
            vehicles = {
                {
                    model = 'police',
                    coords = vector3(442.73, -1019.77, 28.55),
                    heading = 90.0,
                    livery = 0,
                    extras = {1, 2}, -- Extras activados
                    label = "Patrulla #1"
                },
                {
                    model = 'police2',
                    coords = vector3(442.73, -1023.77, 28.55),
                    heading = 90.0,
                    livery = 0,
                    label = "Patrulla #2"
                },
                {
                    model = 'police3',
                    coords = vector3(442.73, -1027.77, 28.55),
                    heading = 90.0,
                    livery = 0,
                    label = "Patrulla #3"
                },
                {
                    model = 'policeb',
                    coords = vector3(451.73, -1019.77, 28.55),
                    heading = 90.0,
                    label = "Moto Policial #1"
                },
                {
                    model = 'fbi',
                    coords = vector3(451.73, -1023.77, 28.55),
                    heading = 90.0,
                    livery = 0,
                    label = "Unidad FBI"
                }
            }
        },
        ['ambulance'] = {
            vehicles = {
                {
                    model = 'ambulance',
                    coords = vector3(298.23, -1445.51, 29.97),
                    heading = 50.0,
                    livery = 0,
                    label = "Ambulancia #1"
                },
                {
                    model = 'ambulance',
                    coords = vector3(294.58, -1448.28, 29.97),
                    heading = 50.0,
                    livery = 0,
                    label = "Ambulancia #2"
                },
                {
                    model = 'ambulance',
                    coords = vector3(290.93, -1451.05, 29.97),
                    heading = 50.0,
                    livery = 0,
                    label = "Ambulancia #3"
                },
                {
                    model = 'firetruk',
                    coords = vector3(287.28, -1453.82, 29.97),
                    heading = 50.0,
                    label = "Camión de Bomberos"
                },
                {
                    model = 'lguard',
                    coords = vector3(283.63, -1456.59, 29.97),
                    heading = 50.0,
                    label = "Vehículo de Rescate"
                }
            }
        },
        ['mechanic'] = {
            vehicles = {
                {
                    model = 'flatbed',
                    coords = vector3(-222.24, -1329.89, 30.89),
                    heading = 270.0,
                    label = "Grúa #1"
                },
                {
                    model = 'towtruck',
                    coords = vector3(-222.24, -1324.89, 30.89),
                    heading = 270.0,
                    label = "Grúa #2"
                },
                {
                    model = 'slamvan3',
                    coords = vector3(-222.24, -1319.89, 30.89),
                    heading = 270.0,
                    label = "Van de Trabajo #1"
                },
                {
                    model = 'utillitruck3',
                    coords = vector3(-205.24, -1329.89, 30.89),
                    heading = 270.0,
                    label = "Camión de Utilidades"
                },
                {
                    model = 'burrito3',
                    coords = vector3(-205.24, -1324.89, 30.89),
                    heading = 270.0,
                    label = "Van de Herramientas"
                }
            }
        }
    }
}

-- Configuración de Idioma
Config.Language = 'es' -- Opciones: 'en' para inglés, 'es' para español

-- Sistema de Menús
Config.MenuSystem = 'qb' -- Opciones: 'qb' (default), 'ox', 'custom'