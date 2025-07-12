fx_version 'cerulean'
game 'gta5'

name 'r1mus_parking'
author 'R1musTAP'
description 'Advanced Realistic Parking System for QBCore with persistent damage and faction vehicles'
version '1.1.0'

repository 'https://github.com/R1musTAP/r1mus_parking'
license 'GPL-3.0-or-later'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/*.lua',
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
    'PolyZone'
}

lua54 'yes'