ESX = exports["es_extended"]:getSharedObject()

function ParseTime(input)
    if input == 0 then 
        return 0
    else
        if input ~= nil then 
            local value, unit = input:match("(%d+)(%a)")
            if value and unit then
                value = tonumber(value)
                if unit == "s" then
                    return value
                elseif unit == "m" then
                    return value * 60
                elseif unit == "h" then
                    return value * 3600
                elseif unit == "j" then
                    return value * 86400
                end
            end
            return 0
        else
            return 0
        end
    end
end

ESX.RegisterServerCallback('korona:getSanctionsList', function(source, cb, id)
    local license = GetPlayerIdentifierByType(id, 'license')
    local result = MySQL.query.await('SELECT * FROM korona_sanctions WHERE license = @license', {
        ['@license'] = license
    })
    cb(result)
end)

RegisterServerEvent('korona:punishPlayer')
AddEventHandler('korona:punishPlayer', function(type, id, temps, raison)
    local license = GetPlayerIdentifierByType(id, 'license')
    local uid = UID:getUIDfromID(id)
    local staffName = GetPlayerName(source)
    local date = os.date("%d")..'/'..os.date("%m")..'/'..os.date("%Y")..' à '..os.date("%H")..'h'..os.date("%M")..' et '..os.date("%S")..' secondes'
    local newTemps = ParseTime(temps)
    if newTemps > 0 then 
        newTemps = os.time() + newTemps
    end
    if staffName == nil then 
        staffName = 'CONSOLE'
    end
    if type == 'jail' then
        TriggerClientEvent('korona:setInJail', id, uid, temps, raison, staffName)
    elseif type == 'ban' then
        if temps == 0 then
            DropPlayer(id, 'Vous avez été banni de Korona RP pour : '..raison..'\nDurée : Permanent\nAuteur : '..staffName)
        else
            DropPlayer(id, 'Vous avez été banni de Korona RP pour : '..raison..'\nDurée : '..temps..'\nAuteur : '..staffName)
        end
    elseif type == 'kick' then
        DropPlayer(id, 'Vous avez été kick de Korona RP pour : '..raison..' | Auteur : '..staffName)
    end
    MySQL.insert('INSERT INTO `korona_sanctions` (license, uid, staff, type, raison, date, duree) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        license, uid, staffName, type, raison, date, newTemps 
    }, function(id)
    end)
end)

RegisterServerEvent('korona:removeSanction')
AddEventHandler('korona:removeSanction', function(rowid)
    if rowid ~= nil then 
        MySQL.update('DELETE FROM `korona_sanctions` WHERE id = ?', {rowid})
    else 
        print('Aucune sanction à supprimer')
    end
end)

AddEventHandler('playerConnecting', function(name, skr, d)
    local src = source 
    local license = GetPlayerIdentifierByType(src, 'license')
    local uid = UID:getUIDfromIdentifier(license)
    d.defer()
    d.update("Bienvenue sur Korona RP\nVérification de vos sanctions...")
    Wait(1000)
    local result = MySQL.query.await('SELECT * FROM korona_sanctions WHERE license = @license', {
        ['@license'] = license
    })
    local result2 = MySQL.query.await('SELECT * FROM korona_sanctions WHERE uid = @uid', {
        ['@uid'] = uid
    })
    if #result > 0 then
        for i=1, #result do 
            local row = result[i]
            if row.type == 'ban' then 
                if os.time() > row.duree and row.duree ~= 0 then 
                    d.update("Bienvenue sur Korona RP\nBon jeu à vous !")
                    Wait(3000)
                    d.done()
                    MySQL.update('DELETE FROM `korona_sanctions` WHERE license = ?', {license})
                else
                    d.update('Vous avez été banni pour '..row.raison..'\nLe : '..row.date..'\nAuteur : '..row.staff..'.\nTemps restant : '..getBanTime(row.uid)..'\nID de ban : '..row.uid..'')
                end 
            else 
                d.update("Bienvenue sur Korona RP\nBon jeu à vous !")
                Wait(3000)
                d.done()
            end
        end
    elseif #result2 > 0 then
            for i=1, #result2 do 
                local row = result2[i]
                if row.type == 'ban' then 
                    if os.time() > row.duree and row.duree ~= 0 then 
                        d.update("Bienvenue sur Korona RP\nBon jeu à vous !")
                        Wait(3000)
                        d.done()
                        MySQL.update('DELETE FROM `korona_sanctions` WHERE uid = ?', {uid})
                    else
                        d.update('Vous avez été banni pour '..row.raison..'\nLe : '..row.date..'\nAuteur : '..row.staff..'.\nTemps restant : '..getBanTime(row.uid)..'\nID de ban : '..row.uid..'')
                    end 
                else 
                    d.update("Bienvenue sur Korona RP\nBon jeu à vous !")
                    Wait(3000)
                    d.done()
                end
            end
        
    else 
        d.update("Bienvenue sur Korona RP\nBon jeu à vous!")
        Wait(3000)
        d.done()
    end
end)

RegisterCommand('ban', function(source, args)
    if source == 0 then 
        local id = args[1]
        local uid = UID:getUIDfromID(id)
        local license = GetPlayerIdentifierByType(id, 'license')
        local staffName = 'CONSOLE'
        local type = 'ban'
        local raison = table.concat(args, " ", 3)
        local temps = args[2]
        local newTemps = ParseTime(temps)
        if newTemps > 0 then 
            newTemps = os.time() + newTemps
        end
        local date = os.date("%d")..'/'..os.date("%m")..'/'..os.date("%Y")..' à '..os.date("%H")..'h'..os.date("%M")..' et '..os.date("%S")..' secondes'
        DropPlayer(id, 'Vous avez été banni de Korona RP pour : '..raison..'\nDurée : '..temps..'\nAuteur : '..staffName)
        MySQL.insert('INSERT INTO `korona_sanctions` (license, uid, staff, type, raison, date, duree) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            license, uid, staffName, type, raison, date, newTemps 
        }, function(id)
        end)
    else 
        print('Cette commande ne peut s\'éxecuter qu\'avec la console.')
    end
end)

RegisterCommand('unban', function(source, args)
    if source == 0 then 
        local uid = args[1]
        if uid ~= nil then 
            local result = MySQL.query.await('SELECT * FROM korona_sanctions WHERE uid = @uid', {
                ['@uid'] = uid
            })
            for i=1, #result do 
                local row = result[i]
                --print(row.type)
                if row.type == 'ban' then 
                    MySQL.update('DELETE FROM `korona_sanctions` WHERE uid = ?', {uid})
                    print('La personne a été unban.')
                else 
                    print('Cette personne n\'est pas ban !')
                end
            end
        else 
            print('Syntaxe : /unban [UID]')
        end
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        local uid = args[1]
        if uid ~= nil then 
            local result = MySQL.query.await('SELECT * FROM korona_sanctions WHERE uid = @uid', {
                ['@uid'] = uid
            })
            for i=1, #result do 
                local row = result[i]
                if row.type == 'ban' then 
                    MySQL.update('DELETE FROM `korona_sanctions` WHERE uid = ?', {uid})
                    xPlayer.showNotification('La personne a été unban.')
                else 
                    xPlayer.showNotification('Cette personne n\'est pas ban !')
                end
            end
        else 
            xPlayer.showNotification('Syntaxe : /unban [UID]')
        end
    end
end)

RegisterCommand('unjail', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local uid = args[1]
    local id = UID:getIDfromUIDnew(uid)
    local staffName = GetPlayerName(source)
    if uid ~= nil then 
        local result = MySQL.query.await('SELECT * FROM korona_sanctions WHERE uid = @uid', {
            ['@uid'] = uid
        })
        for i=1, #result do 
            local row = result[i]
            if row.type == 'jail' then 
                MySQL.update('DELETE FROM `korona_sanctions` WHERE uid = ?', {uid})
                TriggerClientEvent("korona:unjailClient", id, staffName)
                xPlayer.showNotification('La personne a été unjail.')
            else 
                xPlayer.showNotification('Cette personne n\'est pas jail !')
            end
        end
    else 
        xPlayer.showNotification('Syntaxe : /unjail [UID]')
    end
end)

RegisterCommand('banoffline', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local license = 0
    local uid = args[1]
    local staffName = GetPlayerName(source)
    local type = 'ban'
    local temps = args[2]
    local raison = table.concat(args, " ", 3)
    local newTemps = ParseTime(temps)
    if newTemps > 0 then
        newTemps = os.time() + newTemps
    end 
    local date = os.date("%d")..'/'..os.date("%m")..'/'..os.date("%Y")..' à '..os.date("%H")..'h'..os.date("%M")..' et '..os.date("%S")..' secondes'
    MySQL.insert('INSERT INTO `korona_sanctions` (license, uid, staff, type, raison, date, duree) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        license, uid, staffName, type, raison, date, newTemps 
    }, function(id)
    end)
    xPlayer.showNotification('La personne a été banni pour : '..raison..'\nDurée : '..temps)
end)

function getBanTime(uid)
    local v = MySQL.query.await('SELECT * FROM korona_sanctions WHERE uid = @uid', {
        ['@uid'] = uid
    })
    if not v then 
        return 'Inconnue'
    end
    if #v > 0 then
        for i=1, #v do 
            local row = v[i]
            if row.type == 'ban' then 
                if tonumber(row.duree) == 0 then 
                    return 'Permanent'
                else 
                    local remainingTime = tonumber(row.duree) - os.time()
            
                    local remainingDays = math.floor(remainingTime / (24 * 60 * 60))
                    local remainingHours = math.floor((remainingTime % (24 * 60 * 60)) / (60 * 60))
                    local remainingMinutes = math.floor((remainingTime % (60 * 60)) / 60)
                    local remainingSeconds = remainingTime % 60
            
                    local timeString = ''
                        
                    if remainingDays > 0 then
                        timeString = timeString .. remainingDays .. ' jour(s) '
                    
                        if remainingHours > 0 then
                            timeString = timeString .. remainingHours .. ' heure(s) '
                        end
                    else
                        if remainingHours > 0 then
                            timeString = timeString .. remainingHours .. ' heure(s) '
            
                            if remainingMinutes > 0 then
                                timeString = timeString .. remainingMinutes .. ' minute(s) '
                            end
                        else
                            if remainingMinutes > 0 then
                                timeString = timeString .. remainingMinutes .. ' minute(s) '
            
                                if remainingSeconds > 0 then
                                    timeString = timeString .. remainingSeconds .. ' seconde(s) '
                                end
                            else
                                if remainingSeconds > 0 then
                                    timeString = timeString .. remainingSeconds .. ' seconde(s) '
                                end
                            end
                        end
                    end
            
                    return timeString
                end 
            else 
                return 'Inconnue'
            end
        end
    end
    
end