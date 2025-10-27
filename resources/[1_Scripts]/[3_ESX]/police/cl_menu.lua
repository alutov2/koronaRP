ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

local isInServicePolice = false

local cuffeddict = 'mp_arresting'
local cuffedanim = 'crook_p2_back_left'

local cuffdict = 'mp_arrest_paired'
local cuffanim = 'cop_p2_back_left'

local uncuffdict = 'mp_arresting'
local uncuffanim = 'a_uncuff'

openMenuPolice = function()
    local mainMenu = RageUI.CreateMenu("MENU POLICE", "Menu Police");
	mainMenu.EnableMouse = false;

	local menuCitoyens = RageUI.CreateSubMenu(mainMenu, "Citoyens", "Citoyens")
    local menuVehicules = RageUI.CreateSubMenu(mainMenu, "Véhicules", "Véhicules")
    local menuRadio = RageUI.CreateSubMenu(mainMenu, "Radio", "Radio")
    local menuAgents = RageUI.CreateSubMenu(mainMenu, "Agents", "Agents")

    local menuCarte = RageUI.CreateSubMenu(menuCitoyens, "Carte d'identité", "Carte d'identité")
    local menuSanctions = RageUI.CreateSubMenu(menuCitoyens, "Sanctions", "Sanctions")

    mainMenu.closed = function() end

    RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
    while mainMenu do 
        Wait(0)
        RageUI.IsVisible(mainMenu, function()
            RageUI.Checkbox('Prendre son service', nil, isInServicePolice, {}, {
                onChecked = function()
                    isInServicePolice = true
                end,
                onUnchecked = function()
                    isInServicePolice = false
                end,
                onSelected = function(Index)
                    isInServicePolice = Index
                end
            })
            if isInServicePolice then 
                RageUI.Button('Intéractions Citoyens', nil, {RightLabel = '→→→'}, true, {}, menuCitoyens)
                RageUI.Button('Intéractions Véhicules', nil, {RightLabel = '→→→'}, true, {}, menuVehicules)
                RageUI.Button('Codes Radio', nil, {RightLabel = '→→→'}, true, {}, menuRadio)
                RageUI.Button('Agents en service', nil, {RightLabel = '→→→'}, true, {}, menuAgents)
            end
        end, function() end)

        RageUI.IsVisible(menuCitoyens, function()
            RageUI.Button('Menotter/Démenotter', nil, {RightLabel = ''}, true, {
                onSelected = function()
                    --[[local closestPlayer, distance = ESX.Game.GetClosestPlayer()
                    print(closestPlayer)
                    if distance <= 3 and distance ~= 1 and closestPlayer ~= -1 and not IsPedInAnyVehicle(PlayerPedId()) and not IsPedInAnyVehicle(GetPlayerPed(closestPlayer)) then 
                        local targetPed = GetPlayerPed(closestPlayer)
                        ESX.Streaming.RequestAnimDict(cuffdict)
                        local plyPed = PlayerPedId()
                        TaskPlayAnim(plyPed, cuffdict, cuffanim, 8.0, -8.0, 4300, 33, 0.0, false, false, false)
                        RemoveAnimDict(cuffdict)
                        Citizen.Wait(4300)
                        SetEnableHandcuffs(targetPed, true)
                    else 
                        ESX.ShowNotification('Action impossible.')
                    end]]
                end
            })
            RageUI.Button('Fouiller', nil, {RightLabel = '→→→'}, true, {
                onSelected = function()

                end
            })
            RageUI.Button('Prendre carte d\'identité', nil, {RightLabel = '→→→'}, true, {
                onSelected = function()

                end
            }, menuCarte)
            RageUI.Button('Escorter', nil, {RightLabel = ''}, true, {
                onSelected = function()

                end
            })
            RageUI.Button('Mettre dans le véhicule', nil, {RightLabel = ''}, true, {
                onSelected = function()

                end
            })
            RageUI.Button('Sortir du véhicule', nil, {RightLabel = ''}, true, {
                onSelected = function()

                end
            })
            RageUI.Button('Sanctions', nil, {RightLabel = '→→→'}, true, {
                onSelected = function()

                end
            }, menuSanctions)
        end, function() end)
    end
end

Keys.Register("F6", "F6", "Menu Police", function()
	local xPlayer = GetPlayerFromServerId(PlayerId())
    if ESX.GetPlayerData().job.name == "police" then 
        openMenuPolice()
    end
end)