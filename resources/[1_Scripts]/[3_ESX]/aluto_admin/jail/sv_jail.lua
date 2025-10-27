RegisterServerEvent('korona:endOfJail')
AddEventHandler('korona:endOfJail', function(id, uid, staffName)
    local result = MySQL.query.await('SELECT * FROM korona_sanctions WHERE uid = @uid', {
        ['@uid'] = uid
    })
    if #result > 0 then
        for i=1, #result do 
            local row = result[i]
            if row.type == 'jail' then 
                MySQL.update('DELETE FROM `korona_sanctions` WHERE uid = ?', {uid})
                if staffName ~= nil then 
                    TriggerClientEvent("korona:unjailClient", id, staffName)
                end
            end
        end
    end
end)

local jailedPlayers = {}

RegisterServerEvent('korona:updateJailedTime')
AddEventHandler('korona:updateJailedTime', function(uid, time)
    if tonumber(time) > 0 then
        if not jailedPlayers[uid] then
            jailedPlayers[uid] = { time = time }
            --print('created new')
        else 
            jailedPlayers[uid].time = time
            --print('deja')
        end 
    elseif time == 0 then 
        jailedPlayers[uid] = nil 
    end
end)

AddEventHandler('esx:playerLoaded',function(player, xPlayer, isNew)
    local uid = UID:getUIDfromID(player)
    if jailedPlayers[uid] then 
        Wait(100)
        TriggerClientEvent('korona:setInJail', player, uid, jailedPlayers[uid].time, 'Vous avez quitté alors que vous étiez jail', 'Serveur')
        --print('jailed')
    else 
        --print('pas jail')
    end
end)