fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Brito'
description 'Weekly reward system for TOP 3 players with QBCore/ESX support'
version '1.0.0'

dependencies {
    'oxmysql',
    'ox_lib'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'server.lua'
}
