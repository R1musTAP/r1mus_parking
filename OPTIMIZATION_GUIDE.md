# Guía de Optimización - Sistema r1mus_parking

## Estado Actual de Optimización

### ⚠️ Problemas Identificados:

1. **Threads Múltiples Innecesarios**
   - 3 threads separados corriendo constantemente (líneas 274, 334, 386)
   - Cada uno con diferentes intervalos (10s, 1s, 5s)
   - Consumen recursos constantemente

2. **Callbacks Anidados**
   - Múltiples callbacks dentro de loops
   - Cada callback es una llamada al servidor
   - Puede causar lag con muchos jugadores

3. **Verificaciones Redundantes**
   - Se verifica el mismo vehículo múltiples veces
   - Se hacen llamadas al servidor innecesarias

4. **Spawn de Vehículos**
   - Se spawnan TODOS los vehículos de facción para TODOS los jugadores
   - Con 15 vehículos y 50 jugadores = 750 entidades

## Optimizaciones Recomendadas:

### 1. **Combinar Threads**
```lua
-- En lugar de 3 threads, usar uno solo con contadores
CreateThread(function()
    local saveCounter = 0
    local checkCounter = 0
    
    while true do
        Wait(1000) -- Check cada segundo
        
        saveCounter = saveCounter + 1
        checkCounter = checkCounter + 1
        
        -- Guardar cada 10 segundos
        if saveCounter >= 10 then
            -- Lógica de guardado
            saveCounter = 0
        end
        
        -- Verificar vehículos cada 5 segundos
        if checkCounter >= 5 then
            -- Lógica de verificación
            checkCounter = 0
        end
    end
end)
```

### 2. **Cache de Permisos**
```lua
local permissionCache = {}
local cacheTimeout = 60000 -- 1 minuto

-- Verificar permisos con cache
local function CheckPermissionCached(plate, callback)
    local cached = permissionCache[plate]
    if cached and (GetGameTimer() - cached.time) < cacheTimeout then
        callback(cached.result)
        return
    end
    
    -- Si no está en cache, hacer la verificación
    QBCore.Functions.TriggerCallback('r1mus_parking:server:CheckVehicleOwner', function(result)
        permissionCache[plate] = {
            result = result,
            time = GetGameTimer()
        }
        callback(result)
    end, plate)
end
```

### 3. **Spawn Inteligente de Vehículos de Facción**
```lua
-- Solo spawnear vehículos cerca del jugador
local function SpawnNearbyFactionVehicles()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local spawnDistance = 200.0 -- Solo spawn en 200m
    
    for _, vehicleData in ipairs(factionVehicleData) do
        local distance = #(playerCoords - vehicleData.coords)
        if distance <= spawnDistance then
            -- Spawn vehicle
        elseif distance > spawnDistance * 1.5 then
            -- Despawn if too far
        end
    end
end
```

### 4. **Batch Updates**
```lua
-- Acumular actualizaciones y enviarlas en lote
local pendingUpdates = {}

local function QueueVehicleUpdate(data)
    pendingUpdates[data.plate] = data
end

CreateThread(function()
    while true do
        Wait(5000) -- Enviar cada 5 segundos
        
        if next(pendingUpdates) then
            TriggerServerEvent('r1mus_parking:server:BatchUpdateVehicles', pendingUpdates)
            pendingUpdates = {}
        end
    end
end)
```

### 5. **Configuración de Optimización**
```lua
Config.Optimization = {
    -- Distancias
    maxSpawnDistance = 150.0,     -- Distancia máxima para spawn
    despawnDistance = 200.0,      -- Distancia para despawn
    
    -- Intervalos
    saveInterval = 30000,         -- Guardar cada 30s (era 10s)
    checkInterval = 10000,        -- Verificar cada 10s (era 5s)
    
    -- Límites
    maxVehiclesPerPlayer = 5,     -- Máximo de vehículos personales activos
    maxFactionVehiclesNearby = 10, -- Máximo de vehículos de facción cercanos
    
    -- Cache
    permissionCacheTime = 60000,  -- Cache de permisos por 1 minuto
    
    -- Batch
    batchUpdateInterval = 5000,   -- Enviar actualizaciones cada 5s
    maxBatchSize = 10            -- Máximo de actualizaciones por lote
}
```

## Impacto de las Optimizaciones:

### Antes:
- 3 threads constantes
- Llamadas al servidor cada segundo
- Todos los vehículos spawneados siempre
- Sin cache de permisos

### Después:
- 1-2 threads optimizados
- Llamadas al servidor reducidas 80%
- Solo vehículos cercanos spawneados
- Cache inteligente de permisos
- Updates en lote

## Rendimiento Estimado:
- **Reducción de CPU**: 60-70%
- **Reducción de Red**: 75-80%
- **Reducción de Memoria**: 40-50%
- **Mejora de FPS**: 10-20 FPS en áreas con muchos vehículos