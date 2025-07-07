local Translations = {
    error = {
        not_your_vehicle = 'This is not your vehicle',
        no_parking_zone = 'You cannot park in this area',
        max_vehicles_reached = 'You have reached your maximum number of parked vehicles',
        vehicle_not_found = 'Vehicle not found',
        already_parked = 'This vehicle is already parked here',
        no_nearby_vehicles = 'No nearby vehicles found',
        no_faction_permission = 'You do not have permission to use this faction vehicle',
        faction_vehicle_in_use = 'This faction vehicle is already in use',
    },
    success = {
        vehicle_parked = 'Vehicle parked successfully',
        vehicle_retrieved = 'Vehicle retrieved successfully',
        position_saved = 'Vehicle position saved',
        faction_vehicle_locked = 'Faction vehicle locked',
        faction_vehicle_unlocked = 'Faction vehicle unlocked',
    },
    info = {
        checking_vehicles = 'Checking nearby vehicles...',
        vehicle_located = 'Vehicle located at marked position',
        approaching_limit = 'Warning: Approaching parking limit',
        faction_vehicles_loading = 'Loading faction vehicles...',
        no_faction_vehicles = 'No faction vehicles available for your job',
    },
    menu = {
        parking_menu = 'Parking Menu',
        park_vehicle = 'Park Vehicle',
        retrieve_vehicle = 'Retrieve Vehicle',
        vehicle_list = 'Parked Vehicles',
        faction_vehicles = 'Faction Vehicles',
        view_faction_vehicles = 'View Faction Vehicles',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})