local Translations = {
    info = {
        park_vehicle = "Park Vehicle",
        track_vehicle = "Track Vehicle",
        store_vehicle = "Store Vehicle",
        get_vehicle = "Get Vehicle",
        impound_vehicle = "Impound Vehicle",
        vehicle_parked = "Vehicle parked",
        vehicle_stored = "Vehicle stored",
        vehicle_not_found = "Vehicle not found",
        no_vehicles = "No vehicles available",
        impound_fee = "Impound fee: $%s",
        vehicle_impounded = "Vehicle impounded",
        impound_reason = "Reason: %s",
        impound_by = "Impounded by: %s",
        vehicle_released = "Vehicle released from impound",
        insufficient_funds = "Insufficient funds",
        must_be_closer = "You must be closer to the vehicle",
        must_be_owner = "You must be the owner of the vehicle",
        must_be_police = "You must be police to do this",
        must_be_mechanic = "You must be a mechanic to do this",
        vehicle_already_impounded = "Vehicle is already impounded",
    },
    progress = {
        impounding_vehicle = "Impounding vehicle...",
        releasing_vehicle = "Releasing vehicle...",
        checking_vehicle = "Checking vehicle...",
    },
    success = {
        vehicle_parked = "Vehicle parked successfully",
        vehicle_stored = "Vehicle stored successfully",
        vehicle_impounded = "Vehicle impounded successfully",
        vehicle_released = "Vehicle released from impound",
    },
    error = {
        no_vehicle = "No vehicle found",
        not_in_vehicle = "You must be in a vehicle",
        not_owner = "You don't own this vehicle",
        not_police = "You are not authorized",
        not_mechanic = "You are not authorized",
        already_impounded = "Vehicle is already impounded",
        invalid_location = "Invalid location for this vehicle type",
        no_water = "Must be in water to park a boat",
    },
    menu = {
        parking_menu = 'Parking Menu',
        retrieve_vehicle = 'Retrieve Vehicle',
        vehicle_list = 'Parked Vehicles',
        faction_vehicles = 'Faction Vehicles',
        view_faction_vehicles = 'View Faction Vehicles',
        close = "Close",
        track = "Track Vehicle",
        impound = "Impound",
        release = "Release from Impound"
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})