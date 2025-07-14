local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local spawnedVehicles = {}
local lastSavedPositions = {}
local isSpawning = false
local isInitialized = false
local lastCoords = nil
local factionVehicles = {} -- Track de vehículos de facción

-- Función para mostrar notificaciones
local function ShowNotification(message, nType)
    if not Config.NotificationSystem then return end
    if not message then return end
    
    -- Convertir a string si es necesario
    if type(message) ~= "string" then
        message = tostring(message)
    end
    
    -- Tipo de notificación por defecto
    nType = nType or 'primary'
    
    if Config.NotificationSystem.type == 'qb' then
        QBCore.Functions.Notify(message, nType)
    elseif Config.NotificationSystem.type == 'origen' then
        exports['origen_notify']:Notify(message, nType)
    elseif Config.NotificationSystem.type == 'ox' then
        exports['ox_lib']:notify({
            description = message,
            type = nType
        })
    elseif Config.NotificationSystem.type == 'esx' then
        if nType == 'error' then
            message = '~r~' .. message
        elseif nType == 'success' then
            message = '~g~' .. message
        end
        ESX.ShowNotification(message)
    elseif Config.NotificationSystem.type == 'custom' and Config.NotificationSystem.customNotify then
        Config.NotificationSystem.customNotify(message, nType)
    end
end

-- Sistema de cache para optimización
local permissionCache = {}
local lastVehicleCheck = 0
local lastPositionSave = 0

-- Función para obtener propiedades del vehículo
local function GetVehicleProperties(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
    if not vehicleProps then return nil end

    -- Propiedades adicionales - Asegurar valores correctos
    vehicleProps.fuelLevel = exports['qb-fuel']:GetFuel(vehicle)
    vehicleProps.bodyHealth = GetVehicleBodyHealth(vehicle) + 0.0 -- Forzar float
    vehicleProps.engineHealth = GetVehicleEngineHealth(vehicle) + 0.0
    vehicleProps.tankHealth = GetVehiclePetrolTankHealth(vehicle) + 0.0
    vehicleProps.dirtLevel = GetVehicleDirtLevel(vehicle) + 0.0
    
    -- Detectar tipo de vehículo
    local isBoat = exports['r1mus_parking']:IsVehicleABoat(vehicle)
    vehicleProps.vehicleType = isBoat and 'boat' or 'car'
    
    -- Guardar información de daños visuales
    vehicleProps.doorsBroken = {}
    for i = 0, 5 do
        if IsVehicleDoorDamaged(vehicle, i) then
            vehicleProps.doorsBroken[i] = true
        end
    end
    
    vehicleProps.windowsBroken = {}
    for i = 0, 7 do
        if not IsVehicleWindowIntact(vehicle, i) then
            vehicleProps.windowsBroken[i] = true
        end
    end
    
    vehicleProps.tyreBurst = {}
    for i = 0, 5 do
        if IsVehicleTyreBurst(vehicle, i, false) then
            vehicleProps.tyreBurst[i] = true
        end
    end

    return vehicleProps
end

-- Función para aplicar propiedades al vehículo
local function SetVehicleProperties(vehicle, props)
    if not DoesEntityExist(vehicle) or not props then return end

    QBCore.Functions.SetVehicleProperties(vehicle, props)

    -- Aplicar daños y propiedades adicionales
    if props.fuelLevel then exports['qb-fuel']:SetFuel(vehicle, props.fuelLevel) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
    
    -- Aplicar daños visuales
    if props.doorsBroken then
        for doorIndex, _ in pairs(props.doorsBroken) do
            SetVehicleDoorBroken(vehicle, tonumber(doorIndex), true)
        end
    end
    
    if props.windowsBroken then
        for windowIndex, _ in pairs(props.windowsBroken) do
            SmashVehicleWindow(vehicle, tonumber(windowIndex))
        end
    end
    
    if props.tyreBurst then
        for tyreIndex, _ in pairs(props.tyreBurst) do
            SetVehicleTyreBurst(vehicle, tonumber(tyreIndex), true, 1000.0)
        end
    end
end

-- Función para restaurar vehículo
local function RestoreVehicle(data)
    if not data or not data.plate then 
        print("^1Error: No hay datos de vehículo o matrícula")
        return 
    end
    
    print("^2Intentando restaurar vehículo: " .. data.plate)
    print("^2Modelo: " .. data.model)
    print("^2Coordenadas: x=" .. data.coords.x .. ", y=" .. data.coords.y .. ", z=" .. data.coords.z)

    -- Verificar si ya existe
    if spawnedVehicles[data.plate] then
        if DoesEntityExist(spawnedVehicles[data.plate]) then
            print("^3Vehículo ya existe, actualizando propiedades")
            SetVehicleProperties(spawnedVehicles[data.plate], data.properties)
            return
        else
            print("^1Vehículo registrado pero no existe, limpiando registro")
            spawnedVehicles[data.plate] = nil
            TriggerServerEvent('r1mus_parking:server:VehicleRemoved', data.plate)
        end
    end

    -- Preparar el hash del modelo
    local hash = GetHashKey(data.model)
    print("^2Hash del modelo: " .. hash)
    
    if not IsModelInCdimage(hash) then
        print("^1Error: Modelo no válido")
        return
    end

    -- Cargar el modelo
    print("^2Cargando modelo...")
    RequestModel(hash)
    
    -- Sistema mejorado de carga de modelos
    local attempts = 0
    local maxAttempts = 20 -- 20 segundos máximo
    
    while not HasModelLoaded(hash) do
        attempts = attempts + 1
        if attempts >= maxAttempts then
            -- Intentar una última vez con carga forzada
            SetModelAsNoLongerNeeded(hash)
            Wait(500)
            RequestModel(hash)
            Wait(1000)
            
            if not HasModelLoaded(hash) then
                print("^1Error al cargar modelo después de múltiples intentos")
                TriggerEvent('r1mus_parking:client:SpawnError', {
                    plate = data.plate,
                    error = 'model_load_failed'
                })
                return
            end
        end
        Wait(1000) -- Esperar 1 segundo entre intentos
    end
    print("^2Modelo cargado correctamente")

    -- Crear vehículo
    print("^2Creando vehículo...")
    local vehicle = CreateVehicle(hash, data.coords.x, data.coords.y, data.coords.z + 1.0, data.heading, true, true)
    
    if not DoesEntityExist(vehicle) then
        print("^1Error al crear vehículo")
        return
    end
    print("^2Vehículo creado con ID: " .. vehicle)

    -- Configuración básica
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, data.plate)
    
    -- Colocar en el suelo
    local attempts = 0
    while not IsVehicleOnAllWheels(vehicle) and attempts < 5 do
        SetVehicleOnGroundProperly(vehicle)
        Wait(100)
        attempts = attempts + 1
        print("^3Intento " .. attempts .. " de colocar vehículo en el suelo")
    end

    -- Aplicar propiedades
    if data.properties then
        print("^2Aplicando propiedades personalizadas")
        SetVehicleProperties(vehicle, data.properties)
        
        -- Asegurar que los daños se apliquen correctamente
        if data.properties.bodyHealth then
            SetVehicleBodyHealth(vehicle, data.properties.bodyHealth + 0.0)
        end
        if data.properties.engineHealth then
            SetVehicleEngineHealth(vehicle, data.properties.engineHealth + 0.0)
        end
        if data.properties.tankHealth then
            SetVehiclePetrolTankHealth(vehicle, data.properties.tankHealth + 0.0)
        end
    else
        print("^2Aplicando propiedades por defecto")
        SetVehicleBodyHealth(vehicle, data.bodyHealth or 1000.0)
        SetVehicleEngineHealth(vehicle, data.engineHealth or 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        exports['qb-fuel']:SetFuel(vehicle, data.fuelLevel or 100.0)
    end
    
    -- Forzar actualización visual del daño
    SetVehicleDeformationFixed(vehicle)
    Wait(10)
    if data.properties and data.properties.bodyHealth and data.properties.bodyHealth < 900 then
        -- Si el vehículo está dañado, aplicar deformación visual
        SetVehicleBodyHealth(vehicle, data.properties.bodyHealth + 0.0)
    end

    -- Configuración final
    SetVehicleDoorsLocked(vehicle, 2)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    
    -- Registrar el vehículo
    spawnedVehicles[data.plate] = vehicle
    print("^2Vehículo restaurado exitosamente")
    
    -- Dar llaves al jugador
    TriggerServerEvent('vehiclekeys:server:GiveVehicleKeys', data.plate, GetPlayerServerId(PlayerId()))
    
    SetModelAsNoLongerNeeded(hash)
end

-- Función para restaurar vehículo de facción
local function RestoreFactionVehicle(data)
    if not data or not data.plate then
        print("^1Error: No hay datos de vehículo de facción o matrícula")
        return
    end
    
    print("^2Intentando restaurar vehículo de facción: " .. data.plate .. " - " .. data.label)
    
    -- Verificar si ya existe
    if factionVehicles[data.plate] then
        if DoesEntityExist(factionVehicles[data.plate]) then
            print("^3Vehículo de facción ya existe")
            return
        else
            factionVehicles[data.plate] = nil
        end
    end
    
    -- Cargar modelo
    local hash = GetHashKey(data.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(50)
    end
    
    -- Crear vehículo
    local vehicle = CreateVehicle(hash, data.coords.x, data.coords.y, data.coords.z + 1.0, data.heading, true, true)
    
    if not DoesEntityExist(vehicle) then
        print("^1Error al crear vehículo de facción")
        return
    end
    
    -- Configuración básica
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, data.plate)
    SetVehicleOnGroundProperly(vehicle)
    
    -- Aplicar livery si existe
    if data.livery then
        SetVehicleLivery(vehicle, data.livery)
    end
    
    -- Aplicar extras
    if data.extras then
        for _, extra in ipairs(data.extras) do
            SetVehicleExtra(vehicle, extra, 0) -- 0 = activar extra
        end
    end
    
    -- Aplicar propiedades
    if data.mods and next(data.mods) then
        SetVehicleProperties(vehicle, data.mods)
    else
        SetVehicleBodyHealth(vehicle, data.bodyHealth or 1000.0)
        SetVehicleEngineHealth(vehicle, data.engineHealth or 1000.0)
        exports['qb-fuel']:SetFuel(vehicle, data.fuelLevel or 100.0)
        SetVehicleDirtLevel(vehicle, data.dirtLevel or 0.0)
    end
    
    -- Configuración de facción
    SetVehicleDoorsLocked(vehicle, 1) -- Desbloqueado por defecto para miembros
    SetVehicleNeedsToBeHotwired(vehicle, false)
    
    -- Registrar
    factionVehicles[data.plate] = vehicle
    print("^2Vehículo de facción restaurado: " .. data.label)
    
    SetModelAsNoLongerNeeded(hash)
end

-- Función para verificar si es vehículo de facción
local function IsFactionVehicle(plate)
    return factionVehicles[plate] ~= nil
end

-- Sistema de bloqueo de vehículos
local function HandleVehicleLock()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local vehicle = nil

    if IsPedInAnyVehicle(player, false) then
        vehicle = GetVehiclePedIsIn(player, false)
    else
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 8.0, 0, 71)
    end

    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        
        -- Verificar si es vehículo de facción
        if IsFactionVehicle(plate) then
            QBCore.Functions.TriggerCallback('r1mus_parking:server:CanUseFactionVehicle', function(canUse)
                if canUse then
                    local lockStatus = GetVehicleDoorLockStatus(vehicle)
                    if lockStatus == 1 then
                        SetVehicleDoorsLocked(vehicle, 2)
                        if Config.VehicleLock.soundEnabled then
                            PlaySoundFromEntity(-1, Config.VehicleLock.lockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                        end
                        QBCore.Functions.Notify('Vehículo de facción bloqueado', 'success')
                    else
                        SetVehicleDoorsLocked(vehicle, 1)
                        if Config.VehicleLock.soundEnabled then
                            PlaySoundFromEntity(-1, Config.VehicleLock.unlockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                        end
                        QBCore.Functions.Notify('Vehículo de facción desbloqueado', 'success')
                    end
                else
                    QBCore.Functions.Notify('No tienes permiso para usar este vehículo', 'error')
                end
            end, plate)
        else
            -- Vehículo personal
            QBCore.Functions.TriggerCallback('r1mus_parking:server:CheckVehicleOwner', function(isOwner)
                if isOwner then
                    local lockStatus = GetVehicleDoorLockStatus(vehicle)
                    if lockStatus == 1 then -- Desbloqueado
                        SetVehicleDoorsLocked(vehicle, 2)
                        if Config.VehicleLock.soundEnabled then
                            PlaySoundFromEntity(-1, Config.VehicleLock.lockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                        end
                        QBCore.Functions.Notify('Vehículo bloqueado', 'success')
                    else
                        SetVehicleDoorsLocked(vehicle, 1)
                        if Config.VehicleLock.soundEnabled then
                            PlaySoundFromEntity(-1, Config.VehicleLock.unlockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                        end
                        QBCore.Functions.Notify('Vehículo desbloqueado', 'success')
                    end
                end
            end, plate)
        end
    end
end

-- Función para verificar permisos con cache
local function CheckPermissionCached(plate, isFaction, callback)
    local cacheKey = plate .. (isFaction and "_faction" or "_personal")
    local cached = permissionCache[cacheKey]
    
    if Config.Optimization.enablePermissionCache and cached and (GetGameTimer() - cached.time) < Config.Optimization.cacheTimeout then
        callback(cached.result)
        return
    end
    
    if isFaction then
        QBCore.Functions.TriggerCallback('r1mus_parking:server:CanUseFactionVehicle', function(result)
            permissionCache[cacheKey] = {
                result = result,
                time = GetGameTimer()
            }
            callback(result)
        end, plate)
    else
        QBCore.Functions.TriggerCallback('r1mus_parking:server:CheckVehicleOwner', function(result)
            permissionCache[cacheKey] = {
                result = result,
                time = GetGameTimer()
            }
            callback(result)
        end, plate)
    end
end

-- Thread principal optimizado
CreateThread(function()
    while true do
        Wait(1000) -- Check cada segundo
        
        if isInitialized then
            local currentTime = GetGameTimer()
            local playerPed = PlayerPedId()
            local checkInterval = Config.Optimization.vehicleCheckInterval or 5000 -- Valor por defecto si no está definido
            
            -- Verificar vehículos desaparecidos
            if not lastVehicleCheck or (currentTime - lastVehicleCheck) > checkInterval then
                lastVehicleCheck = currentTime
                
                -- Verificar vehículos personales
                for plate, vehicle in pairs(spawnedVehicles) do
                    if vehicle and not DoesEntityExist(vehicle) then
                        spawnedVehicles[plate] = nil
                        if permissionCache then
                            permissionCache[plate .. "_personal"] = nil -- Limpiar cache
                        end
                        TriggerServerEvent('r1mus_parking:server:VehicleRemoved', plate)
                    end
                end
                
                -- Verificar vehículos de facción
                for plate, vehicle in pairs(factionVehicles) do
                    if not DoesEntityExist(vehicle) then
                        factionVehicles[plate] = nil
                        permissionCache[plate .. "_faction"] = nil -- Limpiar cache
                        TriggerServerEvent('r1mus_parking:server:VehicleRemoved', plate)
                    end
                end
            end
            
            -- Guardar posición del vehículo actual
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if DoesEntityExist(vehicle) then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    local coords = GetEntityCoords(vehicle)
                    local heading = GetEntityHeading(vehicle)
                    local isStopped = IsVehicleStopped(vehicle)
                    local isFaction = IsFactionVehicle(plate)
                    
                    -- Guardar cuando está detenido o cada 30 segundos
                    local shouldSave = false
                    if isStopped and (not lastSavedPositions[plate] or not lastSavedPositions[plate].wasStopped) then
                        -- Acaba de detenerse
                        shouldSave = true
                    elseif currentTime - lastPositionSave > Config.Optimization.positionSaveInterval then
                        -- Han pasado 30 segundos
                        if not lastSavedPositions[plate] or #(lastSavedPositions[plate].coords - coords) > Config.Optimization.minDistanceToUpdate then
                            shouldSave = true
                            lastPositionSave = currentTime
                        end
                    end
                    
                    if shouldSave then
                        CheckPermissionCached(plate, isFaction, function(hasPermission)
                            if hasPermission then
                                lastSavedPositions[plate] = {
                                    coords = coords,
                                    heading = heading,
                                    wasStopped = isStopped
                                }
                                
                                local vehicleProps = GetVehicleProperties(vehicle)
                                local eventName = isFaction and 'r1mus_parking:server:UpdateFactionVehiclePosition' or 'r1mus_parking:server:UpdateVehiclePosition'
                                
                                TriggerServerEvent(eventName, {
                                    plate = plate,
                                    coords = coords,
                                    heading = heading,
                                    properties = vehicleProps,
                                    stopped = isStopped
                                })
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- Eventos
RegisterNetEvent('r1mus_parking:client:RestoreVehicle', function(data)
    RestoreVehicle(data)
end)

RegisterNetEvent('r1mus_parking:client:RestoreFactionVehicle', function(data)
    RestoreFactionVehicle(data)
end)

-- Variables para el sistema de NPC
local impoundPed = nil
local hasSpawnedPed = false

-- Función para cargar modelo de NPC
local function LoadPedModel(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelValid(hash) then
        print("^1Modelo inválido: " .. modelName)
        return false
    end

    print("^2Intentando cargar modelo: " .. modelName)
    RequestModel(hash)
    
    local timeout = 0
    local maxTimeout = 100 -- Aumentado el tiempo máximo de espera
    
    while not HasModelLoaded(hash) and timeout < maxTimeout do
        Wait(100)
        timeout = timeout + 1
        
        -- Cada 20 intentos, volver a solicitar el modelo
        if timeout % 20 == 0 then
            SetModelAsNoLongerNeeded(hash)
            Wait(500)
            RequestModel(hash)
        end
    end

    if HasModelLoaded(hash) then
        print("^2Modelo cargado exitosamente: " .. modelName)
        return hash
    end

    print("^1Error al cargar modelo: " .. modelName)
    SetModelAsNoLongerNeeded(hash)
    return false
end

-- Spawn del NPC del depósito
local function SpawnImpoundPed()
    if not Config.Impound.enabled or not Config.Impound.ped.enabled then return end
    
    -- Si el NPC ya existe y está en buen estado, no hacer nada
    if impoundPed and DoesEntityExist(impoundPed) then
        local pedCoords = GetEntityCoords(impoundPed)
        local targetCoords = Config.Impound.ped.coords
        if #(pedCoords - targetCoords) < 3.0 and not IsPedDeadOrDying(impoundPed, true) then
            return
        end
    end

    -- Solo mostrar mensaje de debug si realmente vamos a spawnear
    if Config.Debug then
        print("^2Iniciando proceso de spawn del NPC del depósito")
    end
    
    -- Intentar cada modelo en la lista hasta que uno funcione
    local hash = nil
    if Config.Impound.ped.models and #Config.Impound.ped.models > 0 then
        for _, modelName in ipairs(Config.Impound.ped.models) do
            print("^3Intentando cargar modelo: " .. modelName)
            hash = LoadPedModel(modelName)
            if hash then
                print("^2Modelo exitoso: " .. modelName)
                break
            end
            Wait(500) -- Pequeña espera entre intentos
        end
    end
    
    -- Si ningún modelo funcionó, usar un modelo por defecto
    if not hash then
        local defaultModel = 'a_m_m_business_01'
        print("^3Ningún modelo configurado funcionó, intentando modelo por defecto: " .. defaultModel)
        hash = LoadPedModel(defaultModel)
    end

    if not hash then
        print("^1Error: Ningún modelo de NPC pudo ser cargado")
        return
    end

    -- Crear el NPC con sistema de respawn
    local coords = Config.Impound.ped.coords
    local attempts = 0
    local maxAttempts = 3

    -- Limpiar cualquier NPC anterior
    if impoundPed and DoesEntityExist(impoundPed) then
        DeleteEntity(impoundPed)
        impoundPed = nil
        Wait(1000)
    end

    while attempts < maxAttempts do
        print("^3Intento " .. (attempts + 1) .. " de crear NPC")
        
        -- Limpiar el área antes de crear el NPC
        ClearAreaOfPeds(coords.x, coords.y, coords.z, 2.0, 1)
        Wait(500)
        
        -- Verificar que el modelo sigue cargado
        if not HasModelLoaded(hash) then
            RequestModel(hash)
            Wait(1000)
        end
        
        -- Crear el NPC con más opciones de configuración
        impoundPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, Config.Impound.ped.heading, false, false)
        
        if DoesEntityExist(impoundPed) then
            -- Configuración inmediata para evitar problemas
            SetEntityAsMissionEntity(impoundPed, true, true)
            SetBlockingOfNonTemporaryEvents(impoundPed, true)
            SetPedDiesWhenInjured(impoundPed, false)
            FreezeEntityPosition(impoundPed, true)
            SetEntityInvincible(impoundPed, true)
            SetPedCanRagdoll(impoundPed, false)
            SetPedCanBeTargetted(impoundPed, false)
            
            -- Verificar que el NPC sigue existiendo después de la configuración
            if DoesEntityExist(impoundPed) then
                print("^2NPC creado exitosamente")
                break
            else
                print("^1NPC se eliminó durante la configuración")
            end
        end
        
        print("^1Intento " .. (attempts + 1) .. " de crear NPC fallido, reintentando...")
        attempts = attempts + 1
        Wait(2000) -- Mayor tiempo de espera entre intentos
        
        -- Limpiar recursos si el intento falló
        if impoundPed and DoesEntityExist(impoundPed) then
            DeleteEntity(impoundPed)
            impoundPed = nil
        end
    end
    
    if not DoesEntityExist(impoundPed) then
        print("^1Error: No se pudo crear el NPC después de múltiples intentos")
        return
    end

    -- Configurar el escenario del NPC después de un breve delay
    Wait(1000) -- Dar tiempo a que el NPC se estabilice
    if DoesEntityExist(impoundPed) then
        -- Doble verificación de configuraciones críticas
        SetEntityAsMissionEntity(impoundPed, true, true)
        SetBlockingOfNonTemporaryEvents(impoundPed, true)
        SetPedDiesWhenInjured(impoundPed, false)
        SetEntityInvincible(impoundPed, true)
        FreezeEntityPosition(impoundPed, true)
        SetPedCanRagdoll(impoundPed, false)
        SetPedCanBeTargetted(impoundPed, false)
        
        -- Configuración adicional para estabilidad
        SetEntityProofs(impoundPed, true, true, true, true, true, true, true, true)
        SetPedConfigFlag(impoundPed, 185, true) -- CPED_CONFIG_FLAG_DisableWheelieStats
        SetPedConfigFlag(impoundPed, 108, true) -- CPED_CONFIG_FLAG_DontActivateRagdollFromVehicleImpact
        SetPedConfigFlag(impoundPed, 208, true) -- CPED_CONFIG_FLAG_DisallowVehicleEvasiveAnims
        
        -- Aplicar escenario si está configurado
        if Config.Impound.ped.scenario then
            ClearPedTasksImmediately(impoundPed)
            Wait(500)
            TaskStartScenarioInPlace(impoundPed, Config.Impound.ped.scenario, 0, true)
        end
    end

    -- Configurar interacción
    exports['qb-target']:AddTargetEntity(impoundPed, {
        options = {
            {
                type = "client",
                event = "r1mus_parking:client:OpenImpoundMenu",
                icon = "fas fa-car",
                label = "Abrir Menú Depósito"
            }
        },
        distance = 2.5
    })

    -- Marcar como spawneado
    hasSpawnedPed = true
    print("^2NPC del depósito creado exitosamente")
    
    if Config.Impound.ped.scenario then
        TaskStartScenarioInPlace(ped, Config.Impound.ped.scenario, 0, true)
    end

    -- Crear zona de interacción
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = "r1mus_parking:client:OpenImpoundMenu",
                icon = "fas fa-car",
                label = "Abrir Menú Depósito",
            }
        },
        distance = 2.5
    })
end

-- Sistema de spawn del NPC del depósito
local impoundPed = nil

local function EnsureImpoundPed()
    -- Si el NPC ya existe y es válido, verificar su estado
    if impoundPed and DoesEntityExist(impoundPed) then
        -- Verificar si el NPC está en su posición correcta
        local pedCoords = GetEntityCoords(impoundPed)
        local configCoords = Config.Impound.ped.coords
        local distance = #(pedCoords - configCoords)
        
        if distance > 2.0 then
            print("^3NPC fuera de posición, recolocando...")
            SetEntityCoords(impoundPed, configCoords.x, configCoords.y, configCoords.z - 1.0, false, false)
            SetEntityHeading(impoundPed, Config.Impound.ped.heading)
        end
        return
    end
    
    -- Si el sistema está deshabilitado, no hacer nada
    if not Config.Impound.enabled or not Config.Impound.ped.enabled then return end

    -- Reintentar el spawn del NPC
    print("^3NPC no existe, iniciando proceso de spawn")
    SpawnImpoundPed()

    -- Crear el NPC
    local coords = Config.Impound.ped.coords
    impoundPed = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, Config.Impound.ped.heading, false, true)
    
    if not DoesEntityExist(impoundPed) then
        print("^1Error creating impound ped")
        return
    end

    -- Configurar el NPC
    SetEntityAsMissionEntity(impoundPed, true, true)
    SetBlockingOfNonTemporaryEvents(impoundPed, true)
    SetPedDiesWhenInjured(impoundPed, false)
    SetEntityInvincible(impoundPed, true)
    FreezeEntityPosition(impoundPed, true)
    
    -- Aplicar escenario si está configurado
    if Config.Impound.ped.scenario then
        TaskStartScenarioInPlace(impoundPed, Config.Impound.ped.scenario, 0, true)
    end

    -- Configurar interacción con qb-target
    exports['qb-target']:AddTargetEntity(impoundPed, {
        options = {
            {
                type = "client",
                event = "r1mus_parking:client:OpenImpoundMenu",
                icon = "fas fa-car",
                label = "Abrir Menú Depósito",
            }
        },
        distance = 2.5
    })

    -- Liberar el modelo
    SetModelAsNoLongerNeeded(hash)
end

-- Variables para el control del NPC
local lastRespawnTime = 0
local respawnCooldown = 30000 -- 30 segundos de cooldown entre respawns
local lastVerifiedPosition = nil

-- Thread para mantener el NPC
CreateThread(function()
    while true do
        Wait(10000) -- Aumentado a 10 segundos
        
        if Config.Impound.enabled and Config.Impound.ped.enabled then
            -- Solo verificar si ha pasado el cooldown
            local currentTime = GetGameTimer()
            if currentTime - lastRespawnTime < respawnCooldown then
                goto continue
            end

            -- Verificar si el NPC existe y está en la posición correcta
            if impoundPed and DoesEntityExist(impoundPed) then
                local pedCoords = GetEntityCoords(impoundPed)
                local targetCoords = Config.Impound.ped.coords
                local distance = #(pedCoords - targetCoords)
                
                -- Verificar si el NPC necesita ser respawneado
                local needsRespawn = false
                
                -- Verificar condiciones críticas que requieren respawn inmediato
                if IsPedDeadOrDying(impoundPed, true) or not IsEntityVisible(impoundPed) then
                    needsRespawn = true
                end
                
                -- Si el NPC está muy lejos o en estado inválido
                if distance > 3.0 then
                    -- Intentar primero teletransportarlo
                    SetEntityCoords(impoundPed, targetCoords.x, targetCoords.y, targetCoords.z - 1.0, false, false, false, false)
                    SetEntityHeading(impoundPed, Config.Impound.ped.heading)
                    FreezeEntityPosition(impoundPed, true)
                    Wait(500)
                    
                    -- Verificar si el teletransporte funcionó
                    pedCoords = GetEntityCoords(impoundPed)
                    distance = #(pedCoords - targetCoords)
                    if distance > 3.0 then
                        needsRespawn = true
                    end
                end
                
                if needsRespawn then
                    DeleteEntity(impoundPed)
                    impoundPed = nil
                    Wait(1000)
                    SpawnImpoundPed()
                    lastRespawnTime = currentTime
                else
                    -- Solo reforzar configuraciones si son necesarias
                    if not IsEntityPositionFrozen(impoundPed) then
                        FreezeEntityPosition(impoundPed, true)
                    end
                    if not GetEntityInvincible(impoundPed) then
                        SetEntityInvincible(impoundPed, true)
                    end
                end
            elseif currentTime - lastRespawnTime >= respawnCooldown then
                SpawnImpoundPed()
                lastRespawnTime = currentTime
            end
            
            ::continue::
        end
    end
end)

-- Thread para verificar el NPC del depósito
CreateThread(function()
    while true do
        Wait(10000) -- Verificar cada 10 segundos
        
        if Config.Impound.enabled and Config.Impound.ped.enabled then
            if not impoundPed or not DoesEntityExist(impoundPed) then
                hasSpawnedPed = false
                SpawnImpoundPed()
            end
        end
    end
end)

-- Evento para forzar el respawn del NPC
RegisterNetEvent('r1mus_parking:client:RespawnImpoundPed', function()
    if impoundPed and DoesEntityExist(impoundPed) then
        DeleteEntity(impoundPed)
    end
    hasSpawnedPed = false
    Wait(1000)
    SpawnImpoundPed()
end)

-- Evento para abrir el menú del depósito
RegisterNetEvent('r1mus_parking:client:OpenImpoundMenu', function()
    QBCore.Functions.TriggerCallback('r1mus_parking:server:GetImpoundedVehicles', function(vehicles)
        if not vehicles or #vehicles == 0 then
            ShowNotification(Lang:t('info.no_impounded_vehicles'), 'info')
            return
        end

        local menuItems = {
            {
                header = "Depósito Municipal",
                isMenuHeader = true
            }
        }
        
        for _, vehicle in ipairs(vehicles) do
            local vehicleData = json.decode(vehicle.vehicle)
            local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(vehicleData.model))
            if vehicleName == 'NULL' then vehicleName = vehicleData.model end
            
            table.insert(menuItems, {
                header = vehicleName .. ' - ' .. vehicle.plate,
                txt = "Tarifa: $" .. Config.Impound.fee .. " | Motor: " .. math.floor((vehicleData.engineHealth or 1000)/10) .. "% | Carrocería: " .. math.floor((vehicleData.bodyHealth or 1000)/10) .. "%",
                params = {
                    isServer = false,
                    event = 'r1mus_parking:client:PayImpoundFee',
                    args = vehicle
                }
            })
        end

        table.insert(menuItems, {
            header = "❌ Cerrar",
            txt = "Cerrar menú",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        })

        exports['qb-menu']:openMenu(menuItems)
    end)
end)

-- Evento para localizar vehículo
RegisterNetEvent('r1mus_parking:client:LocateVehicle', function(data)
    if not data or not data.coords then
        QBCore.Functions.Notify(Lang:t('error.vehicle_not_found'), 'error')
        return
    end

    -- Convertir coordenadas si es necesario
    local coords = type(data.coords) == 'string' and json.decode(data.coords) or data.coords
    
    -- Establecer waypoint
    SetNewWaypoint(coords.x, coords.y)
    
    -- Notificar al jugador
    QBCore.Functions.Notify(Lang:t('success.vehicle_located'), 'success')
    
    -- Mostrar distancia
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
    QBCore.Functions.Notify(string.format('Distancia: %.1f metros', distance), 'info')
end)

-- Sistema de control de posiciones del depósito
local occupiedPositions = {}

-- Función para encontrar una posición de spawn disponible
local function GetAvailableSpawnPosition()
    for index, position in ipairs(Config.Impound.spawnPositions) do
        if not occupiedPositions[index] then
            occupiedPositions[index] = true
            -- Liberar la posición después de 30 segundos
            SetTimeout(30000, function()
                occupiedPositions[index] = false
            end)
            return position
        end
    end
    -- Si todas las posiciones están ocupadas, usar la primera
    return Config.Impound.spawnPositions[1]
end

-- Control de puerta del depósito
local gateObject = nil
local gateState = false -- false = cerrado, true = abierto

-- Función para controlar la puerta del depósito
local function ControlImpoundGate(state)
    if not gateObject then
        gateObject = GetClosestObjectOfType(
            Config.Impound.location.gate.coords.x,
            Config.Impound.location.gate.coords.y,
            Config.Impound.location.gate.coords.z,
            5.0,
            Config.Impound.location.gate.model,
            false, false, false
        )
    end

    if DoesEntityExist(gateObject) then
        if state then -- Abrir
            SetEntityHeading(gateObject, Config.Impound.location.gate.heading + 90.0)
        else -- Cerrar
            SetEntityHeading(gateObject, Config.Impound.location.gate.heading)
        end
        gateState = state
    end
end

-- Evento para recuperar vehículo del depósito
RegisterNetEvent('r1mus_parking:client:RetrieveImpoundedVehicle', function(data)
    if not data or not data.plate then return end

    QBCore.Functions.TriggerCallback('r1mus_parking:server:PayImpoundFee', function(success)
        if success then
            -- Abrir la puerta
            ControlImpoundGate(true)
            
            -- Obtener el vehículo del depósito
            local vehicles = GetGamePool('CVehicle')
            local impoundedVehicle = nil
            
            for _, vehicle in ipairs(vehicles) do
                if GetVehicleNumberPlateText(vehicle) == data.plate then
                    impoundedVehicle = vehicle
                    break
                end
            end

            if impoundedVehicle then
                -- Desbloquear el vehículo específico
                SetVehicleDoorsLocked(impoundedVehicle, 1)
                
                -- Dar llaves al jugador
                TriggerServerEvent('vehiclekeys:server:GiveVehicleKeys', data.plate)
                
                -- Notificar al jugador
                ShowNotification(Lang:t('success.vehicle_released'), 'success')
                
                -- Cerrar la puerta después de 30 segundos
                SetTimeout(30000, function()
                    ControlImpoundGate(false)
                end)
            else
                ShowNotification(Lang:t('error.vehicle_not_found'), 'error')
            end
        else
            ShowNotification(Lang:t('error.insufficient_funds'), 'error')
        end
    end, data.fee)
end)

-- Evento para cuando un vehículo es incautado
RegisterNetEvent('r1mus_parking:server:OnVehicleImpounded', function(data)
    if not data or not data.plate then return end
    
    -- Encontrar una posición libre en el depósito
    local spawnPosition = nil
    for _, pos in ipairs(Config.Impound.location.spawnPositions) do
        local clear = true
        local vehicles = GetGamePool('CVehicle')
        for _, v in ipairs(vehicles) do
            local vehCoords = GetEntityCoords(v)
            local distance = #(vehCoords - pos.coords)
            if distance < 3.0 then
                clear = false
                break
            end
        end
        if clear then
            spawnPosition = pos
            break
        end
    end

    if spawnPosition then
        -- Spawnear el vehículo en el depósito
        local hash = GetHashKey(data.model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(0) end
        
        local vehicle = CreateVehicle(hash, spawnPosition.coords.x, spawnPosition.coords.y, spawnPosition.coords.z, spawnPosition.heading, true, false)
        
        SetVehicleNumberPlateText(vehicle, data.plate)
        SetVehicleDoorsLocked(vehicle, 2) -- Bloquear el vehículo
        SetEntityAsMissionEntity(vehicle, true, true)
        
        -- Aplicar propiedades y daños
        if data.properties then
            SetVehicleProperties(vehicle, data.properties)
        end
        
        SetModelAsNoLongerNeeded(hash)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    print("^2OnPlayerLoaded triggered")
    CreateThread(function()
        Wait(3000)
        print("^2Inicializando sistema de vehículos")
        PlayerData = QBCore.Functions.GetPlayerData()
        isInitialized = true
        
        -- Limpiar cualquier estado previo
        factionVehicles = {}
        if streamedFactionVehicles then streamedFactionVehicles = {} end
        if factionVehicleData then factionVehicleData = {} end
        
        -- Solicitar solo vehículos personales
        TriggerServerEvent('r1mus_parking:server:RequestAllVehicles')
        
        -- Los vehículos de facción se cargarán a través del sistema de streaming
        -- cuando el jugador se acerque a las zonas correspondientes

        SpawnImpoundPed()
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isInitialized = false
    -- Limpiar vehículos spawneados
    for plate, vehicle in pairs(spawnedVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    spawnedVehicles = {}
    
    -- Limpiar vehículos de facción
    for plate, vehicle in pairs(factionVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    factionVehicles = {}
end)

RegisterNetEvent('r1mus_parking:client:SpawnError', function(data)
    print("^1Error al spawnear vehículo: " .. (data.plate or 'desconocido'))
    if data.retryCount and data.retryCount < 3 then
        Wait(2000)
        local newData = {
            model = data.model,
            plate = data.plate,
            coords = data.coords,
            heading = data.heading,
            properties = data.properties,
            bodyHealth = data.bodyHealth,
            engineHealth = data.engineHealth,
            fuelLevel = data.fuelLevel,
            dirtLevel = data.dirtLevel,
            retryCount = (data.retryCount or 0) + 1
        }
        RestoreVehicle(newData)
    end
end)

-- Eventos de recursos
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Guardar estado final y eliminar vehículos
        for plate, vehicle in pairs(spawnedVehicles) do
            if DoesEntityExist(vehicle) then
                local coords = GetEntityCoords(vehicle)
                local heading = GetEntityHeading(vehicle)
                local props = GetVehicleProperties(vehicle)
                
                TriggerServerEvent('r1mus_parking:server:UpdateVehiclePosition', {
                    plate = plate,
                    coords = coords,
                    heading = heading,
                    properties = props,
                    final = true
                })
                
                DeleteEntity(vehicle)
            end
            TriggerServerEvent('r1mus_parking:server:VehicleRemoved', plate)
        end
        spawnedVehicles = {}
        
        -- También guardar vehículos de facción
        for plate, vehicle in pairs(factionVehicles) do
            if DoesEntityExist(vehicle) then
                local coords = GetEntityCoords(vehicle)
                local heading = GetEntityHeading(vehicle)
                local props = GetVehicleProperties(vehicle)
                
                TriggerServerEvent('r1mus_parking:server:UpdateFactionVehiclePosition', {
                    plate = plate,
                    coords = coords,
                    heading = heading,
                    properties = props,
                    final = true
                })
                
                DeleteEntity(vehicle)
            end
            TriggerServerEvent('r1mus_parking:server:VehicleRemoved', plate)
        end
        factionVehicles = {}
    end
end)

-- Al iniciar el recurso
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CreateThread(function()
            Wait(1000)
            if LocalPlayer.state.isLoggedIn then
                PlayerData = QBCore.Functions.GetPlayerData()
                isInitialized = true
                TriggerServerEvent('r1mus_parking:server:RequestAllVehicles')
                
                -- También solicitar vehículos de facción
                if PlayerData.job and Config.FactionVehicles and Config.FactionVehicles.enabled and Config.FactionVehicles.factions and Config.FactionVehicles.factions[PlayerData.job.name] then
                    TriggerServerEvent('r1mus_parking:server:RequestFactionVehicles')
                end
            end
        end)
    end
end)

-- Registro de comandos
-- Comando para encontrar vehículos
RegisterCommand('findvehicle', function(source, args)
    QBCore.Functions.TriggerCallback('r1mus_parking:server:GetPlayerVehicles', function(vehicles)
        if not vehicles or #vehicles == 0 then
            QBCore.Functions.Notify(Lang:t('info.no_owned_vehicles'), 'info')
            return
        end

        local Menu = {
            {
                header = "🚗 Tus Vehículos",
                isMenuHeader = true
            }
        }
        
        for _, vehicle in ipairs(vehicles) do
            local vehicleData = type(vehicle.vehicle) == 'string' and json.decode(vehicle.vehicle) or vehicle.vehicle
            if vehicleData then
                local model = type(vehicleData.model) == 'string' and vehicleData.model or GetDisplayNameFromVehicleModel(vehicleData.model)
                local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(model))
                if vehicleName == 'NULL' then vehicleName = model end
                
                local status = "🟢 Disponible"
                if vehicle.impounded then
                    status = "🔴 Incautado"
                elseif vehicle.state == 'out' then
                    status = "🟡 En uso"
                end
                
                local engineHealth = tonumber(vehicleData.engineHealth) or 1000
                local bodyHealth = tonumber(vehicleData.bodyHealth) or 1000
                
                table.insert(Menu, {
                    header = vehicleName .. " - " .. vehicle.plate,
                    txt = status .. " | Motor: " .. math.floor(engineHealth/10) .. "% | Carrocería: " .. math.floor(bodyHealth/10) .. "%",
                    params = {
                        event = 'r1mus_parking:client:LocateVehicle',
                        args = {
                            plate = vehicle.plate,
                            coords = type(vehicle.coords) == 'string' and json.decode(vehicle.coords) or vehicle.coords
                        }
                    }
                })
            end
        end

        -- Añadir opción de cerrar
        table.insert(Menu, {
            header = "❌ Cerrar",
            txt = "Cerrar menú",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        })

        -- Abrir el menú
        exports['qb-menu']:openMenu(Menu)
    end)
end)

-- Evento para localizar vehículo
RegisterNetEvent('r1mus_parking:client:LocateVehicle', function(data)
    if not data or not data.coords then
        QBCore.Functions.Notify(Lang:t('error.vehicle_not_found'), 'error')
        return
    end

    -- Convertir coordenadas si es necesario
    local coords = type(data.coords) == 'string' and json.decode(data.coords) or data.coords
    
    -- Establecer waypoint
    SetNewWaypoint(coords.x, coords.y)
    
    -- Notificar al jugador
    QBCore.Functions.Notify(Lang:t('success.vehicle_located'), 'success')
    
    -- Mostrar distancia
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
    QBCore.Functions.Notify(string.format('Distancia: %.1f metros', distance), 'info')
end)

-- Keybinding para bloqueo de vehículo
RegisterKeyMapping('togglelock', 'Toggle Vehicle Lock', 'keyboard', Config.VehicleLock.defaultKey)
RegisterCommand('togglelock', function()
    if Config.VehicleLock.enabled then
        HandleVehicleLock()
    end
end)

-- Registro del keymapping para bloqueo de vehículos
RegisterKeyMapping('togglevehiclelock', 'Bloquear/Desbloquear Vehículo', 'keyboard', Config.VehicleLock.defaultKey)

RegisterCommand('togglevehiclelock', function()
    if Config.VehicleLock.enabled then
        HandleVehicleLock()
    end
end, false)

RegisterNetEvent('r1mus_parking:client:SetVehicleRoute', function(coords)
    SetNewWaypoint(coords.x, coords.y)
    QBCore.Functions.Notify('Vehicle location marked on map', 'success')
end)
RegisterNetEvent('r1mus_parking:client:TeleportToCoords', function(coords)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
end)

-- Evento para cuando cambia el trabajo del jugador
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    local oldJob = PlayerData.job and PlayerData.job.name
    PlayerData.job = JobInfo
    
    -- Solo limpiar si el trabajo ha cambiado
    if oldJob ~= JobInfo.name then
        print("^2Cambiando de trabajo: " .. (oldJob or "ninguno") .. " a " .. JobInfo.name)
        
        -- Limpiar vehículos de facción existentes
        for plate, vehicle in pairs(factionVehicles) do
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
                print("^3Eliminando vehículo de facción anterior: " .. plate)
            end
            TriggerServerEvent('r1mus_parking:server:VehicleRemoved', plate)
        end
        factionVehicles = {}

        -- Limpiar vehículos en streaming
        if streamedFactionVehicles then
            for plate, vehicle in pairs(streamedFactionVehicles) do
                if DoesEntityExist(vehicle) then
                    DeleteEntity(vehicle)
                    print("^3Eliminando vehículo en streaming: " .. plate)
                end
            end
            streamedFactionVehicles = {}
        end
        
        -- Limpiar datos de streaming
        if factionVehicleData then
            factionVehicleData = {}
        end
    end
end)

-- Comando para ver vehículos de facción disponibles
RegisterCommand('factionvehicles', function()
    if not PlayerData.job then return end
    
    QBCore.Functions.TriggerCallback('r1mus_parking:server:GetFactionVehicles', function(vehicles)
        if vehicles and #vehicles > 0 then
            print("^2=== Vehículos de Facción Disponibles ===")
            for _, vehicle in ipairs(vehicles) do
                local status = vehicle.in_use and "^1EN USO^7" or "^2DISPONIBLE^7"
                print(string.format("^3%s^7 - %s [%s]", vehicle.plate, vehicle.label, status))
            end
        else
            QBCore.Functions.Notify('No hay vehículos de facción disponibles para tu trabajo', 'error')
        end
    end)
end)

-- Sistema de Incautación
RegisterNetEvent('r1mus_parking:client:ImpoundVehicle', function(reason)
    local playerPed = PlayerPedId()
    local vehicle = nil
    
    -- Verificar si está en un vehículo o cerca de uno
    if IsPedInAnyVehicle(playerPed, false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        local coords = GetEntityCoords(playerPed)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    
    if DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        
        -- Animación de incautación
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
        QBCore.Functions.Progressbar("impound_vehicle", "Incautando vehículo...", 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            ClearPedTasks(playerPed)
            
            -- Eliminar el vehículo
            DeleteEntity(vehicle)
            
            -- Notificar al servidor
            TriggerServerEvent('r1mus_parking:server:ImpoundVehicle', plate, reason)
            
            -- Actualizar tracking local
            if spawnedVehicles[plate] then
                spawnedVehicles[plate] = nil
            end
            if factionVehicles[plate] then
                factionVehicles[plate] = nil
            end
        end, function() -- Cancel
            ClearPedTasks(playerPed)
            QBCore.Functions.Notify('Incautación cancelada', 'error')
        end)
    else
        QBCore.Functions.Notify('No hay vehículo cerca para incautar', 'error')
    end
end)

-- Función para verificar si está lo suficientemente cerca del vehículo
local function IsNearVehicle(vehicle)
    if not vehicle then return false end
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(playerCoords - vehicleCoords)
    return distance <= 3.0 -- Debe estar a 3 metros o menos
end

-- Función para incautar vehículo con sistema de grúa automática
local function ImpoundVehicle(vehicle)
    if not vehicle then
        ShowNotification(Lang:t('error.no_vehicle'), 'error')
        return
    end

    if not IsNearVehicle(vehicle) then
        ShowNotification(Lang:t('error.must_be_closer'), 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then
        ShowNotification(Lang:t('error.invalid_plate'), 'error')
        return
    end
    
    -- Limpiar la matrícula de espacios
    plate = string.gsub(plate, "%s+", "")
    
    local vehicleCoords = GetEntityCoords(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local bodyHealth = GetVehicleBodyHealth(vehicle)
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local properties = GetVehicleProperties(vehicle)

    -- Buscar una posición disponible en el depósito
    local spawnPosition = nil
    for _, pos in ipairs(Config.Impound.location.spawnPositions) do
        local clear = true
        local vehicles = GetGamePool('CVehicle')
        for _, v in ipairs(vehicles) do
            local vehCoords = GetEntityCoords(v)
            local distance = #(vehCoords - pos.coords)
            if distance < 3.0 then
                clear = false
                break
            end
        end
        if clear then
            spawnPosition = pos
            break
        end
    end

    if not spawnPosition then
        ShowNotification(Lang:t('error.impound_full'), 'error')
        return
    end

    -- Animación de inspección del vehículo
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_CLIPBOARD", 0, true)
    QBCore.Functions.Progressbar("checking_vehicle", "Inspeccionando vehículo...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        ClearPedTasks(PlayerPedId())
        
        -- Spawneamos la grúa
        local towTruckHash = GetHashKey('flatbed')
        RequestModel(towTruckHash)
        while not HasModelLoaded(towTruckHash) do
            Wait(0)
        end
        
        -- Encontrar una posición adecuada para la grúa
        local offset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -8.0, 0.0)
        local towTruck = CreateVehicle(towTruckHash, offset.x, offset.y, offset.z, GetEntityHeading(vehicle), true, false)
        SetEntityAsMissionEntity(towTruck, true, true)
        
        -- Configurar la grúa
        SetVehicleEngineOn(towTruck, true, true, false)
        SetVehicleDoorsLocked(towTruck, 2)
        SetVehicleDoorsLockedForAllPlayers(towTruck, true)
        
        -- Animar la carga del vehículo
        SetVehicleDoorOpen(towTruck, 5, false, false)
        Wait(1000)
        
        -- Desactivar colisiones durante la carga
        SetEntityCollision(vehicle, false, false)
        
        -- Adjuntar el vehículo a la grúa
        AttachEntityToEntity(vehicle, towTruck, GetEntityBoneIndexByName(towTruck, 'bodyshell'), 0.0, -3.3, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        
        -- Notificar al servidor
        TriggerServerEvent('r1mus_parking:server:ImpoundVehicle', {
            plate = plate,
            vehicleCoords = vehicleCoords,
            heading = GetEntityHeading(vehicle),
            model = model,
            bodyHealth = bodyHealth,
            engineHealth = engineHealth
        })
        
        -- Animar la grúa alejándose
        TaskVehicleDriveToCoord(GetPedInVehicleSeat(towTruck, -1), towTruck, Config.Impound.location.entrance.x, Config.Impound.location.entrance.y, Config.Impound.location.entrance.z, 20.0, 1.0, GetEntityModel(towTruck), 524860, 1.0, true)
        
        -- Esperar unos segundos y luego limpiar
        Wait(5000)
        DeleteEntity(towTruck)
        DeleteEntity(vehicle)
        
        ShowNotification(Lang:t('success.vehicle_impounded'), 'success')
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        ShowNotification(Lang:t('error.impound_cancelled'), 'error')
    end)
end

RegisterNetEvent('r1mus_parking:client:ImpoundVehicle', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    if not vehicle then
        vehicle = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0)
    end
    
    if vehicle then
        ImpoundVehicle(vehicle)
    else
        ShowNotification(Lang:t('error.no_vehicle'), 'error')
    end
end)

-- Comando de impound mejorado
RegisterCommand('impound', function()
    local playerPed = PlayerPedId()
    local vehicle = nil
    local coords = GetEntityCoords(playerPed)

    -- Si el jugador está en un vehículo, usar ese
    if IsPedInAnyVehicle(playerPed, false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        -- Buscar el vehículo más cercano en un radio de 5 metros
        local vehicles = GetGamePool('CVehicle')
        local closestDist = 5.0
        local closestVeh = nil
        for _, v in ipairs(vehicles) do
            local vCoords = GetEntityCoords(v)
            local dist = #(coords - vCoords)
            if dist < closestDist then
                closestDist = dist
                closestVeh = v
            end
        end
        vehicle = closestVeh
    end

    if vehicle and DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        if not plate or plate == '' then
            ShowNotification('No se pudo obtener la matrícula del vehículo', 'error')
            return
        end

        -- Animación y barra de progreso
        TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
        QBCore.Functions.Progressbar("impound_vehicle", "Incautando vehículo...", 4000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            ClearPedTasks(playerPed)
            -- Guardar propiedades
            local vehicleProps = GetVehicleProperties(vehicle)
            local model = GetEntityModel(vehicle)
            local displayName = GetDisplayNameFromVehicleModel(model)
            local vehicleName = GetLabelText(displayName)
            -- Notificar al servidor
            TriggerServerEvent('r1mus_parking:server:ImpoundVehicle', {
                plate = plate,
                model = vehicleName ~= 'NULL' and vehicleName or displayName,
                properties = vehicleProps
            })
            -- Eliminar el vehículo
            DeleteEntity(vehicle)
            ShowNotification('Vehículo enviado al depósito', 'success')
        end, function()
            ClearPedTasks(playerPed)
            ShowNotification('Incautación cancelada', 'error')
        end)
    else
        ShowNotification('No se encontró el vehículo. Acércate más.', 'error')
    end
end, false)

-- Comando de localización mejorado
RegisterCommand('locatevehicle', function(source, args)
    if not args[1] then
        ShowNotification(Lang:t('error.specify_plate'), 'error')
        return
    end
    
    local plate = args[1]:upper()
    QBCore.Functions.TriggerCallback('r1mus_parking:server:LocateVehicle', function(result)
        if result.found then
            if result.state == 2 then -- Impounded
                ShowNotification(Lang:t('info.vehicle_at_impound'), 'info')
            else
                local distance = #(GetEntityCoords(PlayerPedId()) - vector3(result.location.x, result.location.y, result.location.z))
                ShowNotification(Lang:t('info.vehicle_located', {distance = math.floor(distance)}), 'success')
                
                -- Crear blip temporal
                local blip = AddBlipForCoord(result.location.x, result.location.y, result.location.z)
                SetBlipSprite(blip, 225)
                SetBlipColour(blip, 3)
                SetBlipScale(blip, 0.8)
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(result.model)
                EndTextCommandSetBlipName(blip)
                
                -- Eliminar blip después de 1 minuto
                SetTimeout(60000, function()
                    RemoveBlip(blip)
                end)
            end
        else
            ShowNotification(result.message, 'error')
        end
    end, plate)
end)

-- Evento para remover vehículo
RegisterNetEvent('r1mus_parking:client:RemoveVehicle', function(plate)
    if spawnedVehicles[plate] and DoesEntityExist(spawnedVehicles[plate]) then
        DeleteEntity(spawnedVehicles[plate])
        spawnedVehicles[plate] = nil
    end
end)

-- Evento para pagar la tarifa del depósito
RegisterNetEvent('r1mus_parking:client:PayImpoundFee', function(data)
    if not data or not data.plate then return end

    local Player = QBCore.Functions.GetPlayerData()
    local canPayCash = Player.money['cash'] >= Config.Impound.fee
    local canPayBank = Player.money['bank'] >= Config.Impound.fee

    exports['qb-menu']:openMenu({
        {
            header = "🚗 Recuperar Vehículo",
            txt = "Matrícula: " .. data.plate,
            isMenuHeader = true
        },
        {
            header = canPayCash and "💵 Pagar en efectivo" or "❌ Efectivo insuficiente",
            txt = "Costo: $" .. Config.Impound.fee .. (canPayCash and "" or " - No tienes suficiente efectivo"),
            disabled = not canPayCash,
            params = canPayCash and {
                event = "r1mus_parking:client:ConfirmRetrieveVehicle",
                args = {
                    plate = data.plate,
                    fee = Config.Impound.fee,
                    vehicle = data.vehicle,
                    paymentType = 'cash'
                }
            } or nil
        },
        {
            header = canPayBank and "💳 Pagar con tarjeta" or "❌ Saldo insuficiente",
            txt = "Costo: $" .. Config.Impound.fee .. (canPayBank and "" or " - No tienes suficiente saldo"),
            disabled = not canPayBank,
            params = canPayBank and {
                event = "r1mus_parking:client:ConfirmRetrieveVehicle",
                args = {
                    plate = data.plate,
                    fee = Config.Impound.fee,
                    vehicle = data.vehicle,
                    paymentType = 'bank'
                }
            } or nil
        },
        {
            header = "❌ Cancelar",
            txt = "Volver",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        }
    })
end)

-- Evento para confirmar la recuperación del vehículo
RegisterNetEvent('r1mus_parking:client:ConfirmRetrieveVehicle', function(data)
    if not data or not data.plate then return end

    QBCore.Functions.TriggerCallback('r1mus_parking:server:PayImpoundFee', function(success)
        if success then
            -- Buscar una posición libre cerca del depósito
            local spawnPoint = nil
            for _, pos in ipairs(Config.Impound.spawnPositions) do
                local clear = true
                local vehicles = GetGamePool('CVehicle')
                for _, v in ipairs(vehicles) do
                    local vehCoords = GetEntityCoords(v)
                    local distance = #(vehCoords - pos.coords)
                    if distance < 3.0 then
                        clear = false
                        break
                    end
                end
                if clear then
                    spawnPoint = pos
                    break
                end
            end

            if spawnPoint then
                -- Enviar evento al servidor para liberar el vehículo
                TriggerServerEvent('r1mus_parking:server:ReleaseFromImpound', {
                    plate = data.plate,
                    coords = spawnPoint.coords,
                    heading = spawnPoint.heading,
                    properties = data.vehicle and json.decode(data.vehicle) or nil
                })

                -- Abrir la puerta del depósito
                ControlImpoundGate(true)
                
                -- Notificar al jugador
                ShowNotification('Has pagado $' .. data.fee .. ' con ' .. (data.paymentType == 'cash' and 'efectivo' or 'tarjeta') .. '. Tu vehículo está listo para recoger.', 'success')
                PlaySoundFrontend(-1, "NAV", "HUD_AMMO_SHOP_SOUNDSET", 1)

                -- Cerrar la puerta después de 30 segundos
                SetTimeout(30000, function()
                    ControlImpoundGate(false)
                end)
            else
                ShowNotification('No hay espacio disponible para liberar tu vehículo. Inténtalo de nuevo en unos momentos.', 'error')
            end
        else
            ShowNotification('Error al procesar el pago.', 'error')
        end
    end, data.fee, data.paymentType)
end)