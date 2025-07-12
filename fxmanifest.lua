fx_version 'cerulean'
game 'gta5'

author 'R1musTAP'
description 'Realistic Parking System for QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua', -- Añadir más idiomas según sea necesario
    'config.lua'
}

escrow_ignore {
	'config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/main.lua',
    'client/faction_streaming.lua',
    'client/boat_handler.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'oxmysql',
    'PolyZone',
}

lua54 'yes'