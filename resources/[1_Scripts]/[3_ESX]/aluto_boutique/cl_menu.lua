ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

local code = 'Erreur. CODE 1155'
local UID = 'Erreur. CODE 1145'
local nbKurions = 0
local buyLink = 'https://www.google.com/'


local globalItems = {'Acheter', 'Visualiser', 'Tester'}
local globalIndex = 1
local lastPos = nil
local lastVeh = nil
local VehicleSpawned = {}
local plate = ''
local vehProps = nil


local NumberCharset = {}
local Charset = {}

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end


function openWebLink(url)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openLink',
        url = url
    })
    Citizen.SetTimeout(1500, function()
        SetNuiFocus(false, false)
    end)
end


openMenuBoutique = function()
    local mainMenu = RageUI.CreateMenu("MENU BOUTIQUE", "Menu Boutique");
	mainMenu.EnableMouse = false;

    local menuVehicules = RageUI.CreateSubMenu(mainMenu, "Véhicules", "Véhicules")
    local menuArmes = RageUI.CreateSubMenu(mainMenu, "Armes", "Armes")
    local menuCaisses = RageUI.CreateSubMenu(mainMenu, "Caisses", "Caisses")
    local menuGrades = RageUI.CreateSubMenu(mainMenu, "Grades", "Grades")

    mainMenu.Closed = function() end
    menuVehicules.Closed = function()
        DeleteEntity(lastVeh)
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, 0)
        SetEntityCoords(PlayerPedId(), lastPos)
        SetFollowPedCamViewMode(1)
        for k,v in pairs(VehicleSpawned) do 
            if DoesEntityExist(v.model) then
                Wait(150)
                DeleteEntity(v.model)
                table.remove(VehicleSpawned, k)
            end
        end
        DisableControlAction(0, 0, false)
        TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', false)
        --print('closed')
    end

    RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
    while mainMenu do 
        Wait(0)
        RageUI.IsVisible(mainMenu, function()
            RageUI.Separator('Votre code boutique : ~y~'..code)
            RageUI.Separator('Votre UID : ~y~'..UID)
            RageUI.Separator('Vos ~r~Kurions~s~ : '..nbKurions)
            RageUI.Button('Acheter des Kurions', nil, {RightLabel = '→→→'}, true, {
                onSelected = function()
                    openWebLink(buyLink)
                end
            })
            RageUI.Separator('_________________________')
            if exports["aluto_safezone"]:IsPlayerInSafeZoneClient() then
                RageUI.Button('Véhicules EXCLUSIFS', nil, {RightLabel = '→→→'}, true, {
                    onSelected = function()
                        lastPos = GetEntityCoords(PlayerPedId())
                        rot = 1.0
                        FreezeEntityPosition(PlayerPedId(), true)
                        SetEntityVisible(PlayerPedId(), false, 0)
                        SetFollowPedCamViewMode(4)
                        SetEntityCoords(PlayerPedId(), vector3(960.6409, 34.4316, 125.6404))
                        SetEntityHeading(PlayerPedId(), 325.1803)
                        TriggerServerEvent('BoutiqueBucket:SetEntitySourceBucket', true)
                        SetWeatherTypeNow('EXTRASUNNY')
                    end
                }, menuVehicules)
            else
                RageUI.Button('Véhicules EXCLUSIFS', nil, {RightLabel = '→→→'}, true, {
                    onSelected = function()
                        ESX.ShowNotification('~r~Vous devez être en zone safe pour pouvoir ouvrir ce menu !')
                    end
                })
            end
            RageUI.Button('Armes PERMANENTES', nil, {RightLabel = '→→→'}, true, {
                onSelected = function()

                end
            }, menuArmes)
            RageUI.Button('Caisses Mystères', nil, {RightLabel = '→→→'}, true, {
                onSelected = function()

                end
            }, menuCaisses)
            RageUI.Button('Grades', nil, {RightLabel = '→→→'}, true, {
                onSelected = function()

                end
            }, menuGrades)
        end, function() end)
        
        RageUI.IsVisible(menuVehicules, function()
            DisableControlAction(0, 0, true)
            for k,v in pairs(vehiculesBoutique) do 
                RageUI.List(v.label..' | Prix : ~g~'..v.price, globalItems, globalIndex, v.description, {}, true, {
                    onActive = function()
                        if lastVeh ~= nil then
                            rot = rot + 0.20
                            SetEntityHeading(lastVeh, rot)
                        end
                    end,
                    onListChange = function(Index)
						globalIndex = Index
					end,
                    onSelected = function()
                        if globalIndex == 1 then 
                            ESX.TriggerServerCallback('korona:retrieveCoins', function(cb)
                                print(type(v.price))
                                if tonumber(cb) >= v.price then
                                    print('buy '..v.model)
                                    plate = ''
                                    plate = GeneratePlate()
                                    if ESX.Game.IsSpawnPointClear(vector3(965.7822, 42.1806, 123.1267), 100) then
                                        ESX.Game.SpawnLocalVehicle(v.model, vector3(965.7822, 42.1806, 123.1267), 146.9412, function(vehicle)
                                            lastVeh = vehicle
                                            FreezeEntityPosition(vehicle, true)
                                            SetVehicleDoorsLocked(vehicle, 2)
                                            SetEntityInvincible(vehicle, true)
                                            SetVehicleFixed(vehicle)
                                            SetVehicleDirtLevel(vehicle, 0.0)
                                            SetVehicleEngineOn(vehicle, true, true, true)
                                            SetVehicleLights(vehicle, 2)
                                            SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                            SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                            SetVehicleNumberPlateText(vehicle, plate)
                                            vehProps = ESX.Game.GetVehicleProperties(vehicle)
                                            table.insert(VehicleSpawned, {model = vehicle})
                                        end)
                                    else
                                        DeleteEntity(lastVeh)
                                        ESX.Game.SpawnLocalVehicle(v.model, vector3(965.7822, 42.1806, 123.1267), 146.9412, function(vehicle)
                                            lastVeh = vehicle
                                            FreezeEntityPosition(vehicle, true)
                                            SetVehicleDoorsLocked(vehicle, 2)
                                            SetEntityInvincible(vehicle, true)
                                            SetVehicleFixed(vehicle)
                                            SetVehicleDirtLevel(vehicle, 0.0)
                                            SetVehicleEngineOn(vehicle, true, true, true)
                                            SetVehicleLights(vehicle, 2)
                                            SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                            SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                            SetVehicleNumberPlateText(vehicle, plate)
                                            vehProps = ESX.Game.GetVehicleProperties(vehicle)
                                            table.insert(VehicleSpawned, {model = vehicle})
                                        end)
                                    end
                                    Wait(100)
                                    TriggerServerEvent('boutique:buyVehicle', plate, vehProps, 'car')
                                    ESX.ShowNotification('Vous venez d\'acheter un véhicule de la boutique pour ~r~'..v.price..' Kurions. Merci !')
                                else
                                    ESX.ShowNotification('Vous n\'avez pas assez de Kurions pour acheter ce produit.')
                                end
                            end, GetPlayerServerId(PlayerId()))
                            
                        elseif globalIndex == 2 then 
                            plate = ''
                            plate = GeneratePlate()
                            if ESX.Game.IsSpawnPointClear(vector3(965.7822, 42.1806, 123.1267), 100) then
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(965.7822, 42.1806, 123.1267), 146.9412, function(vehicle)
                                    lastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    SetVehicleNumberPlateText(vehicle, plate)
                                    vehProps = ESX.Game.GetVehicleProperties(vehicle)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            else
                                DeleteEntity(lastVeh)
                                ESX.Game.SpawnLocalVehicle(v.model, vector3(965.7822, 42.1806, 123.1267), 146.9412, function(vehicle)
                                    lastVeh = vehicle
                                    FreezeEntityPosition(vehicle, true)
                                    SetVehicleDoorsLocked(vehicle, 2)
                                    SetEntityInvincible(vehicle, true)
                                    SetVehicleFixed(vehicle)
                                    SetVehicleDirtLevel(vehicle, 0.0)
                                    SetVehicleEngineOn(vehicle, true, true, true)
                                    SetVehicleLights(vehicle, 2)
                                    SetVehicleCustomPrimaryColour(vehicle, 33,33,33)
                                    SetVehicleCustomSecondaryColour(vehicle, 33,33,33)
                                    SetVehicleNumberPlateText(vehicle, plate)
                                    vehProps = ESX.Game.GetVehicleProperties(vehicle)
                                    table.insert(VehicleSpawned, {model = vehicle})
                                end)
                            end
                            --print('visualiser '..v.model)
                        elseif globalIndex == 3 then 
                            print('tester '..v.model)
                        end
                    end
                })
            end
        end, function() end)

        RageUI.IsVisible(menuArmes, function()
            for k,v in pairs(armesBoutique) do 
                RageUI.List(v.label..' | Prix : ~g~'..v.price, globalItems, globalIndex, v.description, {}, true, {
                    onListChange = function(Index)
						globalIndex = Index
					end,
                    onSelected = function()
                        if globalIndex == 1 then 
                            print('buy '..v.model)
                        elseif globalIndex == 2 then 
                            print('visualiser '..v.model)
                        elseif globalIndex == 3 then 
                            print('tester '..v.model)
                        end
                    end
                })
            end
        end, function() end)

        RageUI.IsVisible(menuCaisses, function()
            for k,v in pairs(caissesBoutique) do 
                RageUI.List(v.label..' | Prix : ~g~'..v.price, globalItems, globalIndex, v.description, {}, true, {
                    onListChange = function(Index)
						globalIndex = Index
					end,
                    onSelected = function()
                        if globalIndex == 1 then 
                            TriggerServerEvent('korona:boutique:checkoutCaisse', UID, v.model, v.price)
                            print('buy '..v.model)
                        elseif globalIndex == 2 then 
                            print('visualiser '..v.model)
                        elseif globalIndex == 3 then 
                            print('tester '..v.model)
                        end
                    end
                })
            end
        end, function() end)

    end
end

function GeneratePlate()
	math.randomseed(GetGameTimer())

	local generatedPlate = string.upper(GetRandomLetter(3) .. (true and ' ' or '') .. GetRandomNumber(3))

	local isTaken = IsPlateTaken(generatedPlate)
	if isTaken then 
		return GeneratePlate()
	end

	return generatedPlate
end

function IsPlateTaken(plate)
	local p = promise.new()
	
	ESX.TriggerServerCallback('boutique:isPlateTaken', function(isPlateTaken)
		p:resolve(isPlateTaken)
	end, plate)

	return Citizen.Await(p)
end

function GetRandomNumber(length)
	Wait(0)
	return length > 0 and GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)] or ''
end

function GetRandomLetter(length)
	Wait(0)
	return length > 0 and GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)] or ''
end

Keys.Register("F1", "F1", "Menu Boutique", function()
    ESX.TriggerServerCallback('korona:getUIDfromID', function(cb)
        UID = cb
    end, GetPlayerServerId(PlayerId()))
    ESX.TriggerServerCallback('korona:getCodeBoutique', function(cb)
        code = cb
    end, GetPlayerServerId(PlayerId()))
    ESX.TriggerServerCallback('korona:retrieveCoins', function(cb)
        nbKurions = cb
    end, GetPlayerServerId(PlayerId()))
    --print(nbKurions)
    openMenuBoutique()
end)