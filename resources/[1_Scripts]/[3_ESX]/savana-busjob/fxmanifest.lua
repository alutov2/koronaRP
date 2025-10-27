fx_version 'adamant'
game 'gta5'
author 'Savana Scripts'
description 'savana.tebex.io'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/shared.lua',
}

client_scripts {
    'shared/c_framework.lua',
    'main/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/s_framework.lua',
    'main/server.lua'
}

ui_page 'html/index.html'

files {
    'html/images/*.*',
    'html/images/**/*.*',
    'html/font/*.*',
    'html/*.*',    
}

escrow_ignore {
    'shared/*.lua'
}
dependency '/assetpacks'