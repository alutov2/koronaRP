ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

local vehiclesInGarage = {}

openGarage = function()
	local mainMenu = RageUI.CreateMenu("MENU GARAGE", "Menu Garage")
	mainMenu.EnableMouse = false

	mainMenu.Closed = function() end

	RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
	while mainMenu do
		Wait(0)
		RageUI.IsVisible(mainMenu, function()
			RageUI.Separator("↓ ~g~Vos voitures garées~s~ ↓")
			for i, v in pairs(vehiclesInGarage) do
				RageUI.Button(
					GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)) or "Véhicule inconnu",
					"Plaque : " .. v.plate,
					{},
					true,
					{
						onSelected = function()
							SpawnVehicle(v.vehicle, v.plate)
							RageUI.CloseAll()
						end,
					}
				)
			end
		end, function() end)
	end
end

-- // PNJ \\

exports.ox_target:addModel("a_m_m_business_01", {
	label = "Ouvrir le garage",
	name = "a_m_m_business_01",
	icon = "fa-solid fa-car",
	distance = 4,
	onSelect = function(entity, coords, distance, zone)
		ESX.TriggerServerCallback("garage:getVehicles", function(cb)
			vehiclesInGarage = cb
		end)
		openGarage()
	end,
})

-- // MARKER \\

local function IsPlayerInZone(pos, radius)
	local playerCoords = GetEntityCoords(PlayerPedId())
	return #(playerCoords - pos) <= radius
end

Citizen.CreateThread(function()
	while true do
		local markerPos = vector3(217.186813, -785.459351, 30.813232)
		if IsPlayerInZone(markerPos, 50.0) then
			DrawMarker(
				1,
				markerPos.x,
				markerPos.y,
				markerPos.z - 1.0,
				0.0,
				0.0,
				0.0,
				0.0,
				0.0,
				0.0,
				15.0,
				15.0,
				1.0,
				245,
				0,
				0,
				100,
				false,
				false,
				2,
				false,
				nil,
				nil,
				false
			)
			Wait(0)
		else
			Wait(500)
		end
	end
end)

-- // RANGER \\

Citizen.CreateThread(function()
	local hisVehicle = false
	while true do
		Wait(0)
		local markerPos = vector3(217.186813, -785.459351, 30.813232)
		if IsPlayerInZone(markerPos, 7.5) then
			if IsPedInAnyVehicle(PlayerPedId(), false) then
				ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ranger votre véhicule.")
				if IsControlJustReleased(0, 38) then -- Touche E
					local ped = PlayerPedId()
					local car = GetVehiclePedIsIn(ped)
					local props = ESX.Game.GetVehicleProperties(car)
					local plate = props.plate
					local damageState = GetVehicleDamageState(car)
					TriggerServerEvent("garage:saveDamage", plate, damageState)
					ESX.TriggerServerCallback("garage:checkVehicleOwner", function(cb)
						hisVehicle = cb
					end, plate)
					Wait(200)
					if hisVehicle == true then
						TaskLeaveAnyVehicle(ped, 0, 1)
						Citizen.CreateThread(function()
							while IsPedInVehicle(ped, car, false) do
								Wait(100)
							end
							Wait(2000)
							DeleteEntity(car)
							TriggerServerEvent("garage:changeStoredState", plate, true)
						end)
					else
						ESX.ShowNotification("~r~Vous ne pouvez pas ranger ce véhicule.")
					end
				end
			end
		end
	end
end)

-- // FUNCTIONS \\

function SpawnVehicle(vehicle, plate)
	local x, y, z = 232.114288, -793.173645, 30.57727

	--local newVeh = CreateVehicle(vehicle.model, x, y, z, GetEntityHeading(PlayerPedId()), true, false)
	--[[ESX.Game.SpawnVehicle(vehicle.model, { x = x, y = y, z = z }, GetEntityHeading(PlayerPedId()), function(veh)
		ESX.Game.SetVehicleProperties(newVeh, vehicle)
		print(plate)
		print(ESX.Game.GetVehicleProperties(newVeh))
		Citizen.Wait(1000)
		ESX.TriggerServerCallback("garage:getDamage", function(damageData)
			if damageData then
				--print("Application des dégâts :", json.encode(damageData))
				ApplyVehicleDamageState(veh, damageData)
			else
				--print("Aucun dégât récupéré pour ce véhicule.")
			end
		end, plate)
	end)]]

	local newVeh = CreateVehicle(vehicle.model, x, y, z, GetEntityHeading(PlayerPedId()), true, false)
	ESX.Game.SetVehicleProperties(newVeh, vehicle)

	SetVehRadioStation(newVeh, "OFF")
	SetVehicleUndriveable(newVeh, false)
	SetVehicleEngineOn(newVeh, true, true)
	TaskWarpPedIntoVehicle(PlayerPedId(), newVeh, -1)
	TriggerServerEvent("garage:changeStoredState", plate, false)
end

function GetVehicleDamageState(vehicle)
	local damage = {}

	damage.engineHealth = GetVehicleEngineHealth(vehicle)
	damage.bodyHealth = GetVehicleBodyHealth(vehicle)
	damage.doorStatus = {}
	damage.tyreBurst = {}
	damage.windowStatus = {}

	for i = 0, 5 do
		damage.doorStatus[i] = IsVehicleDoorDamaged(vehicle, i)
	end

	for i = 0, 7 do
		damage.tyreBurst[i] = IsVehicleTyreBurst(vehicle, i, false)
	end

	for i = 0, 7 do
		damage.windowStatus[i] = not IsVehicleWindowIntact(vehicle, i)
	end

	return damage
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
