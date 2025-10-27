fx_version 'cerulean'

games { 'gta5' }

server_script '@oxmysql/lib/MySQL.lua'

client_scripts {
    'client/cl_co.lua',
}

server_scripts {
    'server/sv_deco.lua',
}

