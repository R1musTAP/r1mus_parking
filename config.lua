Config = {}

Config.Debug = true -- Activar para ver mensajes de debug
Config.SaveInterval = 30000 -- Guardar posición cada 30 segundos
Config.MinDistanceToSave = 5.0 -- Distancia mínima para actualizar posición

Config.VehicleLock = {
    enabled = true,
    defaultKey = 'X',
    soundEnabled = true,
    lockSound = "door-bolt-4",
    unlockSound = "door-bolt-4"
}

-- Configuración general
Config.Debug = false
Config.SaveInterval = 30000 -- Guardar posición cada 30 segundos
Config.MinDistanceToSave = 5.0 -- Distancia mínima para actualizar posición


-- Configuración de degradación de vehículos
Config.VehicleDegradation = {
    enabled = false,
    interval = 3600000, -- Comprobar cada hora
    healthDecrease = 0.5, -- Porcentaje de salud que pierde por hora
    fuelDecrease = 0.2, -- Porcentaje de combustible que pierde por hora
    minimumHealth = 500.0, -- Salud mínima del vehículo
    minimumFuel = 5.0, -- Combustible mínimo
}

-- Configuración de notificaciones
Config.Notifications = {
    enabled = true,
    healthThreshold = 600.0, -- Notificar cuando la salud baje de este valor
    fuelThreshold = 20.0, -- Notificar cuando el combustible baje de este porcentaje
}

-- Configuración de respawn de vehículos
Config.VehicleRespawn = {
    enabled = true,
    maxDistance = 100.0, -- Distancia máxima para hacer respawn de vehículos
    checkInterval = 10000, -- Intervalo para comprobar vehículos cercanos
}

-- Configuración de Depósito/Incautación
Config.Impound = {
    enabled = false,
    location = vector3(409.0, -1625.0, 29.3), -- Ubicación del depósito
    heading = 230.0,
    blip = {
        enabled = true,
        sprite = 68,
        color = 3,
        scale = 0.8,
        label = "Depósito Municipal"
    },
    fee = 500, -- Costo para recuperar vehículo
    policeCanImpound = true, -- Policía puede incautar
    mechanicCanImpound = true, -- Mecánicos pueden incautar
    autoImpoundAfterDays = 7, -- Auto-incautar después de X días sin uso
}

-- Configuración de Botes
Config.BoatParking = {
    enabled = true,
    checkInterval = 5000, -- Verificar cada 5 segundos si está en agua
    minWaterDepth = 1.5, -- Profundidad mínima para considerar agua
    docks = {
        {
            name = "Puerto Principal",
            coords = vector3(-794.75, -1510.83, 1.6),
            radius = 50.0,
            blip = {sprite = 410, color = 3, scale = 0.8}
        },
        {
            name = "Marina Chumash",
            coords = vector3(-3426.77, 955.66, 8.35),
            radius = 50.0,
            blip = {sprite = 410, color = 3, scale = 0.8}
        },
        {
            name = "Muelle Paleto",
            coords = vector3(-275.52, 6635.84, 7.51),
            radius = 40.0,
            blip = {sprite = 410, color = 3, scale = 0.8}
        }
    }
}

-- Configuración de Optimización
Config.Optimization = {
    -- Intervalos de actualización
    vehicleCheckInterval = 5000,  -- Verificar vehículos cada 5 segundos
    positionSaveInterval = 30000, -- Guardar posición cada 30 segundos
    stoppedSaveDelay = 2000,     -- Esperar 2 segundos después de detenerse para guardar
    
    -- Distancias
    minDistanceToUpdate = 5.0,    -- Distancia mínima para actualizar posición
    maxSpawnDistance = 300.0,     -- Distancia máxima para spawn de vehículos
    
    -- Límites
    maxVehiclesPerPlayer = 10,    -- Máximo de vehículos personales activos por jugador
    spawnDelay = 1000,           -- Delay entre spawn de vehículos (ms)
    
    -- Cache
    enablePermissionCache = true, -- Habilitar cache de permisos
    cacheTimeout = 60000,        -- Tiempo de cache en ms (1 minuto)
    
    -- Streaming para 250+ jugadores
    streamingEnabled = true,     -- Usar sistema de streaming para vehículos de facción
    streamDistance = 150.0,      -- Distancia de streaming (metros)
    streamCheckInterval = 2000,  -- Intervalo de verificación de streaming (ms)
}

-- Configuración de Vehículos de Facción
Config.FactionVehicles = {
    enabled = true, -- ASEGÚRATE DE QUE ESTÉ EN true
    respawnOnRestart = false, -- Los vehículos vuelven a su posición original al reiniciar
    lockToFaction = true, -- Solo miembros de la facción pueden usar los vehículos
    requireOnDuty = false, -- Requiere estar on duty para usar vehículos de facción
    alwaysVisible = true, -- Los vehículos siempre son visibles para todos (no afecta rendimiento con streaming)
    
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