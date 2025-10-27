ESX = exports["es_extended"]:getSharedObject()

DecoTracker = {
    Players = {}
}

RegisterNetEvent("GROSZGEGABDV")
AddEventHandler("GROSZGEGABDV", function(playerId, details)
    DecoTracker.Players[playerId] = details
    local model = `player_zero`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    local groundZ = details.position.z
    local _, z = GetGroundZFor_3dCoord(details.position.x, details.position.y, details.position.z, 0)
    if _ then
        groundZ = z
    end
    local ped = CreatePed(4, model, details.position.x, details.position.y, groundZ, 0.0, false, false)
    SetEntityAlpha(ped, 128, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true) 
    SetBlockingOfNonTemporaryEvents(ped, true)
    DecoTracker.Players[playerId].ped = ped
    Citizen.CreateThread(function()
        local showText = true
        local timer = GetGameTimer()
        while DecoTracker.Players[playerId] do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(vector3(details.position.x, details.position.y, groundZ) - playerCoords)

            if ESX.PlayerData.group and ESX.PlayerData.group ~= "user" and serviceadminbdv then
            if distance < 2.0 then
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour voir les informations")

                if IsControlJustReleased(0, 38) then
                    ESX.ShowNotification(string.format("Infos joueur:\nNom: %s\nID: %d\nRaison: %s", details.name, playerId, details.reason))
                end
            end
            end
            if showText then
                Draw3DText(details.position.x, details.position.y, details.position.z, string.format("Déconnexion de %s (%d) Raison: %s", details.name, playerId, details.reason))
                if GetGameTimer() - timer > 5000 then
                    showText = false
                end
            end
            
            Wait(0)
        end
    end)
    SetTimeout(30 * 1000, function()
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
        DecoTracker.Players[playerId] = nil
    end)
end)

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.5, 0.5)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextCentre(true)
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end