ESX = nil

ESX = exports["es_extended"]:getSharedObject()

local count = 0
local codeBoutique = ''
local identifiersCodeBoutique = {}
local codesLoaded = false

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM boutique_code', {}, function(results)
		for k, v in pairs(results) do
            identifiersCodeBoutique[v.license] = v.code
        end

        print('^0[^2!^0] ^2server.lua ^0=> La base de données a chargé ^3' .. #results .. ' ^0code boutique.')
        codesLoaded = true
    end)
end)

function createNewCodeBoutique()
    codeBoutique = ''
    local characters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
    for i = 1,4 do 
        codeBoutique = codeBoutique..characters[math.random(1, #characters)] 
    end
    for i = 1, 3 do
        codeBoutique = codeBoutique .. math.random(1, 9)
    end
    return codeBoutique
end

RegisterServerEvent('korona:boutique:checkoutCaisse')
AddEventHandler('korona:boutique:checkoutCaisse', function(uid, name, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addInventoryItem(name, 1)
    xPlayer.showNotification('Vous avez acheté une '..name, true)
    --print('été')
end)

function getRandomReward(caisse)
    local rewards = rewardsCaisses[caisse]
    local totalWeight = 0
    local weightedRewards = {}

    -- Construire les poids
    for _, reward in ipairs(rewards) do
        local weight = 11 - reward.rarity -- Rareté 10 = 1 chance, Rareté 1 = 10 chances
        totalWeight = totalWeight + weight
        table.insert(weightedRewards, {
            reward = reward,
            weight = weight
        })
    end

    -- Tirage aléatoire
    local rand = math.random(1, totalWeight)
    local current = 0
    for _, item in ipairs(weightedRewards) do
        current = current + item.weight
        if rand <= current then
            return item.reward
        end
    end
end


ESX.RegisterUsableItem('caisse_ete', function(source)
    local reward = getRandomReward('caisse_ete')
    local xPlayer = ESX.GetPlayerFromId(source)
    local license = GetPlayerIdentifierByType(source, 'license')

    xPlayer.removeInventoryItem('caisse_ete', 1)

    if reward.type == 'money' then
        xPlayer.addMoney(reward.model)
    elseif reward.type == 'vehicle' then
        
    elseif reward.type == 'coins' then
        giveCoins(license, reward.model)
    elseif reward.type == 'weapon' then
        -- Donner l'arme
    end

    print(("Tu as gagné : %s (%s)"):format(reward.type, reward.model))

end)

function checkIfCodeExists(code)
    local codeExists = false
    MySQL.Async.fetchAll('SELECT * FROM boutique_code', {}, function(results)
        for k, v in pairs(results) do
            if v.code == code then 
                codeExists = true
            else
                codeExists = false
            end
        end
    end)
    return codeExists
end

function giveCoins(license, coins)
    local date = os.date("%d")..'/'..os.date("%m")..'/'..os.date("%Y")..' à '..os.date("%H")..'h'..os.date("%M")..' et '..os.date("%S")..' secondes'
    MySQL.Async.execute('INSERT INTO boutique_wallet (license, code, coins, date) VALUES (@license, @code, @coins, @date)', {
        ['@license'] = license,
        ['@code'] = identifiersCodeBoutique[license],
        ['@coins'] = coins,
        ['@date'] = date
    })
end

function retrieveCoins(code, cb)
    MySQL.scalar('SELECT SUM(coins) as total FROM boutique_wallet WHERE code = ?', {code}, function(total)
        total = total or 0
        --print('Le joueur a un total de : ' .. total .. ' coins.')
        cb(total)
    end)
end

RegisterNetEvent('BoutiqueBucket:SetEntitySourceBucket')
AddEventHandler('BoutiqueBucket:SetEntitySourceBucket', function(valeur)
    if valeur then
        SetPlayerRoutingBucket(source, source+1)
    else
        SetPlayerRoutingBucket(source, 0)
   end
end)

AddEventHandler('esx:playerLoaded', function(player, xPlayer, isNew)
    local hasCode = false
    local license = GetPlayerIdentifierByType(player, 'license')
    if not identifiersCodeBoutique[license] then 
        --print('no code')
        identifiersCodeBoutique[license] = createNewCodeBoutique()
        local codeExists = checkIfCodeExists(identifiersCodeBoutique[license])
        if not codeExists then 
            MySQL.Async.execute('INSERT INTO boutique_code (license, code) VALUES (@license, @code)', {
                ['@license'] = license,
                ['@code'] = identifiersCodeBoutique[license],
            })
            print('created code '..identifiersCodeBoutique[license])
        else 
            identifiersCodeBoutique[license] = createNewCodeBoutique()
            codeExists = checkIfCodeExists(identifiersCodeBoutique[license])
            if not codeExists then 
                MySQL.Async.execute('INSERT INTO boutique_code (license, code) VALUES (@license, @code)', {
                    ['@license'] = license,
                    ['@code'] = identifiersCodeBoutique[license],
                })
            else 
                identifiersCodeBoutique[license] = createNewCodeBoutique()
                codeExists = checkIfCodeExists(identifiersCodeBoutique[license])
                if not codeExists then 
                    MySQL.Async.execute('INSERT INTO boutique_code (license, code) VALUES (@license, @code)', {
                        ['@license'] = license,
                        ['@code'] = identifiersCodeBoutique[license],
                    })
                else 
                    DropPlayer(player, 'Erreur lors du chargement de votre code boutique, veuillez contactez le support (discord.gg/koronarp).\nCode erreur : 1165.')
                end
            end
        end
    else 
        --print('deja code')
    end
end)

RegisterCommand('givecoins', function(source, args)
    if source ~= 0 then
        local sPlayer = ESX.GetPlayerFromId(source)
        if sPlayer.getGroup() == 'owner' then 
            local xUID = args[1]
            local coinsToGive = args[2]
            local xID = exports["aluto_admin"]:getIDfromUIDnew(xUID)
            if xID ~= nil then
                local license = GetPlayerIdentifierByType(xID, 'license')
                giveCoins(license, coinsToGive)
                sPlayer.showNotification('Le joueur avec l\'uid '..xUID..' a reçu '..coinsToGive..' coin(s) avec succès !')
            else
                local license = exports['aluto_admin']:getIdentifierfromUID(xUID)
                giveCoins(license, coinsToGive)
                sPlayer.showNotification('Le joueur avec l\'uid '..xUID..' a reçu '..coinsToGive..' coin(s) avec succès !')
            end
        else 
            sPlayer.showNotification('NON')
        end
    elseif source == 0 then 
        local xUID = args[1]
        local coinsToGive = args[2]
        local xID = exports["aluto_admin"]:getIDfromUIDnew(xUID)
        if xID ~= nil then
            local license = GetPlayerIdentifierByType(xID, 'license')
            giveCoins(license, coinsToGive)
            print('Le joueur avec l\'uid '..xUID..' a reçu '..coinsToGive..' coin(s) avec succès !')
        else 
            local license = exports['aluto_admin']:getIdentifierfromUID(xUID)
            giveCoins(license, coinsToGive)
            print('Le joueur avec l\'uid '..xUID..' a reçu '..coinsToGive..' coin(s) avec succès !')
        end
    end
end)

ESX.RegisterServerCallback('korona:getCodeBoutique', function(source, cb)
    local license = GetPlayerIdentifierByType(source, 'license')
    cb(identifiersCodeBoutique[license])
end)

ESX.RegisterServerCallback('korona:retrieveCoins', function(source, cb)
    local license = GetPlayerIdentifierByType(source, 'license')
    local code = identifiersCodeBoutique[license]
    retrieveCoins(code, function(coins)
        cb(coins)
        --print('Résultat reçu depuis le callback : ' .. coins)
    end)
end)

RegisterServerEvent('boutique:buyVehicle')
AddEventHandler('boutique:buyVehicle', function(plate, vehicle, type)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local owner = xPlayer.getIdentifier()
    local vehProps = json.encode(vehicle)

    MySQL.Async.fetchAll('SELECT `vehicle` FROM owned_vehicles WHERE owner = @owner', {
        ['@owner'] = owner
    }, function(results)
        local alreadyOwned = false

        for _, v in ipairs(results) do
            local dbVeh = json.decode(v.vehicle)
            if dbVeh and dbVeh.model == vehicle.model then
                alreadyOwned = true
                break
            end
        end

        if not alreadyOwned then
            MySQL.insert('INSERT INTO `owned_vehicles` (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)', {
                owner, plate, vehProps, type, true
            }, function(id)
                print('Véhicule acheté. ID: ' .. tostring(id))
            end)
        else
            print('Véhicule déjà acquis')
        end
    end)
end)


ESX.RegisterServerCallback('boutique:isPlateTaken', function(source, cb, plate)
	MySQL.scalar('SELECT plate FROM owned_vehicles WHERE plate = ?', {plate},
	function(result)
		cb(result ~= nil)
	end)
end)