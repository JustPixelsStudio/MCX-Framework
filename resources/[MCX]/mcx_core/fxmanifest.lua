fx_version 'cerulean'
game 'gta5'

name 'mcx_core'
description 'Midnight City Core Framework (MCX) with account + character support'
author 'MCX Framework'
version '2.1.0'

lua54 'yes'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db_sv.lua',
    'server/players_sv.lua',
    'server/core_sv.lua'
}

client_scripts {
    'client/core_cl.lua'
}
