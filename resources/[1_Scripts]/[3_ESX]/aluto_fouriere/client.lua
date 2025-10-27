ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

local vehiclesImpound = {}

openFouriere = function()
	local mainMenu = RageUI.CreateMenu("MENU FOURRIERE", "Menu Fourrière")
	mainMenu.EnableMouse = false

	mainMenu.Closed = function() end

	RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
	while mainMenu do
		Wait(0)
		RageUI.IsVisible(mainMenu, function()
			RageUI.Separator("↓ ~o~Vos voitures en fourrière~s~ ↓")
			for i, v in pairs(vehiclesImpound) do
				RageUI.Button(
					GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)) or "Véhicule inconnu",
					"Plaque : ~y~" .. v.plate .. "~s~\nCoût de la fourrière : ~r~500$",
					{},
					true,
					{
						onSelected = function()
							TriggerServerEvent("fourriere:retrieveImpoundMoney")
							SpawnVehicle(v.vehicle, v.plate)
							RageUI.CloseAll()
							ESX.ShowNotification(
								"Vous avez payé ~r~500$~s~ pour sortir votre véhicule de la fourrière !"
							)
						end,
					}
				)
			end
		end, function() end)
	end
end

exports.ox_target:addModel("a_m_y_stbla_02", {
	label = "Ouvrir la fourrière",
	name = "a_m_y_stbla_02",
	icon = "fa-solid fa-car",
	distance = 4,
	onSelect = function(entity, coords, distance, zone)
		ESX.TriggerServerCallback("fourriere:getVehicles", function(cb)
			vehiclesImpound = cb
		end)
		openFouriere()
	end,
})

function SpawnVehicle(vehicle, plate)
	print("lzlzlzllz")
	local x, y, z = 406.180237, -1643.024170, 29.279907

	ESX.Game.SpawnVehicle(vehicle.model, { x = x, y = y, z = z }, GetEntityHeading(PlayerPedId()), function(veh)
		ESX.Game.SetVehicleProperties(newVeh, vehicle)
		Citizen.Wait(1000)
		ESX.TriggerServerCallback("fourriere:getDamage", function(damageData)
			if damageData then
				--print("Application des dégâts :", json.encode(damageData))
				ApplyVehicleDamageState(veh, damageData)
			else
				--print("Aucun dégât récupéré pour ce véhicule.")
			end
		end, plate)
	end)

	SetVehRadioStation(newVeh, "OFF")
	SetVehicleUndriveable(newVeh, false)
	SetVehicleEngineOn(newVeh, true, true)
	TaskWarpPedIntoVehicle(PlayerPedId(), newVeh, -1)
	TriggerServerEvent("fourriere:changeStoredState", plate, true)
	print("ah bah oui")
end

function ApplyVehicleDamageState(vehicle, damage)
	if not DoesEntityExist(vehicle) then
		return
	end

	if damage.engineHealth then
		SetVehicleEngineHealth(vehicle, damage.engineHealth)
	end

	if damage.bodyHealth then
		SetVehicleBodyHealth(vehicle, damage.bodyHealth)
	end

	for i = 0, 5 do
		if damage.doorStatus[tostring(i)] then
			SetVehicleDoorBroken(vehicle, i, true)
		end
	end

	for i = 0, 7 do
		if damage.tyreBurst[tostring(i)] then
			SetVehicleTyreBurst(vehicle, i, true, 1000.0)
		end
	end

	for i = 0, 7 do
		if damage.windowStatus[tostring(i)] then
			SmashVehicleWindow(vehicle, i)
		end
	end
end
