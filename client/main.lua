


-- Framework universal (manual o auto)
local Framework, Core = nil, nil
function GetCore()
    if Config.Framework == 'qbcore' then
        Framework = 'qbcore'
        return exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'qbox' then
        Framework = 'qbox'
        return exports['qbx_core']:GetCoreObject() or exports['qbx_core']:GetSharedObject() or exports['qbx_core']:getSharedObject() or exports['qbx_core']:GetCore() or exports['qbx_core']:GetPlayerData() -- fallback
    elseif Config.Framework == 'esx' then
        Framework = 'esx'
        return exports['es_extended']:getSharedObject()
    elseif Config.Framework == 'auto' or not Config.Framework then
        if GetResourceState('qb-core') == 'started' then
            Framework = 'qbcore'
            return exports['qb-core']:GetCoreObject()
        elseif GetResourceState('qbx_core') == 'started' then
            Framework = 'qbox'
            return exports['qbx_core']:GetCoreObject() or exports['qbx_core']:GetSharedObject() or exports['qbx_core']:getSharedObject() or exports['qbx_core']:GetCore() or exports['qbx_core']:GetPlayerData()
        elseif GetResourceState('es_extended') == 'started' then
            Framework = 'esx'
            return exports['es_extended']:getSharedObject()
        end
    end
    return nil
end

local QBCore = GetCore() -- Para compatibilidad con el resto del código

-- =============================
-- SISTEMA UNIVERSAL DE FUEL
-- =============================
local FuelSystem = nil
local function DetectFuelSystem()
    if GetResourceState('LegacyFuel') == 'started' then
        return 'LegacyFuel'
    elseif GetResourceState('cdn-fuel') == 'started' then
        return 'cdn-fuel'
    elseif GetResourceState('ps-fuel') == 'started' then
        return 'ps-fuel'
    elseif GetResourceState('okokGasStation') == 'started' then
        return 'okokGasStation'
    elseif GetResourceState('qb-fuel') == 'started' then
        return 'qb-fuel'
    elseif GetResourceState('ox_fuel') == 'started' then
        return 'ox_fuel'
    else
        return 'native'
    end
end

FuelSystem = DetectFuelSystem()

local function GetFuel(vehicle)
    if FuelSystem == 'LegacyFuel' then
        return exports['LegacyFuel']:GetFuel(vehicle)
    elseif FuelSystem == 'cdn-fuel' then
        return exports['cdn-fuel']:GetFuel(vehicle)
    elseif FuelSystem == 'ps-fuel' then
        return exports['ps-fuel']:GetFuel(vehicle)
    elseif FuelSystem == 'okokGasStation' then
        return exports['okokGasStation']:GetFuel(vehicle)
    elseif FuelSystem == 'qb-fuel' then
        return exports['qb-fuel']:GetFuel(vehicle)
    elseif FuelSystem == 'ox_fuel' then
        return exports['ox_fuel']:getFuel(vehicle)
    else
        return GetVehicleFuelLevel(vehicle)
    end
end

local function SetFuel(vehicle, level)
    if FuelSystem == 'LegacyFuel' then
        exports['LegacyFuel']:SetFuel(vehicle, level)
    elseif FuelSystem == 'cdn-fuel' then
        exports['cdn-fuel']:SetFuel(vehicle, level)
    elseif FuelSystem == 'ps-fuel' then
        exports['ps-fuel']:SetFuel(vehicle, level)
    elseif FuelSystem == 'okokGasStation' then
        exports['okokGasStation']:SetFuel(vehicle, level)
    elseif FuelSystem == 'qb-fuel' then
        exports['qb-fuel']:SetFuel(vehicle, level)
    elseif FuelSystem == 'ox_fuel' then
        exports['ox_fuel']:setFuel(vehicle, level)
    else
        SetVehicleFuelLevel(vehicle, level)
    end
end

-- Función centralizada de notificaciones

function Notify(msg, type, time)
    type = type or 'info'
    time = time or 5000
    if Framework == 'esx' then
        TriggerEvent('esx:showNotification', msg)
        return
    end
    if Config.NotifyType == 'qb' then
        QBCore.Functions.Notify(msg, type, time)
    elseif Config.NotifyType == 'origen' then
        TriggerEvent('origen_notify:Notify', type, msg, time)
    elseif Config.NotifyType == 'okok' then
        exports['okokNotify']:Alert('Parking', msg, time, type)
    elseif Config.NotifyType == 'mythic' then
        exports['mythic_notify']:SendAlert(type, msg, time)
    elseif Config.NotifyType == 'custom' then
        print('CUSTOM NOTIFY:', msg, type)
    else
        QBCore.Functions.Notify(msg, type, time)
    end
end
local PlayerData = {}
local spawnedVehicles = {}
local lastSavedPositions = {}
local isSpawning = false
local isInitialized = false
local lastCoords = nil
local factionVehicles = {} -- Track de vehículos de facción

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
    vehicleProps.fuelLevel = GetFuel(vehicle)
    vehicleProps.bodyHealth = GetVehicleBodyHealth(vehicle) + 0.0 -- Forzar float
    vehicleProps.engineHealth = GetVehicleEngineHealth(vehicle) + 0.0
    vehicleProps.tankHealth = GetVehiclePetrolTankHealth(vehicle) + 0.0
    vehicleProps.dirtLevel = GetVehicleDirtLevel(vehicle) + 0.0
    
    -- Detectar tipo de vehículo
    local isBoat = false
    -- Refuerzo: intentar export y fallback a clase
    if exports and exports['r1mus_parking'] and exports['r1mus_parking'].IsVehicleABoat then
        isBoat = exports['r1mus_parking']:IsVehicleABoat(vehicle)
    else
        local vehicleClass = GetVehicleClass(vehicle)
        isBoat = (vehicleClass == 14)
    end
    vehicleProps.vehicleType = isBoat and 'boat' or 'car'
    if Config.Debug then print('Tipo de vehículo detectado:', vehicleProps.vehicleType) end
    
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
    if props.fuelLevel then SetFuel(vehicle, props.fuelLevel) end
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
    local timeoutCounter = 0
    while not HasModelLoaded(hash) do
        timeoutCounter = timeoutCounter + 1
        Wait(50)
        if timeoutCounter > 100 then
            print("^1Timeout al cargar modelo")
            return
        end
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
        SetFuel(vehicle, data.fuelLevel or 100.0)
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
        SetFuel(vehicle, data.fuelLevel or 100.0)
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
        local isBoat = exports['r1mus_parking']:IsVehicleABoat(vehicle)
        -- Permitir bloqueo/desbloqueo también para botes
        if IsFactionVehicle(plate) then
            QBCore.Functions.TriggerCallback('r1mus_parking:server:CanUseFactionVehicle', function(canUse)
                if canUse then
                    local lockStatus = GetVehicleDoorLockStatus(vehicle)
                    if lockStatus == 1 then
                        SetVehicleDoorsLocked(vehicle, 2)
                        if Config.VehicleLock.soundEnabled then
                            PlaySoundFromEntity(-1, Config.VehicleLock.lockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                        end
                        Notify(Lang:t('success.faction_vehicle_locked'), 'success')
                    else
                        SetVehicleDoorsLocked(vehicle, 1)
                        if Config.VehicleLock.soundEnabled then
                            PlaySoundFromEntity(-1, Config.VehicleLock.unlockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                        end
                        Notify(Lang:t('success.faction_vehicle_unlocked'), 'success')
                    end
                else
                    Notify(Lang:t('error.no_faction_permission'), 'error')
                end
            end, plate)
        elseif isBoat then
            -- Permitir bloqueo/desbloqueo de botes
            local lockStatus = GetVehicleDoorLockStatus(vehicle)
            if lockStatus == 1 then
                SetVehicleDoorsLocked(vehicle, 2)
                if Config.VehicleLock.soundEnabled then
                    PlaySoundFromEntity(-1, Config.VehicleLock.lockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                end
                Notify('Bote bloqueado', 'success')
            else
                SetVehicleDoorsLocked(vehicle, 1)
                if Config.VehicleLock.soundEnabled then
                    PlaySoundFromEntity(-1, Config.VehicleLock.unlockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                end
                Notify('Bote desbloqueado', 'success')
            end
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
                        Notify(Lang:t('success.vehicle_parked'), 'success')
                    else
                        SetVehicleDoorsLocked(vehicle, 1)
                        if Config.VehicleLock.soundEnabled then
                            PlaySoundFromEntity(-1, Config.VehicleLock.unlockSound, vehicle, "HUD_FRONTEND_DEFAULT_SOUNDSET", 1, 0)
                        end
                        Notify(Lang:t('success.vehicle_retrieved'), 'success')
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
            
            -- Verificar vehículos desaparecidos cada 5 segundos
            if currentTime - lastVehicleCheck > Config.Optimization.vehicleCheckInterval then
                lastVehicleCheck = currentTime
                
                -- Verificar vehículos personales
                for plate, vehicle in pairs(spawnedVehicles) do
                    if not DoesEntityExist(vehicle) then
                        spawnedVehicles[plate] = nil
                        permissionCache[plate .. "_personal"] = nil -- Limpiar cache
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

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    print("^2OnPlayerLoaded triggered")
    CreateThread(function()
        Wait(3000)
        print("^2Solicitando vehículos después de 3 segundos")
        PlayerData = QBCore.Functions.GetPlayerData()
        isInitialized = true
        TriggerServerEvent('r1mus_parking:server:RequestAllVehicles')
        
        -- También solicitar vehículos de facción si tiene trabajo
        if PlayerData.job and Config.FactionVehicles and Config.FactionVehicles.enabled and Config.FactionVehicles.factions and Config.FactionVehicles.factions[PlayerData.job.name] then
            TriggerServerEvent('r1mus_parking:server:RequestFactionVehicles')
        end
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
RegisterCommand('findvehicle', function(source, args)
    if not args[1] then
        Notify(Lang:t('error.no_nearby_vehicles'), 'error')

-- =============================
-- MENÚ Y PED DE RECUPERACIÓN DEPÓSITO
-- =============================
local impoundPed = nil
local impoundPedModel = `s_m_y_cop_01` -- Puedes cambiar el modelo aquí
local impoundPedCoords = Config.Impound.location
local impoundPedHeading = Config.Impound.heading or 0.0

-- Crear el PED del depósito
CreateThread(function()
    if not Config.Impound.enabled then return end
    RequestModel(impoundPedModel)
    while not HasModelLoaded(impoundPedModel) do Wait(50) end
    impoundPed = CreatePed(4, impoundPedModel, impoundPedCoords.x, impoundPedCoords.y, impoundPedCoords.z - 1.0, impoundPedHeading, false, true)
    FreezeEntityPosition(impoundPed, true)
    SetEntityInvincible(impoundPed, true)
    SetBlockingOfNonTemporaryEvents(impoundPed, true)
end)

-- Detección de cercanía e interacción
CreateThread(function()
    while true do
        Wait(500)
        if impoundPed and #(GetEntityCoords(PlayerPedId()) - impoundPedCoords) < 2.5 then
            -- Mostrar ayuda
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("Pulsa ~INPUT_CONTEXT~ para recuperar vehículos incautados")
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustReleased(0, 38) then -- E
                TriggerServerEvent('r1mus_parking:server:OpenImpoundMenu')
            end
        end
    end
end)

-- Recibir menú de vehículos incautados
RegisterNetEvent('r1mus_parking:client:ShowImpoundMenu', function(vehicles)
    if not vehicles or #vehicles == 0 then
        Notify('No tienes vehículos incautados', 'error')
        return
    end
    local elements = {}
    for _, v in ipairs(vehicles) do
        table.insert(elements, {
            header = v.plate .. ' - ' .. (v.label or v.model),
            params = { event = 'r1mus_parking:client:RecoverImpoundedVehicle', args = { plate = v.plate } }
        })
    end
    table.insert(elements, { header = 'Cerrar', params = { event = '' } })
    if Framework == 'esx' then
        -- Menú simple para ESX (puedes mejorar con esx_menu_default)
        local menu = {}
        for _, v in ipairs(vehicles) do
            table.insert(menu, {label = v.plate .. ' - ' .. (v.label or v.model), value = v.plate})
        end
        table.insert(menu, {label = 'Cerrar', value = 'close'})
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'impound_menu', {
            title = 'Vehículos Incautados',
            align = 'top-left',
            elements = menu
        }, function(data, menu)
            if data.current.value and data.current.value ~= 'close' then
                TriggerServerEvent('r1mus_parking:server:PayImpoundFee', data.current.value)
            end
            menu.close()
        end, function(data, menu)
            menu.close()
        end)
    else
        exports['qb-menu']:openMenu(elements)
    end
end)

RegisterNetEvent('r1mus_parking:client:RecoverImpoundedVehicle', function(data)
    if data and data.plate then
        TriggerServerEvent('r1mus_parking:server:PayImpoundFee', data.plate)
    end
end)
        return
    end
    QBCore.Functions.TriggerCallback('r1mus_parking:server:GetLastVehicleLocation', function(coords)
        if coords then
            SetNewWaypoint(coords.x, coords.y)
            Notify(Lang:t('info.vehicle_located'), 'success')
        else
            Notify(Lang:t('error.vehicle_not_found'), 'error')
        end
    end, args[1])
end)

-- Keybinding para bloqueo de vehículo (plug & play con config)
CreateThread(function()
    -- Intenta registrar el keymapping con la tecla definida en config
    RegisterKeyMapping('togglelock', 'Toggle Vehicle Lock', 'keyboard', Config.VehicleLock.defaultKey)
    RegisterCommand('togglelock', function()
        if Config.VehicleLock.enabled then
            HandleVehicleLock()
        end
    end)
    -- Aviso si el usuario tiene la L asignada por error
    Wait(2000)
    local key = GetControlInstructionalButton(0, string.byte(Config.VehicleLock.defaultKey:upper()), true)
    if Config.VehicleLock.defaultKey:lower() ~= 'l' then
        print('^3[Parking] Si la tecla L sigue abriendo/cerrando el vehículo, ejecuta en F8: ^0unbind keyboard l^3 y reinicia el recurso para que funcione la tecla configurada ('..Config.VehicleLock.defaultKey:upper()..')^0')
    end
end)
RegisterNetEvent('r1mus_parking:client:SetVehicleRoute', function(coords)
    SetNewWaypoint(coords.x, coords.y)
    Notify(Lang:t('info.vehicle_located'), 'success')
end)
RegisterNetEvent('r1mus_parking:client:TeleportToCoords', function(coords)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
end)

-- Evento para cuando cambia el trabajo del jugador
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    -- Limpiar vehículos de facción anteriores solo si cambió a otro trabajo con vehículos de facción
if PlayerData.job and PlayerData.job.name ~= JobInfo.name then
    -- Solo limpiar si el nuevo trabajo también tiene vehículos de facción
    local newJobHasFactionVehicles = Config.FactionVehicles and Config.FactionVehicles.enabled and 
                                    Config.FactionVehicles.factions and Config.FactionVehicles.factions[JobInfo.name]
    
    if newJobHasFactionVehicles then
        for plate, vehicle in pairs(factionVehicles) do
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            TriggerServerEvent('r1mus_parking:server:VehicleRemoved', plate)
        end
        factionVehicles = {}
    end
end
    
    -- Solicitar nuevos vehículos de facción si el nuevo trabajo los tiene
    if Config.FactionVehicles and Config.FactionVehicles.enabled and Config.FactionVehicles.factions and Config.FactionVehicles.factions[JobInfo.name] then
        Wait(1000) -- Pequeño delay para asegurar que el trabajo se actualizó en el servidor
        TriggerServerEvent('r1mus_parking:server:RequestFactionVehicles')
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
            Notify(Lang:t('info.no_faction_vehicles'), 'error')
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
            Notify(Lang:t('error.vehicle_not_found'), 'error')
        end)
    else
        Notify(Lang:t('error.no_nearby_vehicles'), 'error')
    end
end)


-- Blip y PED del depósito
if Config.Impound.enabled and Config.Impound.blip.enabled then
    CreateThread(function()
        -- Blip
        local blip = AddBlipForCoord(Config.Impound.location.x, Config.Impound.location.y, Config.Impound.location.z)
        SetBlipSprite(blip, Config.Impound.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Impound.blip.scale)
        SetBlipColour(blip, Config.Impound.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Impound.blip.label)
        EndTextCommandSetBlipName(blip)

        -- PED/NPC
        local pedModel = `s_m_m_security_01` -- Modelo de seguridad, puedes cambiarlo
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do Wait(10) end
        local ped = CreatePed(4, pedModel, Config.Impound.location.x, Config.Impound.location.y, Config.Impound.location.z - 1.0, Config.Impound.heading or 0.0, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", 0, true)

        -- Interacción con el PED
        while true do
            Wait(0)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local dist = #(playerCoords - vector3(Config.Impound.location.x, Config.Impound.location.y, Config.Impound.location.z))
            if dist < 2.0 then
                DrawText3D(Config.Impound.location.x, Config.Impound.location.y, Config.Impound.location.z + 1.0, "[E] Recuperar Vehículo")
                if IsControlJustReleased(0, 38) then -- E
                    TriggerServerEvent('r1mus_parking:server:OpenImpoundMenu')
                    Wait(1000)
                end
            else
                Wait(500)
            end
        end
    end)
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end