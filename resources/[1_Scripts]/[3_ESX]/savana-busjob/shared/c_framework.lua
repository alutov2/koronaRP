Framework = {}
currentZone = nil

function Framework:GetIdentifier()
    if shared.Framework == "qb" then
        return FrameworkObject.Functions.GetPlayerData().citizenid
    elseif shared.Framework == "esx" then
        return FrameworkObject.GetPlayerData().identifier
    else
        -- Write your own code.
        return nil
    end
end

function Framework:Notify(msg, tip)
    if shared.Framework == "qb" then
        return FrameworkObject.Functions.Notify(msg, tip, 2500)
    elseif shared.Framework == "esx" then        
        return FrameworkObject.ShowNotification(msg,tip, 2500)
    else
        -- Write your own code.
        return nil
    end
end

function Framework:RemoveKey(vehicle, trailer)
    print(vehicle..' and ' ..trailer..' key deleted')
end

function Framework:SpawnClear(data,count)
    if shared.Framework == "qb" then
        return FrameworkObject.Functions.SpawnClear(data,count)
    elseif shared.Framework == "esx" then        
        return FrameworkObject.Game.IsSpawnPointClear(data,count)
    else
        -- Write your own code.
        return nil
    end
end

text = function(text, duration)
    if not shared.infoText then
        
    else
        ClearPrints()
        BeginTextCommandPrint('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandPrint(duration, 1)
    end
end

loadVehicle = function(vehicle, coords, heading)
    local model
    if type(vehicle) == 'number' then 
        model = vehicle 
    else 
        model = GetHashKey(vehicle) 
    end
    while not HasModelLoaded(model) do 
        Wait(0) 
        RequestModel(model) 
    end

    local car = CreateVehicle(model, coords.x,coords.y,coords.z, heading, true, false)
    SetEntityAsMissionEntity(car, true, true)
    
    TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(car))
    fuel(car)
    return car
end

function fuel(car)
    if GetResourceState('savana-fuel') == 'started' then
        return exports['savana-fuel']:SetFuel(car, 100.0)
    end
    if GetResourceState('LegacyFuel') == 'started' then
        return exports.LegacyFuel:SetFuel(car, 100.0)
    end
    if GetResourceState('cdn-fuel') == 'started' then
        return exports['cdn-fuel']:SetFuel(car, 100.0)
    end
    if GetResourceState('ox_fuel') == 'started' then
        return Entity(car) and Entity(car).state and Entity(car).state.fuel or 100
    end
end

for k, v in pairs(shared.BusJob) do
    if shared.UseTarget then
        RequestModel(v.ped)
        while not HasModelLoaded(v.ped) do
            Wait(0)
        end
        local ped = CreatePed(4, GetHashKey(v.ped), v.pedCoords.x, v.pedCoords.y, v.pedCoords.z -1, v.pedCoords.w, false, false)
        SetEntityHeading(ped, v.pedCoords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedDiesWhenInjured(ped, false)
        SetPedCanRagdoll(ped, false)

        if GetResourceState('ox_target') == 'started' then
            local coord = v.pedCoords
            exports.ox_target:addBoxZone({
                coords = vector3(coord.x,coord.y,coord.z),
                size = vec3(1, 1, 2),
                rotation = 0,
                debug = shared.debug,
                distance = 2.5,
                options = {
                    {
                        name = "OpenBusMenu",
                        label = shared.Locales["open_job_target"],
                        icon = "fas fa-briefcase",
                        onSelect = function()
                            currentZone = k
                            OpenBusMenu()
                        end,
                        canInteract = function(entity, distance, data)
                            return not working 
                        end,
                    },
                    {
                        name = 'cancel_mission',
                        label = shared.Locales["cancel_job_target"],
                        icon = "fas fa-truck",
                        onSelect = function(data)
                            endMission()
                        end,
                        canInteract = function(entity, distance, data)
                            return working 
                        end,
                    },
                },
            })
        else
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        label = shared.Locales["open_job_target"],
                        icon = "fas fa-briefcase",
                        action = function()
                            currentZone = k
                            OpenBusMenu()
                        end,
                        canInteract = function()
                            if not working then 
                                return true
                            end
                        end,
                    },
                    {
                        action = function()
                            endMission()
                        end,
                        icon = 'fas fa-truck',
                        label = shared.Locales["cancel_job_target"],
                        canInteract = function()
                            if working then 
                                return true
                            end
                        end,
                    },
                },
                distance = 2.0
            })
        end
    else
        local coords = vector3(v.pedCoords.x, v.pedCoords.y, v.pedCoords.z)
        
        Citizen.CreateThread(function()

            while true do
                wait = 1000
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local coords = vector3(v.pedCoords.x, v.pedCoords.y, v.pedCoords.z)
                local distance = #(playerCoords - coords)

                if distance < 18.0 then
                    currentZone = k
                    HandleDealerZone(v.pedCoords)
                    wait = 0
                end
                Citizen.Wait(wait)
            end
        end)
    end
end

function HandleDealerZone(_coords)
    coords = vector3(_coords.x, _coords.y, _coords.z)
    if menuOpened then return end

    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - coords)

    if distance < 18.0 then
        DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 0.5, 255, 255, 0, 100, false, true, 2, true, nil, nil, false)
        if distance < 1.5 then
            if not working then
                Draw3DText(coords.x, coords.y, coords.z + 0.4, shared.Locales["open_job"])
                if IsControlJustReleased(0, 38) then
                    OpenBusMenu()
                end
            else
                Draw3DText(coords.x, coords.y, coords.z + 0.4, shared.Locales["cancel_job"])
                if IsControlJustReleased(0, 38) then
                    endMission()
                end
            end
        end
    end
end

RegisterNetEvent('savana-busjob:client:sendNotifys',function(msg, tipim)
    Framework:Notify(msg, tipim)
end)


function Draw3DText(x, y, z, Text)
	if Text then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry("STRING")
		SetTextCentre(true)
		AddTextComponentString(Text)
		SetDrawOrigin(x, y, z, 0)
		DrawText(0.0, 0.0)
		local Factor = (string.len(Text)) / 370
		DrawRect(0.0, 0.0 + 0.0125, 0.017 + Factor, 0.03, 0, 0, 0, 75)
		ClearDrawOrigin()
	end
end

function createBlips()
    for _, bus in pairs(shared.BusJob) do
        local blip = AddBlipForCoord(bus.pedCoords.x, bus.pedCoords.y, bus.pedCoords.z)

        SetBlipSprite(blip, bus.blip.sprite) 
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, bus.blip.size)
        SetBlipColour(blip, bus.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(bus.blip.text)
        EndTextCommandSetBlipName(blip)
    end
end

if shared.Framework == 'esx' or shared.Framework == 'esxold' then
    RegisterNetEvent('esx:playerLoaded', function()
        createBlips()
    end)
else
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        createBlips()
    end)
end
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    endMission()
end)

AddEventHandler('onResourceStart', function(resourceName)
    -- handles script restarts
    if GetCurrentResourceName() == resourceName then
        createBlips()
    end
end)