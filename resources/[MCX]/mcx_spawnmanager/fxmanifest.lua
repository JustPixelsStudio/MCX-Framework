fx_version 'cerulean'
game 'gta5'

name 'MCX Spawn Manager'
description 'Spawn selector UI + logic for MCX Framework'
author 'MCX / JustPixelsStudio'
version '1.1.0'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css'
}

client_scripts {
    'client/mcx_spawnmanager_cl.lua'
}
