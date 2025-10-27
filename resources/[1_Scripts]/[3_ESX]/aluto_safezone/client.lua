ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end


local isInSafeZone = false
local protected = false

local safeZones = {
    vector3(226.813187, -782.848328, 30.880615) -- Parking Central
}

local disabledActions = {24, 25, 68, 69, 70, 91, 92, 106}

Citizen.CreateThread(function()
    while true do 
        Wait(2000)
        ESX.TriggerServerCallback('korona:getGroupForSafezone', function(cb) 
            protected = cb
        end, id)
    end
end)

Citizen.CreateThread(function()
	while not NetworkIsPlayerActive(PlayerId()) do
		Citizen.Wait(0)
	end

	while true do
		local plyPed = PlayerPedId()
		local plyCoords = GetEntityCoords(plyPed, false)
		local minDistance = 50000

		for i = 1, #safeZones, 1 do
			local dist = #(safeZones[i] - plyCoords)

			if dist < minDistance then
				minDistance = dist
				closestZone = i
			end
		end

		Citizen.Wait(15000)
	end
end)

Citizen.CreateThread(function()
    while true do 
        local plyPed = PlayerPedId()
        local plyCoords = GetEntityCoords(plyPed)
        local minDistance = 80

        local distance = #(safeZones[closestZone] - plyCoords)
        if distance < minDistance then 
            if not isInSafeZone then
                isInSafeZone = true
                NetworkSetFriendlyFireOption(false)
                SetCurrentPedWeapon(plyPed, `WEAPON_UNARMED`, true)
                TriggerServerEvent('korona:updateSafezoneStatus', true)
                ESX.ShowNotification('✅ ~g~Vous êtes dans une safezone !')
            end
        else 
            if isInSafeZone then
                isInSafeZone = false
                NetworkSetFriendlyFireOption(true)
                TriggerServerEvent('korona:updateSafezoneStatus', false)
                ESX.ShowNotification("❌ ~r~Vous n'êtes plus dans une safezone !")
            end
        end
        Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do 
        local plyPed = PlayerPedId()
        if isInSafeZone and not protected then 
            Wait()
            DisablePlayerFiring(plyPed, true)
            for i = 1, #disabledActions, 1 do 
                DisableControlAction(0, disabledActions[i], true)
                if IsDisabledControlJustPressed(0, disabledActions[i]) then 
                    SetCurrentPedWeapon(plyPed, 0xA2719263, true)
                    ESX.ShowNotification('~r~Vous ne pouvez pas faire ceci en safezone.')
                    break
                end
            end
        else 
            Wait(1000)
        end 
    end
end)

exports('IsPlayerInSafeZoneClient', function()
    return isInSafeZone
end)