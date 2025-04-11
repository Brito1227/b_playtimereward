fx_version 'cerulean'
game 'gta5'

author 'Brito'
description 'Sistema de recompensa semanal para TOP 3 jogadores com suporte QBCore/ESX'
version '1.0.0'

-- Dependências obrigatórias
dependencies {
    'oxmysql',
    'ox_lib'
}

lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'server.lua'
}
