games({ "gta5", "rdr3" })

fx_version("cerulean")

rdr3_warning(
	"I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
)

lua54("yes")

use_experimental_fxv2_oal("yes")

author("Slanting Studios")

version("1.0.0")

dependency("yarn")

shared_scripts({ "shared/libs/eventbase.lua", "shared/libs/modules.lua" })

client_scripts({ "client/libs/game.lua", "client/libs/xmenu/api/main.lua", "client/libs/xmenu/api/example.lua" })

client_script("client/init.lua")

shared_script("shared/functions.lua")

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

_module("personalmenu")({
	["maps"] = { "common" },
	["author"] = "MRV, Korioz",
	["dependencies"] = {},
	["description"] = "Personal menu",
	["shared"] = true,
	["games"] = { "gta5", "rdr3" },
	["projects"] = { "*" },
	["path"] = "modules/personalmenu",
})

client_scripts({
	"modules/personalmenu/client/config.lua",
	"modules/personalmenu/client/main.lua",
	"modules/personalmenu/client/module.lua",
})
