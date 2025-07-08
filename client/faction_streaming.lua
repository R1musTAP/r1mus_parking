-- Sistema de Streaming Optimizado para Vehículos de Facción
local QBCore = exports['qb-core']:GetCoreObject()
local streamedFactionVehicles = {}
local factionVehicleData = {}
local STREAM_DISTANCE = Config and Config.Optimization and Config.Optimization.streamDistance or 150.0
local CHECK_INTERVAL = Config and Config.Optimization and Config.Optimization.streamCheckInterval or 2000

-- Recibir datos de vehículos de facción del servidor
RegisterNetEvent('r1mus_parking:client:ReceiveFactionVehicleData', function(data)
    factionVehicleData = data
    print("^2=== DATOS DE VEHÍCULOS DE FACCIÓN RECIBIDOS ===")
    print("^2Total de vehículos: " .. #data)
    for i, veh in ipairs(data) do
        print("^3Vehículo " .. i .. ": " .. veh.plate .. " - " .. veh.label .. " en X:" .. math.floor(veh.coords.x) .. " Y:" .. math.floor(veh.coords.y))
    end
    print("^2===============================================")
end)

-- Sistema de streaming optimizado
CreateThread(function()
    while true do
        Wait(CHECK_INTERVAL)
        if #factionVehicleData > 0 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            -- No obtenemos el trabajo aquí, solo para bloqueo

            for _, vehicleData in ipairs(factionVehicleData) do
                local distance = #(playerCoords - vehicleData.coords)
                local vehicleKey = vehicleData.plate

                if distance <= STREAM_DISTANCE or (Config.FactionVehicles and Config.FactionVehicles.alwaysVisible) then
                    if not streamedFactionVehicles[vehicleKey] or not DoesEntityExist(streamedFactionVehicles[vehicleKey]) then
                        CreateThread(function()
                            local hash = GetHashKey(vehicleData.model)
                            if not IsModelInCdimage(hash) then return end
                            RequestModel(hash)
                            local timeout = 0
                            while not HasModelLoaded(hash) and timeout < 50 do
                                Wait(10)
                                timeout = timeout + 1
                            end
                            if HasModelLoaded(hash) then
                                local vehicle = CreateVehicle(hash, vehicleData.coords.x, vehicleData.coords.y, vehicleData.coords.z, vehicleData.heading, false, false)
                                if DoesEntityExist(vehicle) then
                                    SetEntityAsMissionEntity(vehicle, true, true)
                                    SetVehicleNumberPlateText(vehicle, vehicleData.plate)
                                    SetVehicleOnGroundProperly(vehicle)
                                    if vehicleData.livery then SetVehicleLivery(vehicle, vehicleData.livery) end
                                    if vehicleData.extras then for _, extra in ipairs(vehicleData.extras) do SetVehicleExtra(vehicle, extra, 0) end end
                                    SetVehicleBodyHealth(vehicle, vehicleData.bodyHealth or 1000.0)
                                    SetVehicleEngineHealth(vehicle, vehicleData.engineHealth or 1000.0)
                                    SetVehicleDirtLevel(vehicle, vehicleData.dirtLevel or 0.0)
                                    SetVehicleDoorsLocked(vehicle, 2) -- Siempre bloqueado por defecto
                                    SetVehicleNeedsToBeHotwired(vehicle, false)
                                    streamedFactionVehicles[vehicleKey] = vehicle
                                    factionVehicles[vehicleData.plate] = vehicle
                                end
                                SetModelAsNoLongerNeeded(hash)
                            end
                        end)
                    end
                else
                    if streamedFactionVehicles[vehicleKey] and DoesEntityExist(streamedFactionVehicles[vehicleKey]) then
                        local vehicle = streamedFactionVehicles[vehicleKey]
                        vehicleData.bodyHealth = GetVehicleBodyHealth(vehicle)
                        vehicleData.engineHealth = GetVehicleEngineHealth(vehicle)
                        vehicleData.dirtLevel = GetVehicleDirtLevel(vehicle)
                        DeleteEntity(vehicle)
                        streamedFactionVehicles[vehicleKey] = nil
                        factionVehicles[vehicleData.plate] = nil
                    end
                end
            end
        end
    end
end)

-- Actualizar posición de vehículo de facción localmente
RegisterNetEvent('r1mus_parking:client:UpdateFactionVehiclePosition', function(plate, newCoords, newHeading)
    for _, vehicleData in ipairs(factionVehicleData) do
        if vehicleData.plate == plate then
            vehicleData.coords = newCoords
            vehicleData.heading = newHeading
            break
        end
    end
end)

-- Limpiar al desconectar
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    for _, vehicle in pairs(streamedFactionVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    streamedFactionVehicles = {}
    factionVehicleData = {}
end)

-- Comando de depuración para verificar datos de streaming
RegisterCommand('debugstreaming', function()
    print("^2=== DEBUG STREAMING DE VEHÍCULOS DE FACCIÓN ===")
    print("^3Total de datos de vehículos: " .. #factionVehicleData)
    print("^3Vehículos actualmente streameados: " .. tableLength(streamedFactionVehicles))
    print("^3Distancia de streaming: " .. STREAM_DISTANCE)
    print("^3Intervalo de verificación: " .. CHECK_INTERVAL .. "ms")
    
    if #factionVehicleData > 0 then
        print("^2--- Primeros 5 vehículos en datos ---")
        for i = 1, math.min(5, #factionVehicleData) do
            local veh = factionVehicleData[i]
            print(string.format("^3%d. %s (%s) - Job: %s - Pos: %.1f, %.1f",
                i, veh.plate, veh.label, veh.job, veh.coords.x, veh.coords.y))
        end
    else
        print("^1No hay datos de vehículos de facción!")
        print("^1Posibles causas:")
        print("^1- El streaming no está habilitado en config")
        print("^1- No se han recibido datos del servidor")
        print("^1- Error en la inicialización")
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    print("^2Tu posición actual: " .. string.format("%.1f, %.1f, %.1f", playerCoords.x, playerCoords.y, playerCoords.z))
end)

-- Función auxiliar para contar elementos en tabla
function tableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

-- Comando para forzar solicitud de datos
RegisterCommand('requestfactiondata', function()
    print("^3Solicitando datos de vehículos de facción al servidor...")
    TriggerServerEvent('r1mus_parking:server:RequestFactionVehicleData')
end)