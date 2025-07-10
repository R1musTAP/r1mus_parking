
fx_version 'cerulean'
game 'gta5'

author 'R1musTAP'
description 'Universal Persistent Parking & Key System for QBCore, Qbox, ESX (auto-detect)'
version '2.0.0'



shared_scripts {
    'config.lua',
    'locales/en.lua',
    'locales/es.lua'
}


escrow_ignore {
    'config.lua'
}



client_scripts {
    'client/main.lua',
    'client/faction_streaming.lua',
    'client/boat_handler.lua'
}


server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}






lua54 'yes'