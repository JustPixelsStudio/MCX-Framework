fx_version 'cerulean'
game 'gta5'

name 'MCX Core'
description 'Core systems for MCX Framework'
author 'MCX / JustPixelsStudio'
version '1.0.0'

lua54 'yes'


shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/core_cl.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db_sv.lua',
    'server/core_sv.lua'
}
