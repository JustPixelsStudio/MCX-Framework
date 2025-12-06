fx_version 'cerulean'
game 'gta5'

name 'mcx_charcreator'
description 'Temporary character creator and spawn selector UI for MCX'
author 'MCX Framework'
version '1.1.0'

lua54 'yes'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

client_scripts {
    'client/cl_charcreator.lua'
}
