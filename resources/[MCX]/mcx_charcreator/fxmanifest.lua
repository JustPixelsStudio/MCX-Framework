
fx_version 'cerulean'
game 'gta5'

name 'MCX Character Creator'
description 'Character creation UI for MCX Framework (split from spawn manager)'
author 'MCX'
version '1.2.0'

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
