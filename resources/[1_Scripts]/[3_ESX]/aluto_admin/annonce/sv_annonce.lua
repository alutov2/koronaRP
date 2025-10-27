ESX = exports["es_extended"]:getSharedObject()

local hasAccess = false

function checkAccess(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local group = xPlayer.getGroup()
    if group ~= user then 
        hasAccess = true 
    end
end

RegisterCommand('annonce', function(source, args)
    local _src = source 
    local argument = table.concat(args, ' ', 1)
    if _src == 0 then
        TriggerClientEvent('korona:displayWarnOnScreen', -1, 'Annonce SERVEUR', argument)
        --print('^2Annonce effectuée : "'..argument..'" par '..YveltHelper:getPlayerName(targetId)..'^0')
    else
        checkAccess(source)
        if hasAccess then 
            TriggerClientEvent('korona:displayWarnOnScreen', -1, 'Annonce', argument)
            --print('^2Annonce effectuée : "'..argument..'" par '..YveltHelper:getPlayerName(targetId)..'^0')
        else
            --YveltHelper:serverNotification(_src, '~r~Tu n\'as pas la permission !')
        end
    end
end)