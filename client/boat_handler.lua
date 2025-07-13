-- Sistema de Detección y Manejo de Botes
local QBCore = exports['qb-core']:GetCoreObject()

-- Función para mostrar texto 3D
local function DrawText3D(x, y, z, text)
    -- Establecer el texto
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    
    -- Obtener coordenadas en pantalla
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Event handler para guardar botes
RegisterNetEvent('r1mus_parking:client:SaveBoat', function()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        ShowNotification(Lang:t('error.not_in_vehicle'), 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if not IsVehicleABoat(vehicle) then
        ShowNotification(Lang:t('error.not_a_boat'), 'error')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then
        ShowNotification(Lang:t('error.invalid_plate'), 'error')
        return
    end
    plate = string.gsub(plate, "%s+", "")

    local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)

    TriggerServerEvent('r1mus_parking:server:SaveBoat', plate, vehicleProps, coords, heading)
end)

-- Lista de modelos de botes (puedes expandir esta lista)
local boatModels = {
    [`dinghy`] = true,
    [`dinghy2`] = true,
    [`dinghy3`] = true,
    [`dinghy4`] = true,
    [`jetmax`] = true,
    [`marquis`] = true,
    [`seashark`] = true,
    [`seashark2`] = true,
    [`seashark3`] = true,
    [`speeder`] = true,
    [`speeder2`] = true,
    [`squalo`] = true,
    [`submersible`] = true,
    [`submersible2`] = true,
    [`suntrap`] = true,
    [`toro`] = true,
    [`toro2`] = true,
    [`tropic`] = true,
    [`tropic2`] = true,
    [`tug`] = true,
}

-- Función para verificar si un vehículo es un bote
function IsVehicleABoat(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    local model = GetEntityModel(vehicle)
    if boatModels[model] then
        return true
    end
    
    -- También verificar por clase de vehículo
    local vehicleClass = GetVehicleClass(vehicle)
    return vehicleClass == 14 -- 14 = Boats
end

-- Función para verificar si está en agua profunda
function IsEntityInDeepWater(entity)
    local coords = GetEntityCoords(entity)
    local _, waterHeight = GetWaterHeight(coords.x, coords.y, coords.z)
    if not waterHeight then return false end
    
    -- Verificar profundidad
    local depth = waterHeight - GetEntityHeightAboveGround(entity)
    return depth >= Config.BoatParking.minWaterDepth
end

-- Función para verificar si se puede estacionar el bote
function CanParkBoat(vehicle)
    if not Config.BoatParking.requireDock then
        -- Si no se requiere muelle, solo verificar que esté en agua profunda
        return IsEntityInDeepWater(vehicle)
    else
        -- Si se requiere muelle, verificar ambas condiciones
        local coords = GetEntityCoords(vehicle)
        local nearDock = false
        
        for _, dock in pairs(Config.BoatParking.docks) do
            if #(coords - dock.coords) < (dock.radius or 50.0) then
                nearDock = true
                break
            end
        end
        
        return nearDock and IsEntityInDeepWater(vehicle)
    end
end

-- Función para obtener el muelle más cercano (solo para blips)
function GetNearestDock(coords)
    local nearestDock = nil
    local nearestDistance = 999999.0
    
    for _, dock in ipairs(Config.BoatParking.docks) do
        local distance = #(coords - dock.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestDock = dock
        end
    end
    
    return nearestDock, nearestDistance
end

-- Thread para detectar cuando se guarda un bote
CreateThread(function()
    if not Config.BoatParking.enabled then return end
    
    while true do
        Wait(Config.BoatParking.checkInterval or 5000)
        
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if IsVehicleABoat(vehicle) then
                -- Solo verificamos si está en el agua
                local coords = GetEntityCoords(vehicle)
                local inWater = IsEntityInWater(vehicle)
                
                if inWater then
                    -- Si está en el agua, no permitimos estacionarlo
                    ShowNotification(Lang:t('error.cant_park_in_water'), 'error')
                end
            end
        end
    end
end)

-- Thread principal para el manejo de barcos
CreateThread(function()
    if not Config.BoatParking.enabled then return end
    
    while true do
        Wait(1000)
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if IsVehicleABoat(vehicle) then
                -- Verificar si está en el agua
                if IsEntityInWater(vehicle) then
                    ShowNotification(Lang:t('info.cant_park_in_water'), 'info')
                    Wait(3000) -- Esperar 3 segundos antes de mostrar otra notificación
                end
            end
        end
    end
end)

-- Exportar funciones para uso en main.lua
exports('IsVehicleABoat', IsVehicleABoat)
exports('IsEntityInWater', IsEntityInWater)
exports('GetNearestDock', GetNearestDock)
exports('IsNearDock', IsNearDock)