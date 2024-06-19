
fx_version 'adamant'
game 'gta5'
lua54 'yes'
version '1.0'
description 'garages'
author 'Sixxen'

client_scripts{
    'client/*.lua',
}

server_scripts{
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}


shared_scripts {'@es_extended/imports.lua', 'config.lua', '@ox_lib/init.lua'}