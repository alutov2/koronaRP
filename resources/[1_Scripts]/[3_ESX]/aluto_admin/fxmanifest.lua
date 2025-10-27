fx_version("cerulean")

games({ "gta5" })

lua54("yes")

use_experimental_fxv2_oal("yes")

dependency("yarn")

shared_script({ "shared/libs/eventbase.lua", "shared/functions.lua", "shared/libs/modules.lua" })

client_scripts({ "client/libs/game.lua", "client/libs/xmenu/api/main.lua", "client/libs/xmenu/api/example.lua" })

client_script("client/init.lua")

--shared_script("shared/functions.lua")

ui_page("ui/app/index.html")

ui_page_preload("yes")

loadscreen("ui/loadingscreen/index.html")

files({
	"ui/app/index.html",
	"ui/app/vendor/**/*",
	"ui/app/css/*",
	"ui/app/js/*",
	"ui/app/img/*",
	"ui/app/sounds/*",
	"ui/app/fonts/*",
	"client/libs/xmenu/dist/fonts/*",
	"client/libs/xmenu/dist/css/app.css",
	"client/libs/xmenu/dist/js/chunk-vendors.js",
	"client/libs/xmenu/dist/js/app.js",
	"client/libs/xmenu/dist/index.html",
	"client/libs/xmenu/dist/img/header.png",
})

server_scripts({
	"@oxmysql/lib/MySQL.lua",
	"admin_server_module.lua",
	"bans/sv_bans.lua",
	"server.lua",
	"annonce/sv_annonce.lua",
	"reports/sv_reports.lua",
	"uid/sv_uid.lua",
	"jail/sv_jail.lua",
})

client_scripts({
	"RageUIv2/RMenu.lua",
	"RageUIv2/menu/RageUI.lua",
	"RageUIv2/menu/Menu.lua",
	"RageUIv2/menu/MenuController.lua",
	"RageUIv2/components/*.lua",
	"RageUIv2/menu/elements/*.lua",
	"RageUIv2/menu/items/*.lua",
	"RageUIv2/menu/panels/*.lua",
	"RageUIv2/menu/windows/*.lua",
	"client.lua",
	"annonce/cl_annonce.lua",
	"reports/cl_reports.lua",
	"pistolstaff/cl_pistol.lua",
	"uid/cl_uid.lua",
	"noclip/noclip.lua",
	"jail/cl_jail.lua",
	"adminmodule.lua",
})

exports({
	"getUIDfromID",
	"getIDfromUIDnew",
	"getIdentifierfromUID",
})
