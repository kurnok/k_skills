fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Kurnok'
description 'Global skills / XP system with exports'
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

server_scripts {
    'server/main.lua',
    'server/admin.lua',
}
