fx_version 'cerulean'
game 'gta5'

name 'MCX Spawnmanager'
description 'Custom spawn & respawn manager for MCX Framework'
author 'MCX / JustPixelsStudio'
version '0.2.0'

client_scripts {
    'client/mcx_spawn_cl.lua'
}

server_scripts {
    'server/mcx_spawn_sv.lua'
}

dependencies {
    'mcx_core'
}
