fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Kurnok'
description 'Global skills / XP system with exports'
version '1.0.4'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}


ui_page 'web/index.html'

files {
  'web/index.html',
  'web/styles.css',
  'web/script.js',
}