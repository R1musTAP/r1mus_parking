local QBCore = exports['qb-core']:GetCoreObject()
local ParkedVehicles = {}
local SpawnedVehicles = {}
local FactionVehicles = {} -- Track de vehículos de facción spawneados


-- Función para verificar si un vehículo existe
local function CheckVehicleExists(plate, citizenid)
    if not plate or not citizenid then return false end
    
    local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?', {
        plate,
        citizenid
    })
    
    return result ~= nil
end

-- Función para verificar si un vehículo ya está spawneado
local function IsVehicleSpawned(plate)
    return SpawnedVehicles[plate] ~= nil
end

-- Función para marcar un vehículo como spawneado
local function MarkVehicleAsSpawned(plate, source)
    SpawnedVehicles[plate] = {
        source = source,
        time = os.time()
    }
end

-- Función para desmarcar un vehículo spawneado
local function UnmarkVehicleAsSpawned(plate)
    if SpawnedVehicles[plate] then
        SpawnedVehicles[plate] = nil
    end
end

-- Función para limpiar vehículos spawneados
local function CleanupSpawnedVehicles()
    SpawnedVehicles = {}
end

-- Función para verificar propiedad del vehículo
local function CheckVehicleOwnership(citizenid, plate)
    local result = MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?', {plate, citizenid})
    return result ~= nil
end

-- Función para actualizar datos del vehículo
local function UpdateVehicleData(plate, data, citizenid)
    if not data.coords then return end

    -- Determinar tipo de vehículo
    local vehicleType = data.vehicleType or 'car'
    
    -- Verificar si existe
    local exists = MySQL.scalar.await('SELECT 1 FROM r1mus_parked_vehicles WHERE plate = ?', {plate})
    
    if exists then
        MySQL.update('UPDATE r1mus_parked_vehicles SET coords = ?, heading = ?, body_health = ?, engine_health = ?, fuel_level = ?, dirt_level = ?, mods = ?, last_parked = ?, vehicle_type = ? WHERE plate = ?',
        {
            json.encode(data.coords),
            data.heading,
            data.properties.bodyHealth or 1000.0,
            data.properties.engineHealth or 1000.0,
            data.properties.fuelLevel or 100.0,
            data.properties.dirtLevel or 0.0,
            json.encode(data.properties or {}),
            os.time(),
            vehicleType,
            plate
        })
    else
        MySQL.insert('INSERT INTO r1mus_parked_vehicles (plate, citizenid, coords, heading, model, body_health, engine_health, fuel_level, dirt_level, mods, last_parked, vehicle_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            plate,
            citizenid,
            json.encode(data.coords),
            data.heading,
            data.properties.model or data.model,
            data.properties.bodyHealth or 1000.0,
            data.properties.engineHealth or 1000.0,
            data.properties.fuelLevel or 100.0,
            data.properties.dirtLevel or 0.0,
            json.encode(data.properties or {}),
            os.time(),
            vehicleType
        })
    end
end

-- Función para generar matrícula única para vehículos de facción
local function GenerateFactionPlate(job, index)
    local prefix = string.upper(string.sub(job, 1, 3))
    return prefix .. string.format("%05d", index)
end

-- Función para inicializar vehículos de facción
local function InitializeFactionVehicles()
    if not Config.FactionVehicles.enabled then
        print("^1Sistema de vehículos de facción deshabilitado")
        return
    end
    
    print("^2Inicializando vehículos de facción...")
    
    -- NO borrar registros existentes, solo actualizar o insertar nuevos
    local totalVehicles = 0
    local updatedVehicles = 0
    local newVehicles = 0
    local errorCount = 0
    
    for job, factionData in pairs(Config.FactionVehicles.factions) do
        print("^3Procesando facción: " .. job)
        for index, vehicle in ipairs(factionData.vehicles) do
            local plate = GenerateFactionPlate(job, index)
            
            -- Usar pcall para capturar errores
            local success, result = pcall(function()
                -- Verificar si ya existe
                local exists = MySQL.scalar.await('SELECT 1 FROM r1mus_faction_vehicles WHERE plate = ?', {plate})
                
                if exists then
                    -- Actualizar posición original si cambió en la config
                    MySQL.update.await('UPDATE r1mus_faction_vehicles SET original_coords = ?, original_heading = ?, model = ?, label = ?, livery = ?, extras = ? WHERE plate = ?',
                    {
                        json.encode(vehicle.coords),
                        vehicle.heading,
                        vehicle.model,
                        vehicle.label or "Vehículo de Facción",
                        vehicle.livery or 0,
                        json.encode(vehicle.extras or {}),
                        plate
                    })
                    updatedVehicles = updatedVehicles + 1
                    print("^3Vehículo de facción actualizado: " .. plate)
                else
                    -- Insertar nuevo con verificación adicional
                    MySQL.insert.await('INSERT IGNORE INTO r1mus_faction_vehicles (plate, job, model, coords, heading, original_coords, original_heading, label, livery, extras) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    {
                        plate,
                        job,
                        vehicle.model,
                        json.encode(vehicle.coords),
                        vehicle.heading,
                        json.encode(vehicle.coords),
                        vehicle.heading,
                        vehicle.label or "Vehículo de Facción",
                        vehicle.livery or 0,
                        json.encode(vehicle.extras or {})
                    })
                    
                    -- Verificar si realmente se insertó
                    local wasInserted = MySQL.scalar.await('SELECT 1 FROM r1mus_faction_vehicles WHERE plate = ?', {plate})
                    if wasInserted then
                        newVehicles = newVehicles + 1
                        print("^2Nuevo vehículo de facción registrado: " .. plate .. " - " .. job .. " - " .. vehicle.label)
                    else
                        print("^3Vehículo ya existía: " .. plate)
                        updatedVehicles = updatedVehicles + 1
                    end
                end
            end)
            
            if not success then
                errorCount = errorCount + 1
                print("^1Error procesando vehículo " .. plate .. ": " .. tostring(result))
            end
            
            totalVehicles = totalVehicles + 1
        end
    end
    
    print("^2Total de vehículos de facción: " .. totalVehicles)
    print("^2Nuevos: " .. newVehicles .. " | Actualizados: " .. updatedVehicles .. " | Errores: " .. errorCount)
end

-- Función para restaurar vehículos de facción a su posición original
local function RestoreFactionVehiclesToOriginal()
    if not Config.FactionVehicles.respawnOnRestart then return end
    
    MySQL.query('UPDATE r1mus_faction_vehicles SET coords = original_coords, heading = original_heading, in_use = false')
    print("^2Vehículos de facción restaurados a posiciones originales")
end

-- Función para verificar si un jugador puede usar vehículos de facción
local function CanUseFactionVehicle(Player, job)
    if not Config.FactionVehicles.lockToFaction then return true end
    
    -- Verificar si tiene el trabajo correcto
    if Player.PlayerData.job.name ~= job then
        return false
    end
    
    -- Si se requiere estar on duty, verificar eso también
    if Config.FactionVehicles.requireOnDuty then
        return Player.PlayerData.job.onduty
    end
    
    return true
end

-- Callbacks
QBCore.Functions.CreateCallback('r1mus_parking:server:CheckVehicleOwner', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end
    
    cb(CheckVehicleOwnership(Player.PlayerData.citizenid, plate))
end)

QBCore.Functions.CreateCallback('r1mus_parking:server:GetNearbyVehicles', function(source, cb, coords)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end

    local vehicles = MySQL.query.await('SELECT * FROM r1mus_parked_vehicles WHERE citizenid = ?', 
    {Player.PlayerData.citizenid})
    
    local nearbyVehicles = {}
    for _, vehicle in ipairs(vehicles or {}) do
        local vehicleCoords = json.decode(vehicle.coords)
        if vehicleCoords then
            local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z))
            if distance <= 100.0 then
                nearbyVehicles[#nearbyVehicles + 1] = vehicle
            end
        end
    end

    cb(nearbyVehicles)
end)

QBCore.Functions.CreateCallback('r1mus_parking:server:GetLastVehicleLocation', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end

    local result = MySQL.single.await('SELECT coords, heading FROM r1mus_parked_vehicles WHERE plate = ? AND citizenid = ?', 
{
    plate,
    Player.PlayerData.citizenid
})

    if result then
        result.coords = json.decode(result.coords)
        cb(result)
    else
        cb(false)
    end
end)

-- Callback para obtener vehículos de facción disponibles
QBCore.Functions.CreateCallback('r1mus_parking:server:GetFactionVehicles', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb({}) end
    
    local job = Player.PlayerData.job.name
    local vehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles WHERE job = ?', {job})
    
    cb(vehicles or {})
end)

-- Callback para verificar si puede usar vehículo de facción
QBCore.Functions.CreateCallback('r1mus_parking:server:CanUseFactionVehicle', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end
    
    local vehicle = MySQL.single.await('SELECT job FROM r1mus_faction_vehicles WHERE plate = ?', {plate})
    if vehicle then
        cb(CanUseFactionVehicle(Player, vehicle.job))
    else
        cb(false)
    end
end)

-- Eventos
RegisterNetEvent('r1mus_parking:server:UpdateVehiclePosition', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not data or not data.plate then return end

    -- Verificar propiedad
    if not CheckVehicleOwnership(Player.PlayerData.citizenid, data.plate) then return end

    -- Actualizar datos
    UpdateVehicleData(data.plate, data, Player.PlayerData.citizenid)
end)

-- Se ha eliminado el evento 'r1mus_parking:server:SaveFactionVehicle'

RegisterNetEvent('r1mus_parking:server:RequestAllVehicles', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print("^1No se encontró jugador")
        return
    end

    print("^2Buscando vehículos para citizenid: " .. Player.PlayerData.citizenid)

    local vehicles = MySQL.query.await([[
    SELECT
        pv.vehicle,
        pv.plate,
        epv.coords,
        epv.heading,
        epv.mods,
        epv.body_health,
        epv.engine_health,
        epv.fuel_level,
        epv.dirt_level,
        epv.impounded
    FROM
        player_vehicles pv
    LEFT JOIN
        r1mus_parked_vehicles epv ON pv.plate = epv.plate
    WHERE
        pv.citizenid = ? AND (epv.impounded IS NULL OR epv.impounded = false)
]], {Player.PlayerData.citizenid})

    print("^2Vehículos encontrados: " .. (vehicles and #vehicles or 0))

    if vehicles and #vehicles > 0 then
        for i, vehicle in ipairs(vehicles) do
            print("^3Procesando vehículo: " .. vehicle.plate)
            local coords = json.decode(vehicle.coords or '{"x":-30.69,"y":-1089.55,"z":26.42}')
            print("^3Coordenadas: x=" .. coords.x .. ", y=" .. coords.y .. ", z=" .. coords.z)
            
            if not IsVehicleSpawned(vehicle.plate) then
                print("^2Enviando vehículo al cliente: " .. vehicle.plate)
                MarkVehicleAsSpawned(vehicle.plate, src)
                TriggerClientEvent('r1mus_parking:client:RestoreVehicle', src, {
                    model = vehicle.vehicle,
                    plate = vehicle.plate,
                    coords = coords,
                    heading = vehicle.heading or 0.0,
                    properties = json.decode(vehicle.mods or '{}'),
                    bodyHealth = vehicle.body_health or 1000.0,
                    engineHealth = vehicle.engine_health or 1000.0,
                    fuelLevel = vehicle.fuel_level or 100.0,
                    dirtLevel = vehicle.dirt_level or 0.0,
                })
                Wait(Config.Optimization.spawnDelay or 1000)
            else
                print("^1Vehículo ya spawneado: " .. vehicle.plate)
            end
            
            -- Limitar vehículos por jugador
            local vehicleCount = 0
            for _ in pairs(vehicles) do
                vehicleCount = vehicleCount + 1
            end
            
            if vehicleCount >= (Config.Optimization.maxVehiclesPerPlayer or 10) then
                print("^3Límite de vehículos alcanzado para el jugador")
                break
            end
        end
    else
        print("^1No se encontraron vehículos para el jugador")
    end
end)

-- Evento para solicitar vehículos de facción
RegisterNetEvent('r1mus_parking:server:RequestFactionVehicles', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local job = Player.PlayerData.job.name
    
    -- Verificar si el trabajo tiene vehículos configurados
    if not Config.FactionVehicles.factions[job] then return end
    
    print("^2Buscando vehículos de facción para: " .. job)
    
    local vehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles WHERE job = ?', {job})
    
    if vehicles and #vehicles > 0 then
        for _, vehicle in ipairs(vehicles) do
            if not FactionVehicles[vehicle.plate] then
                print("^2Enviando vehículo de facción al cliente: " .. vehicle.plate)
                FactionVehicles[vehicle.plate] = src
                
                local coords = json.decode(vehicle.coords)
                local extras = json.decode(vehicle.extras or '[]')
                
                TriggerClientEvent('r1mus_parking:client:RestoreFactionVehicle', src, {
                    model = vehicle.model,
                    plate = vehicle.plate,
                    coords = coords,
                    heading = vehicle.heading,
                    job = vehicle.job,
                    label = vehicle.label,
                    livery = vehicle.livery,
                    extras = extras,
                    bodyHealth = vehicle.body_health,
                    engineHealth = vehicle.engine_health,
                    fuelLevel = vehicle.fuel_level,
                    dirtLevel = vehicle.dirt_level,
                    mods = json.decode(vehicle.mods or '{}')
                })
                Wait(Config.Optimization.spawnDelay or 500)
            end
        end
    end
end)

-- Evento para actualizar posición de vehículo de facción
RegisterNetEvent('r1mus_parking:server:UpdateFactionVehiclePosition', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not data or not data.plate then return end
    
    -- Verificar que es un vehículo de facción
    local vehicle = MySQL.single.await('SELECT job FROM r1mus_faction_vehicles WHERE plate = ?', {data.plate})
    if not vehicle then return end
    
    -- Verificar permisos
    if not CanUseFactionVehicle(Player, vehicle.job) then return end
    
    -- Actualizar posición
    MySQL.update('UPDATE r1mus_faction_vehicles SET coords = ?, heading = ?, body_health = ?, engine_health = ?, fuel_level = ?, dirt_level = ?, mods = ?, in_use = ?, last_used = ? WHERE plate = ?',
    {
        json.encode(data.coords),
        data.heading,
        data.properties.bodyHealth or 1000.0,
        data.properties.engineHealth or 1000.0,
        data.properties.fuelLevel or 100.0,
        data.properties.dirtLevel or 0.0,
        json.encode(data.properties or {}),
        true,
        os.time(),
        data.plate
    })
end)

-- Evento para solicitar datos de vehículos de facción (para debugging)
RegisterNetEvent('r1mus_parking:server:RequestFactionVehicleData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    print("^3Jugador " .. src .. " solicitó datos de vehículos de facción")
    
    if Config.FactionVehicles.enabled and Config.Optimization.streamingEnabled then
        local allFactionVehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles')
        if allFactionVehicles and #allFactionVehicles > 0 then
            local vehicleDataForStreaming = {}
            for _, vehicle in ipairs(allFactionVehicles) do
                local coords = json.decode(vehicle.coords)
                local extras = json.decode(vehicle.extras or '[]')
                
                table.insert(vehicleDataForStreaming, {
                    model = vehicle.model,
                    plate = vehicle.plate,
                    coords = coords,
                    heading = vehicle.heading,
                    job = vehicle.job,
                    label = vehicle.label,
                    livery = vehicle.livery,
                    extras = extras,
                    bodyHealth = vehicle.body_health or 1000.0,
                    engineHealth = vehicle.engine_health or 1000.0,
                    fuelLevel = vehicle.fuel_level or 100.0,
                    dirtLevel = vehicle.dirt_level or 0.0
                })
            end
            TriggerClientEvent('r1mus_parking:client:ReceiveFactionVehicleData', src, vehicleDataForStreaming)
            print("^2Enviados " .. #vehicleDataForStreaming .. " vehículos de facción al jugador " .. src)
        else
            print("^1No hay vehículos de facción en la base de datos")
        end
    else
        print("^1Sistema de vehículos de facción o streaming deshabilitado")
    end
end)

RegisterNetEvent('r1mus_parking:server:VehicleRemoved', function(plate)
    UnmarkVehicleAsSpawned(plate)
    
    -- También verificar si es vehículo de facción
    if FactionVehicles[plate] then
        FactionVehicles[plate] = nil
        MySQL.update('UPDATE r1mus_faction_vehicles SET in_use = false WHERE plate = ?', {plate})
    end
end)

RegisterNetEvent('r1mus_parking:server:TrackVehicle', function(plate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if CheckVehicleOwnership(Player.PlayerData.citizenid, plate) then
        local vehicleData = MySQL.single.await('SELECT coords, heading FROM r1mus_parked_vehicles WHERE plate = ?', {plate})
        if vehicleData then
            local coords = json.decode(vehicleData.coords)
            TriggerClientEvent('r1mus_parking:client:SetVehicleRoute', src, coords)
        end
    end
end)

-- Eventos del framework
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Cargar vehículos del jugador con delay
    CreateThread(function()
        Wait(2000) -- Esperar 2 segundos antes de empezar a cargar vehículos
        
        -- Enviar datos de vehículos de facción para streaming
        if Config.FactionVehicles.enabled then
            local allFactionVehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles')
            if allFactionVehicles and #allFactionVehicles > 0 then
                local vehicleDataForStreaming = {}
                for _, vehicle in ipairs(allFactionVehicles) do
                    local coords = json.decode(vehicle.coords)
                    local extras = json.decode(vehicle.extras or '[]')
                    
                    table.insert(vehicleDataForStreaming, {
                        model = vehicle.model,
                        plate = vehicle.plate,
                        coords = coords,
                        heading = vehicle.heading,
                        job = vehicle.job,
                        label = vehicle.label,
                        livery = vehicle.livery,
                        extras = extras,
                        bodyHealth = vehicle.body_health or 1000.0,
                        engineHealth = vehicle.engine_health or 1000.0,
                        fuelLevel = vehicle.fuel_level or 100.0,
                        dirtLevel = vehicle.dirt_level or 0.0
                    })
                end
                TriggerClientEvent('r1mus_parking:client:ReceiveFactionVehicleData', src, vehicleDataForStreaming)
            end
        end
        
        -- Cargar vehículos personales
        local vehicles = MySQL.query.await('SELECT * FROM r1mus_parked_vehicles WHERE citizenid = ?',
            {Player.PlayerData.citizenid})

        if vehicles then
            for _, vehicleData in ipairs(vehicles) do
                Wait(1000) -- Esperar 1 segundo entre cada vehículo
                if not IsVehicleSpawned(vehicleData.plate) then
                    local coords = json.decode(vehicleData.coords)
                    if coords then
                        MarkVehicleAsSpawned(vehicleData.plate, src)
                        TriggerClientEvent('r1mus_parking:client:RestoreVehicle', src, {
                            model = vehicleData.model,
                            plate = vehicleData.plate,
                            coords = coords,
                            heading = vehicleData.heading,
                            properties = json.decode(vehicleData.mods or '{}'),
                            bodyHealth = vehicleData.body_health,
                            engineHealth = vehicleData.engine_health,
                            fuelLevel = vehicleData.fuel_level,
                            dirtLevel = vehicleData.dirt_level,
                        })
                    end
                end
            end
        end
    end)
end)

-- Cleanup al desconectar
AddEventHandler('playerDropped', function()
    local src = source
    -- Limpiar vehículos spawneados por este jugador
    for plate, data in pairs(SpawnedVehicles) do
        if data.source == src then
            UnmarkVehicleAsSpawned(plate)
        end
    end
end)

-- Eventos de recursos
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        -- Inicializar vehículos de facción
        InitializeFactionVehicles()
        RestoreFactionVehiclesToOriginal()
        CleanupSpawnedVehicles()
        
        -- Sistema de streaming para vehículos de facción
        if Config.FactionVehicles.enabled then
            CreateThread(function()
                Wait(5000) -- Esperar 5 segundos para asegurar que MySQL esté listo
                print("^2=== PREPARANDO SISTEMA DE STREAMING DE VEHÍCULOS DE FACCIÓN ===")
                
                -- Obtener todos los vehículos de facción de la base de datos
                local allFactionVehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles')
                
                if allFactionVehicles and #allFactionVehicles > 0 then
                    print("^2Vehículos de facción encontrados: " .. #allFactionVehicles)
                    
                    -- Preparar datos para streaming
                    local vehicleDataForStreaming = {}
                    for _, vehicle in ipairs(allFactionVehicles) do
                        local coords = json.decode(vehicle.coords)
                        local extras = json.decode(vehicle.extras or '[]')
                        
                        table.insert(vehicleDataForStreaming, {
                            model = vehicle.model,
                            plate = vehicle.plate,
                            coords = coords,
                            heading = vehicle.heading,
                            job = vehicle.job,
                            label = vehicle.label,
                            livery = vehicle.livery,
                            extras = extras,
                            bodyHealth = vehicle.body_health or 1000.0,
                            engineHealth = vehicle.engine_health or 1000.0,
                            fuelLevel = vehicle.fuel_level or 100.0,
                            dirtLevel = vehicle.dirt_level or 0.0
                        })
                    end
                    
                    -- Enviar datos a todos los clientes conectados
                    TriggerClientEvent('r1mus_parking:client:ReceiveFactionVehicleData', -1, vehicleDataForStreaming)
                    print("^2=== DATOS DE STREAMING ENVIADOS A TODOS LOS CLIENTES ===")
                else
                    print("^1No se encontraron vehículos de facción en la base de datos")
                end
            end)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        -- Guardar último estado de todos los vehículos
        for plate, spawnData in pairs(SpawnedVehicles) do
            local vehicleData = MySQL.single.await('SELECT * FROM r1mus_parked_vehicles WHERE plate = ?', {plate})
            if vehicleData then
                MySQL.update('UPDATE r1mus_parked_vehicles SET last_parked = ? WHERE plate = ?',
                {
                    os.time(),
                    plate
                })
            end
        end
        
        CleanupSpawnedVehicles()
        FactionVehicles = {}
        ParkedVehicles = {}
    end
end)

-- Exports
exports('IsVehicleSpawned', IsVehicleSpawned)
exports('CheckVehicleOwnership', CheckVehicleOwnership)
exports('GetParkedVehicles', function(citizenid)
    if not citizenid then return {} end
    
    local vehicles = MySQL.query.await('SELECT * FROM r1mus_parked_vehicles WHERE citizenid = ?', {citizenid})
    return vehicles or {}
end)
-- Admin Commands
QBCore.Commands.Add("locatevehicle", "Locate a vehicle by plate", {{name="plate", help="Vehicle Plate"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.group == "admin" or Player.PlayerData.group == "superadmin" then
        local plate = args[1]
        if not plate then
            TriggerClientEvent('QBCore:Notify', source, "You must specify a plate.", "error")
            return
        end

        local vehicleData = MySQL.single.await('SELECT coords FROM r1mus_parked_vehicles WHERE plate = ?', {plate})
        if vehicleData and vehicleData.coords then
            local coords = json.decode(vehicleData.coords)
            TriggerClientEvent('r1mus_parking:client:SetVehicleRoute', source, coords)
            TriggerClientEvent('QBCore:Notify', source, "Vehicle location marked on map.", "success")
        else
            TriggerClientEvent('QBCore:Notify', source, "Vehicle not found.", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, "You do not have permission to use this command.", "error")
    end
end, "admin")

-- Sistema de Incautación
QBCore.Commands.Add("impound", "Incautar un vehículo", {{name="reason", help="Razón de incautación (opcional)"}}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local job = Player.PlayerData.job.name
    local canImpound = (job == "police" and Config.Impound.policeCanImpound) or
                       (job == "mechanic" and Config.Impound.mechanicCanImpound)
    
    if canImpound then
        local reason = table.concat(args, " ") or "Sin razón especificada"
        TriggerClientEvent('r1mus_parking:client:ImpoundVehicle', source, reason)
    else
        TriggerClientEvent('QBCore:Notify', source, "No tienes permiso para incautar vehículos", "error")
    end
end)

-- Función para incautar vehículo
local function ImpoundVehicle(plate, reason, fee)
    -- Actualizar en la base de datos
    MySQL.update('UPDATE r1mus_parked_vehicles SET impounded = ?, impound_date = ?, impound_reason = ?, impound_fee = ?, coords = ?, heading = ? WHERE plate = ?',
    {
        true,
        os.time(),
        reason or "Incautado por las autoridades",
        fee or Config.Impound.fee,
        json.encode(Config.Impound.location),
        Config.Impound.heading,
        plate
    })
    
    -- Desmarcar como spawneado
    UnmarkVehicleAsSpawned(plate)
end

-- Evento para incautar vehículo
RegisterNetEvent('r1mus_parking:server:ImpoundVehicle', function(plate, reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local job = Player.PlayerData.job.name
    local canImpound = (job == "police" and Config.Impound.policeCanImpound) or
                       (job == "mechanic" and Config.Impound.mechanicCanImpound)
    
    if canImpound then
        ImpoundVehicle(plate, reason, Config.Impound.fee)
        TriggerClientEvent('QBCore:Notify', src, "Vehículo incautado y enviado al depósito", "success")
        
        -- Notificar al dueño si está conectado
        local vehicleData = MySQL.single.await('SELECT citizenid FROM r1mus_parked_vehicles WHERE plate = ?', {plate})
        if vehicleData then
            local Owner = QBCore.Functions.GetPlayerByCitizenId(vehicleData.citizenid)
            if Owner then
                TriggerClientEvent('QBCore:Notify', Owner.PlayerData.source, "Tu vehículo " .. plate .. " ha sido incautado", "error")
            end
        end
    end
end)

-- Comando para recuperar vehículo del depósito
QBCore.Commands.Add("retrieveimpound", "Recuperar vehículo del depósito", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Obtener vehículos incautados del jugador
    local impoundedVehicles = MySQL.query.await('SELECT * FROM r1mus_parked_vehicles WHERE citizenid = ? AND impounded = true',
        {Player.PlayerData.citizenid})
    
    if impoundedVehicles and #impoundedVehicles > 0 then
        -- Aquí podrías abrir un menú, por ahora solo mostramos la lista
        TriggerClientEvent('QBCore:Notify', source, "Tienes " .. #impoundedVehicles .. " vehículo(s) en el depósito", "info")
        for _, veh in ipairs(impoundedVehicles) do
            print("- " .. veh.plate .. " | Multa: $" .. veh.impound_fee .. " | Razón: " .. veh.impound_reason)
        end
    else
        TriggerClientEvent('QBCore:Notify', source, "No tienes vehículos en el depósito", "error")
    end
end)

-- Callback para pagar y recuperar vehículo
QBCore.Functions.CreateCallback('r1mus_parking:server:PayImpoundFee', function(source, cb, plate)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return cb(false) end
    
    local vehicleData = MySQL.single.await('SELECT * FROM r1mus_parked_vehicles WHERE plate = ? AND citizenid = ? AND impounded = true',
        {plate, Player.PlayerData.citizenid})
    
    if vehicleData then
        local fee = vehicleData.impound_fee or Config.Impound.fee
        
        if Player.Functions.RemoveMoney('bank', fee) or Player.Functions.RemoveMoney('cash', fee) then
            -- Quitar incautación
            MySQL.update('UPDATE r1mus_parked_vehicles SET impounded = false, impound_date = NULL, impound_reason = NULL WHERE plate = ?', {plate})
            
            cb(true)
            TriggerClientEvent('QBCore:Notify', source, "Has pagado $" .. fee .. " y recuperado tu vehículo", "success")
        else
            cb(false)
            TriggerClientEvent('QBCore:Notify', source, "No tienes suficiente dinero ($" .. fee .. ")", "error")
        end
    else
        cb(false)
    end
end)

-- Comando para reinicializar vehículos de facción
QBCore.Commands.Add("resetfactionvehicles", "Reset and reinitialize all faction vehicles", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.group == "admin" or Player.PlayerData.group == "superadmin" then
        print("^3Reinicializando sistema de vehículos de facción...")
        
        -- Limpiar tabla completamente
        MySQL.query('DELETE FROM r1mus_faction_vehicles')
        
        -- Esperar un momento
        Wait(1000)
        
        -- Reinicializar
        InitializeFactionVehicles()
        
        -- Si está habilitado el streaming, reenviar datos a todos los clientes
        if Config.FactionVehicles.enabled and Config.Optimization.streamingEnabled then
            Wait(2000)
            local allFactionVehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles')
            
            if allFactionVehicles and #allFactionVehicles > 0 then
                local vehicleDataForStreaming = {}
                for _, vehicle in ipairs(allFactionVehicles) do
                    local coords = json.decode(vehicle.coords)
                    local extras = json.decode(vehicle.extras or '[]')
                    
                    table.insert(vehicleDataForStreaming, {
                        model = vehicle.model,
                        plate = vehicle.plate,
                        coords = coords,
                        heading = vehicle.heading,
                        job = vehicle.job,
                        label = vehicle.label,
                        livery = vehicle.livery,
                        extras = extras,
                        bodyHealth = vehicle.body_health or 1000.0,
                        engineHealth = vehicle.engine_health or 1000.0,
                        fuelLevel = vehicle.fuel_level or 100.0,
                        dirtLevel = vehicle.dirt_level or 0.0
                    })
                end
                
                TriggerClientEvent('r1mus_parking:client:ReceiveFactionVehicleData', -1, vehicleDataForStreaming)
                TriggerClientEvent('QBCore:Notify', source, "Faction vehicles reset and reinitialized", "success")
            end
        end
    end
end, "admin")

-- Comando de depuración para vehículos de facción
QBCore.Commands.Add("debugfaction", "Debug faction vehicles system", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.group == "admin" or Player.PlayerData.group == "superadmin" then
        print("^2=== DEBUG FACTION VEHICLES ===")
        print("^3Config.FactionVehicles.enabled: " .. tostring(Config.FactionVehicles.enabled))
        
        -- Verificar vehículos en la base de datos
        local factionVehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles')
        print("^3Vehículos de facción en DB: " .. (factionVehicles and #factionVehicles or 0))
        
        if factionVehicles and #factionVehicles > 0 then
            for _, veh in ipairs(factionVehicles) do
                print("  - " .. veh.plate .. " (" .. veh.job .. ") - " .. veh.label)
            end
        end
        
        TriggerClientEvent('QBCore:Notify', source, "Check server console for debug info", "info")
    end
end, "admin")

-- Comando para forzar spawn de vehículos de facción
QBCore.Commands.Add("spawnfactionvehicles", "Force spawn all faction vehicles", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.group == "admin" or Player.PlayerData.group == "superadmin" then
        print("^2Forzando spawn de vehículos de facción...")
        
        local allFactionVehicles = MySQL.query.await('SELECT * FROM r1mus_faction_vehicles')
        
        if allFactionVehicles and #allFactionVehicles > 0 then
            for _, vehicle in ipairs(allFactionVehicles) do
                local coords = json.decode(vehicle.coords)
                local extras = json.decode(vehicle.extras or '[]')
                
                TriggerClientEvent('r1mus_parking:client:SpawnServerFactionVehicle', -1, {
                    model = vehicle.model,
                    plate = vehicle.plate,
                    coords = coords,
                    heading = vehicle.heading,
                    job = vehicle.job,
                    label = vehicle.label,
                    livery = vehicle.livery,
                    extras = extras,
                    bodyHealth = vehicle.body_health or 1000.0,
                    engineHealth = vehicle.engine_health or 1000.0,
                    fuelLevel = vehicle.fuel_level or 100.0,
                    dirtLevel = vehicle.dirt_level or 0.0,
                    mods = json.decode(vehicle.mods or '{}')
                })
                
                Wait(500)
            end
            
            TriggerClientEvent('QBCore:Notify', source, "Spawned " .. #allFactionVehicles .. " faction vehicles", "success")
        else
            TriggerClientEvent('QBCore:Notify', source, "No faction vehicles found in database", "error")
        end
    end
end, "admin")

QBCore.Commands.Add("getvehicle", "Teleport a vehicle to your location", {{name="plate", help="Vehicle Plate"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.group == "admin" or Player.PlayerData.group == "superadmin" then
        local plate = args[1]
        if not plate then
            TriggerClientEvent('QBCore:Notify', source, "You must specify a plate.", "error")
            return
        end

        local playerPed = GetPlayerPed(source)
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)

        MySQL.update('UPDATE r1mus_parked_vehicles SET coords = ?, heading = ? WHERE plate = ?', {
            json.encode(playerCoords),
            playerHeading,
            plate
        })

        TriggerClientEvent('QBCore:Notify', source, "Vehicle has been teleported to your location. It will spawn shortly.", "success")
        -- We need a way to force the vehicle to respawn on the client
        -- For now, we'll just notify the user.
    else
        TriggerClientEvent('QBCore:Notify', source, "You do not have permission to use this command.", "error")
    end
end, "admin")

QBCore.Commands.Add("gotovehicle", "Teleport to a vehicle's location", {{name="plate", help="Vehicle Plate"}}, true, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.group == "admin" or Player.PlayerData.group == "superadmin" then
        local plate = args[1]
        if not plate then
            TriggerClientEvent('QBCore:Notify', source, "You must specify a plate.", "error")
            return
        end

        local vehicleData = MySQL.single.await('SELECT coords FROM r1mus_parked_vehicles WHERE plate = ?', {plate})
        if vehicleData and vehicleData.coords then
            local coords = json.decode(vehicleData.coords)
            TriggerClientEvent('r1mus_parking:client:TeleportToCoords', source, coords)
        else
            TriggerClientEvent('QBCore:Notify', source, "Vehicle not found.", "error")
        end
    else
        TriggerClientEvent('QBCore:Notify', source, "You do not have permission to use this command.", "error")
    end
end, "admin")