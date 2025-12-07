fx_version 'cerulean'
game 'gta5'

name 'MCX Death System'
description 'Downed/bleedout + revive + hospital respawn for MCX framework'
author 'MCX / ChatGPT'
version '2.0.0'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css'
}

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/mcx_death_cl.lua'
}

server_scripts {
    'server/mcx_death_sv.lua'
}
