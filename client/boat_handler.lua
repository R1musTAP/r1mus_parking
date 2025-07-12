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

-- Función para verificar si está en agua
function IsEntityInWater(entity)
    local coords = GetEntityCoords(entity)
    local _, waterHeight = GetWaterHeight(coords.x, coords.y, coords.z)
    return waterHeight ~= false and coords.z <= waterHeight + 2.0
end

-- Función para obtener el muelle más cercano
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
                    QBCore.Functions.Notify('⚠️ Los botes deben estar en el agua o cerca de un muelle', 'error', 5000)
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