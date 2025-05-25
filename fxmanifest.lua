fx_version 'cerulean'
game 'gta5'

description 'Organizations Script'
author 'coii'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/shop.lua',
    'server/interactions.lua',
    'sv_config.lua'
}

client_scripts {
    'client/main.lua',
    'client/shop.lua',
    'client/interactions.lua'
}

lua54 'yes'