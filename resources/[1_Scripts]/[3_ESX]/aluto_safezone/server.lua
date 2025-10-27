ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

local safeZoneStatus = {}

ESX.RegisterServerCallback('korona:getGroupForSafezone', function(id, cb)
    local xPlayer = ESX.GetPlayerFromId(id)
    if xPlayer.getGroup() ~= 'user' then 
        cb(true)
    else 
        cb(false)
    end
end)

RegisterServerEvent('korona:updateSafezoneStatus')
AddEventHandler('korona:updateSafezoneStatus', function(status)
    local src = source
    safeZoneStatus[src] = status
end)

AddEventHandler('playerDropped', function(reason)
    safeZoneStatus[source] = nil
end)

exports('IsPlayerInSafeZoneServer', function(id)
    return safeZoneStatus[id] == true
end)