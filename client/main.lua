local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local spawnedVehicles = {}
local lastSavedPositions = {}
local isSpawning = false
local isInitialized = false
local lastCoords = nil
local factionVehicles = {} -- Track de vehículos de facción

-- Función para mostrar notificaciones
local function ShowNotification(message, type)
    if not Config.NotificationSystem then return end
    
    if Config.NotificationSystem.type == 'qb' then
        QBCore.Functions.Notify(message, type)
    elseif Config.NotificationSystem.type == 'origen' then
        exports['origen_notify']:Notify(message, type)
    elseif Config.NotificationSystem.type == 'ox' then
        exports['ox_lib']:notify({
            description = message,
            type = type
        })
    elseif Config.NotificationSystem.type == 'esx' then
        ESX.ShowNotification(message)
    elseif Config.NotificationSystem.type == 'custom' and Config.NotificationSystem.customNotify then
        Config.NotificationSystem.customNotify(message, type)
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

-- Spawn del NPC del depósito
local function SpawnImpoundPed()
    if not Config.Impound.enabled or not Config.Impound.ped.enabled then return end

    local hash = GetHashKey(Config.Impound.ped.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(10)
    end

    local ped = CreatePed(4, hash, Config.Impound.ped.coords.x, Config.Impound.ped.coords.y, Config.Impound.ped.coords.z, Config.Impound.ped.heading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

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
                label = "Acceder al Depósito",
            }
        },
        distance = 2.5,
    })
end

-- Evento para abrir el menú del depósito
RegisterNetEvent('r1mus_parking:client:OpenImpoundMenu', function()
    QBCore.Functions.TriggerCallback('r1mus_parking:server:GetImpoundedVehicles', function(vehicles)
        if not vehicles or #vehicles == 0 then
            ShowNotification(Lang:t('error.no_impounded_vehicles'), 'error')
            return
        end

        local menuItems = {}
        for _, vehicle in ipairs(vehicles) do
            table.insert(menuItems, {
                header = vehicle.label .. ' - ' .. vehicle.plate,
                txt = Lang:t('info.impound_fee', {amount = Config.Impound.fee}),
                params = {
                    event = 'r1mus_parking:client:RetrieveImpoundedVehicle',
                    args = {
                        plate = vehicle.plate,
                        fee = Config.Impound.fee
                    }
                }
            })
        end

        -- Soporte para diferentes sistemas de menú
        if Config.MenuSystem == 'qb' then
            exports['qb-menu']:openMenu(menuItems)
        elseif Config.MenuSystem == 'ox' then
            exports.ox_lib:registerMenu({
                id = 'impound_menu',
                title = Lang:t('menu.impound_lot'),
                options = menuItems
            })
            exports.ox_lib:showMenu('impound_menu')
        else
            -- Puedes añadir más sistemas de menú aquí
            exports[Config.MenuSystem]:openMenu(menuItems)
        end
    end)
end)

-- Evento para recuperar vehículo del depósito
RegisterNetEvent('r1mus_parking:client:RetrieveImpoundedVehicle', function(data)
    QBCore.Functions.TriggerCallback('r1mus_parking:server:PayImpoundFee', function(success)
        if success then
            QBCore.Functions.Notify('Vehículo recuperado - Pago realizado: $' .. data.fee, 'success')
            TriggerServerEvent('r1mus_parking:server:RetrieveVehicle', data.plate)
        else
            QBCore.Functions.Notify('No tienes suficiente dinero - Necesitas: $' .. data.fee, 'error')
        end
    end, data.fee)
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
RegisterCommand('findvehicle', function(source, args)
    if not args[1] then
        QBCore.Functions.Notify('Debes especificar una matrícula', 'error')
        return
    end
    QBCore.Functions.TriggerCallback('r1mus_parking:server:GetLastVehicleLocation', function(coords)
        if coords then
            SetNewWaypoint(coords.x, coords.y)
            QBCore.Functions.Notify('Ubicación del vehículo marcada en el mapa', 'success')
        else
            QBCore.Functions.Notify('No se encontró el vehículo', 'error')
        end
    end, args[1])
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
    -- Limpiar vehículos de facción anteriores si cambió de trabajo
    if PlayerData.job and PlayerData.job.name ~= JobInfo.name then
        for plate, vehicle in pairs(factionVehicles) do
            if DoesEntityExist(vehicle) then
                DeleteEntity(vehicle)
            end
            TriggerServerEvent('r1mus_parking:server:VehicleRemoved', plate)
        end
        factionVehicles = {}
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

-- Blip del depósito
if Config.Impound.enabled and Config.Impound.blip.enabled then
    CreateThread(function()
        local blip = AddBlipForCoord(Config.Impound.location.x, Config.Impound.location.y, Config.Impound.location.z)
        SetBlipSprite(blip, Config.Impound.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Impound.blip.scale)
        SetBlipColour(blip, Config.Impound.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Impound.blip.label)
        EndTextCommandSetBlipName(blip)
    end)
end

-- Comando de impound mejorado
RegisterCommand('impound', function()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, true)
    
    if not vehicle or not DoesEntityExist(vehicle) then
        vehicle = GetClosestVehicle(GetEntityCoords(player), 5.0, 0, 71)
    end
    
    if vehicle and DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerServerEvent('r1mus_parking:server:ImpoundVehicle', plate)
    else
        ShowNotification(Lang:t('error.no_nearby_vehicles'), 'error')
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