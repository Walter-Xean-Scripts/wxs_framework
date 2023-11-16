fx_version 'cerulean'
games { 'gta5' }

author 'Walter & Xean'
description 'A new FiveM framework - soon compatible with ESX & QBCore scripts'
version '1.0.0'

lua54 'yes'

shared_scripts {
    "@wxs_core/main.lua",
    "configs/*.lua",
    "shared/init.lua",
}

client_scripts {
    "client/init.lua",
    "bridges/esx/client/**/*",
    "bridges/qbcore/client/**/*"
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "server/init.lua",
    "bridges/esx/server/**/*",
    "bridges/qbcore/server/**/*"
}

files {
    "client/**/*",
    "shared/**/*"
}

dependencies {
    "wxs_core",
    "oxmysql"
}

provide 'es_extended'
provide 'qb-core'
