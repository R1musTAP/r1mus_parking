
-- Cargar idioma dinámicamente desde locales/en.lua o locales/es.lua
local function LoadLocale()
    local locale = Config and Config.Locale or 'en'
    local file = 'locales/' .. locale .. '.lua'
    local chunk = LoadResourceFile(GetCurrentResourceName(), file)
    if chunk then
        local loaded = load(chunk, file)
        if loaded then
            return loaded()
        end
    end
    print('^1[ERROR] No se pudo cargar el archivo de idioma: '..file..'^0')
    return {}
end

local LangPhrases = LoadLocale()
local function Lang(key)
    local parts = {}
    for part in string.gmatch(key, "[^.]+") do table.insert(parts, part) end
    local phrase = LangPhrases
    for _, p in ipairs(parts) do
        if phrase and phrase[p] then phrase = phrase[p] else phrase = nil break end
    end
    return phrase or key
end

local function GetCore()
    if Config and Config.Framework == 'qbcore' then
        return exports['qb-core']:GetCoreObject()
    elseif Config and Config.Framework == 'qbox' then
        return exports['qbx_core']:GetCoreObject() or exports['qbx_core']:GetSharedObject() or exports['qbx_core']:getSharedObject() or exports['qbx_core']:GetCore() or exports['qbx_core']:GetPlayerData()
    elseif Config and Config.Framework == 'esx' then
        return exports['es_extended']:getSharedObject()
    elseif not Config or Config.Framework == 'auto' then
        if GetResourceState('qb-core') == 'started' then
            return exports['qb-core']:GetCoreObject()
        elseif GetResourceState('qbx_core') == 'started' then
            return exports['qbx_core']:GetCoreObject() or exports['qbx_core']:GetSharedObject() or exports['qbx_core']:getSharedObject() or exports['qbx_core']:GetCore() or exports['qbx_core']:GetPlayerData()
        elseif GetResourceState('es_extended') == 'started' then
            return exports['es_extended']:getSharedObject()
        end
    end
    return nil
end
local QBCore = GetCore()

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


-- (Eliminadas funciones de muelle: ahora los botes pueden guardarse en cualquier parte del agua)

-- Thread para detectar cuando se guarda un bote
CreateThread(function()
    if not Config.BoatParking.enabled then return end
    while true do
        Wait(Config.BoatParking.checkInterval or 5000)
        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if IsVehicleABoat(vehicle) then
                -- Solo validar que esté en agua suficiente, sin importar ubicación
                local coords = GetEntityCoords(vehicle)
                local inWater = IsEntityInWater(vehicle)
                local minDepth = Config.BoatParking.minWaterDepth or 1.5
                local waterFound, waterHeight = GetWaterHeight(coords.x, coords.y, coords.z)
                local depth = waterFound and (waterHeight - coords.z) or 0.0
                if not inWater or depth < minDepth then
                    Notify(Lang('error.boat_not_in_water'), 'error', 5000)
                end
            end
        end
    end
end)


-- (Eliminado: ya no se crean blips de muelles, los botes pueden guardarse en cualquier parte del agua)

exports('IsVehicleABoat', IsVehicleABoat)
exports('IsEntityInWater', IsEntityInWater)