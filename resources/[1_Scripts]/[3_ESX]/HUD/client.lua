ESX = exports["es_extended"]:getSharedObject()


function updateHUD()
    ESX.TriggerServerCallback('dynastyHUD:getPlayerMoney', function(data)
        SendNUIMessage({
            type = 'updateHUD',
            dirty = data.dirty,   -- Argent Sale
            cash = data.cash,     -- Liquide
            bank = data.bank      -- Banque
        })
    end)
end

AddEventHandler('playerSpawned', updateHUD)
RegisterNetEvent('esx:setAccountMoney', updateHUD)

RegisterCommand('update', function()
    updateHUD()
end, false)

Citizen.CreateThread(function()
    while true do
        updateHUD()
        Citizen.Wait(5000)
    end
end)