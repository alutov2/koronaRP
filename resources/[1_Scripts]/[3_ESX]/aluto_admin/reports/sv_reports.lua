ESX = exports["es_extended"]:getSharedObject()

Reports = {}
ReportsSessionId = 0
ReportsInfos = {
    Active = 0,
    Taked = 0,
    Finish = 0,
}

ESX.RegisterServerCallback('korona:getReportList', function(source)
    return {Reports}
end)

RegisterCommand('report', function(source, args)
    local _src = source 
    local argument = table.concat(args, ' ', 1)
    local xPlayer = ESX.GetPlayerFromId(_src)

    if _src == 0 then
        print(' ')
        print('Voici l\'état des reports actuellement :')
        print('Reports actif : '..ReportsInfos.Active)
        print('Reports en attente : '..ReportsInfos.Active - ReportsInfos.Taked.. '')
        print('Reports pris en charge : '..ReportsInfos.Taked)
        print('Reports terminé : '..ReportsInfos.Finish)
        print(' ')
    else
        if Reports[source] then
            xPlayer.showNotification('~r~Vous avez déjà un report actif')
            return
        else
            if argument == '' then
                xPlayer.showNotification('~r~Vous devez indiquer une raison')
                return
            end

            ReportsSessionId = ReportsSessionId + 1 

            local players = {}
            local xPlayers = ESX.GetPlayers()
            
                Reports[source] = {
                    date = os.date("%d")..'/'..os.date("%m")..'/'..os.date("%Y")..' à '..os.date("%H")..'h'..os.date("%M")..' et '..os.date("%S")..' secondes',
                    heure = os.date("%H")..'h'..os.date("%M")..' et '..os.date("%S")..' secondes',
                    uid = _src,
                    source = _src,
                    name = GetPlayerName(_src),
                    rank = 'Joueur',
                    --job1 = YveltHelper:getJob(xPlayer.source).name,
                    --job2 = YveltHelper:getJob2(xPlayer.source).name,
                    rankName = 'Joueur',
                    rankLabel = '[ Joueur ]',
                    rankColor = '~s~',
                    rankPower = 0,
                    raison = argument,
                    state = 'waiting',
                    takedBy = '?',
                    id = _src,
                }

            xPlayer.showNotification('~g~Votre report a été envoyé ! ')

            for i=1, #xPlayers, 1 do
                local xPlayerS = ESX.GetPlayerFromId(xPlayers[i])
                if xPlayerS then
                    local group = xPlayer.getGroup()
                    if group ~= user then
                        xPlayerS.showNotification('~g~Un nouveau report est arrivé !')
                        --YveltHelper:serverNotification(xPlayerS.source, '~g~Un report vient d\'arriver ('..ReportsSessionId..') !')
                        TriggerClientEvent('korona:ReceiveReportsList', xPlayerS.source, Reports)
                    end
                end
            end
        end
    end
end)

RegisterServerEvent('korona:updateReport')
AddEventHandler('korona:updateReport', function(action, s)
    local xPlayer = ESX.GetPlayerFromId(source)
    --if PlayersRanks[YveltHelper:getIdentifier(xPlayer.source)] then

        local players = {}
        local xPlayers = ESX.GetPlayers()

        if action == 'taked' then
            Reports[s.source].state = 'taked'
            Reports[s.source].takedBy = GetPlayerName(source)

            local sPlayer = ESX.GetPlayerFromId(Reports[s.source].source)
            sPlayer.showNotification("~g~Le staff "..GetPlayerName(source).." a pris votre report en charge !")

            for i=1, #xPlayers, 1 do
                local xPlayerS = ESX.GetPlayerFromId(xPlayers[i])
                if xPlayerS then
                    local group = xPlayer.getGroup()
                    if group ~= user then
                        --YveltHelper:serverNotification(xPlayerS.source, '~g~Le staff '..GetPlayerName(source)..' a pris le report n°'..s.id..' en charge !')
                        TriggerClientEvent('korona:ReceiveReportsList', xPlayerS.source, Reports)
                    end
                end
            end
        elseif action == 'finish' then
            local id = s.id

            local sPlayer = ESX.GetPlayerFromId(Reports[s.source].source)
            sPlayer.showNotification("~r~Le staff "..GetPlayerName(source).." a férmé votre report !")

            Reports[s.source] = nil
            for i=1, #xPlayers, 1 do
                local xPlayerS = ESX.GetPlayerFromId(xPlayers[i])
                if xPlayerS then
                    local group = xPlayer.getGroup()
                    if group ~= user then
                        --YveltHelper:serverNotification(xPlayerS.source, '~g~Le staff '..GetPlayerName(source)..' a pris le report n°'..s.id..' en charge !')
                        TriggerClientEvent('korona:ReceiveReportsList', xPlayerS.source, Reports)
                    end
                end
            end
            --[s.source].showNotification('~g~Report cloturé par '..GetPlayerName(source)..' !')
            --antiCheatAvis['id:'..s.source] = YveltHelper:getIdentifier(xPlayer.source)

            -- print('YveltHelper:getIdentifier(xPlayer.source)', YveltHelper:getIdentifier(xPlayer.source))
            -- print('antiCheatAvis[\'id:\'..source] : ', antiCheatAvis['id:'..source])
            -- print('xPlayer.source', xPlayer.source)
        else
            DropPlayer(source, "YveltShield : Tentative de triche (bypass trigger : \"Yvelt:updateReport\")")
        end
    --else
        --DropPlayer(source, "YveltShield : Tentative de triche (bypass trigger : \"Yvelt:updateReport\")")
    --end
end)