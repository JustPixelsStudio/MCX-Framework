fx_version 'cerulean'
game 'gta5'

name 'MCX Character Creator'
description 'Character creator + spawn menu for MCX Framework'
author 'MCX / JustPixelsStudio'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css'
}

client_scripts {
    'client/cl_charcreator.lua'
}
