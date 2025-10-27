fx_version("cerulean")

games({ "gta5" })

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
	"@sleepless_interact/init.lua",
	"client.lua",
})

server_scripts({
	"server.lua",
})

exports({})
