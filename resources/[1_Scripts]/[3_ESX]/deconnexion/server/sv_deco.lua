ESX = exports["es_extended"]:getSharedObject()

DecoTracker = {
    Players = {}
}

AddEventHandler("playerDropped", function(reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        local playerCoords = xPlayer.getCoords(true)
        local playerName = xPlayer.getName()
        
        DecoTracker.Players[src] = { reason = reason, timestamp = os.date("%d/%m %X"), position = playerCoords, name = playerName }
        TriggerClientEvent("GROSZGEGABDV", -1, src, DecoTracker.Players[src])
    end
end)