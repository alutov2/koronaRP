fx_version 'cerulean'

games { 'gta5' }

server_script '@oxmysql/lib/MySQL.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/main.js'
}

client_scripts {
    'RageUIv2/RMenu.lua',
    'RageUIv2/menu/RageUI.lua',
    'RageUIv2/menu/Menu.lua',
    'RageUIv2/menu/MenuController.lua',
    'RageUIv2/components/*.lua',
    'RageUIv2/menu/elements/*.lua',
    'RageUIv2/menu/items/*.lua',
    'RageUIv2/menu/panels/*.lua',
    'RageUIv2/menu/windows/*.lua',
    'cl_menu.lua',
    'shared/config.lua',
}

server_scripts {
    'server.lua',
    'shared/sv_config.lua'
}

