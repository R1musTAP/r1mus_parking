local Translations = {
    error = {
        not_your_vehicle = 'Este no es tu vehículo',
        no_parking_zone = 'No puedes estacionar en esta área',
        max_vehicles_reached = 'Has alcanzado el número máximo de vehículos estacionados',
        vehicle_not_found = 'Vehículo no encontrado',
        already_parked = 'Este vehículo ya está estacionado aquí',
        no_nearby_vehicles = 'No hay vehículos cercanos',
        no_faction_permission = 'No tienes permiso para usar este vehículo de facción',
        faction_vehicle_in_use = 'Este vehículo de facción ya está en uso',
        not_in_water = '⚠️ Los botes deben estar en el agua para estacionar',
        cant_park_in_water = 'No puedes estacionar el barco mientras está en el agua',
        not_enough_money = 'No tienes suficiente dinero - Necesitas: $%{amount}',
        no_impounded_vehicles = 'No tienes vehículos en el depósito',
        no_permission_impound = 'No tienes permiso para incautar vehículos',
        specify_plate = 'Debes especificar una matrícula',
        cannot_locate_vehicle = 'No se puede localizar este vehículo',
        no_locate_permission = 'No tienes permiso para localizar este vehículo',
        no_vehicle = 'No hay vehículo cerca',
        must_be_closer = 'Debes estar más cerca del vehículo para incautarlo',
        not_in_vehicle = 'No estás en un vehículo',
        not_owner = 'No eres el dueño de este vehículo',
        not_police = 'No estás autorizado',
        not_mechanic = 'No estás autorizado',
        already_impounded = 'El vehículo ya está incautado',
        impound_cancelled = 'Incautación cancelada',
        invalid_location = 'Ubicación no válida para este tipo de vehículo',
    },
    success = {
        vehicle_parked = 'Vehículo estacionado correctamente',
        vehicle_retrieved = 'Vehículo recuperado correctamente',
        position_saved = 'Posición del vehículo guardada',
        faction_vehicle_locked = 'Vehículo de facción bloqueado',
        faction_vehicle_unlocked = 'Vehículo de facción desbloqueado',
        vehicle_impounded = 'Vehículo incautado correctamente',
        vehicle_recovered = 'Vehículo recuperado - Pago realizado: $%{amount}',
        personal_vehicle_locked = 'Vehículo bloqueado',
        personal_vehicle_unlocked = 'Vehículo desbloqueado',
        vehicle_impounded = 'Vehículo incautado correctamente',
        vehicle_released = 'Vehículo liberado del depósito',
    },
    info = {
        checking_vehicles = 'Comprobando vehículos cercanos...',
        vehicle_located = 'Vehículo localizado a %{distance} metros',
        approaching_limit = 'Advertencia: Te acercas al límite de estacionamiento',
        faction_vehicles_loading = 'Cargando vehículos de facción...',
        no_faction_vehicles = 'No hay vehículos de facción disponibles para tu trabajo',
        vehicle_at_impound = 'El vehículo está en el depósito municipal',
        impound_fee = 'Tarifa del depósito: $%{amount}',
        impound_fee = 'Multa de incautación: $%s',
        impound_reason = 'Razón: %s',
        impound_by = 'Incautado por: %s',
    },
    menu = {
        parking_menu = 'Menú de Estacionamiento',
        park_vehicle = 'Estacionar Vehículo',
        retrieve_vehicle = 'Recuperar Vehículo',
        vehicle_list = 'Vehículos Estacionados',
        faction_vehicles = 'Vehículos de Facción',
        view_faction_vehicles = 'Ver Vehículos de Facción',
        access_impound = 'Acceder al Depósito',
        impound_lot = 'Depósito Municipal'
    },
    commands = {
        impound_command = 'Incautar un vehículo',
        locate_command = 'Localizar tu vehículo'
    },
    progress = {
        impounding_vehicle = 'Incautando vehículo...',
        releasing_vehicle = 'Liberando vehículo...',
        checking_vehicle = 'Revisando vehículo...',
    }
}

if GetConvar('qb_locale', 'en') == 'es' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
