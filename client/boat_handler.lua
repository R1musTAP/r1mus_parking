-- Sistema de Detección y Manejo de Botes
local QBCore = exports['qb-core']:GetCoreObject()

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

-- Función para verificar si está en un muelle
function IsNearDock(coords)
    local _, distance = GetNearestDock(coords)
    return distance <= 50.0 -- Dentro de 50 metros de cualquier muelle
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
                -- Es un bote, verificar si está en agua o cerca de un muelle
                local coords = GetEntityCoords(vehicle)
                local inWater = IsEntityInWater(vehicle)
                local nearDock = IsNearDock(coords)
                
                if not inWater and not nearDock then
                    -- Bote fuera del agua y lejos de muelles
                    ShowNotification(Lang:t('error.not_in_water'), 'error')
                end
            end
        end
    end
end)

-- Crear blips para los muelles
CreateThread(function()
    if not Config.BoatParking.enabled then return end
    
    for _, dock in ipairs(Config.BoatParking.docks) do
        local blip = AddBlipForCoord(dock.coords.x, dock.coords.y, dock.coords.z)
        SetBlipSprite(blip, dock.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, dock.blip.scale)
        SetBlipColour(blip, dock.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(dock.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Exportar funciones para uso en main.lua
exports('IsVehicleABoat', IsVehicleABoat)
exports('IsEntityInWater', IsEntityInWater)
exports('GetNearestDock', GetNearestDock)
exports('IsNearDock', IsNearDock)