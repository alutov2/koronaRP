ESX = exports["es_extended"]:getSharedObject()

local coffres = {}

RegisterServerEvent("coffre:depositMoney")
AddEventHandler("coffre:depositMoney", function(job, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            account.addMoney(amount)
        end)
    end
end)

RegisterServerEvent("coffre:withdrawMoney")
AddEventHandler("coffre:withdrawMoney", function(job, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
        if account.money >= amount then
            account.removeMoney(amount)
            xPlayer.addMoney(amount)
        end
    end)
end)

RegisterServerEvent("coffre:depositBlackMoney")
AddEventHandler("coffre:depositBlackMoney", function(job, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local account = xPlayer.getAccount('black_money')
    if account.money >= amount then
        xPlayer.removeAccountMoney('black_money', amount)
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job..'_black', function(account)
            account.addMoney(amount)
        end)
    end
end)

RegisterServerEvent("coffre:withdrawBlackMoney")
AddEventHandler("coffre:withdrawBlackMoney", function(job, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job..'_black', function(account)
        if account.money >= amount then
            account.removeMoney(amount)
            xPlayer.addAccountMoney('black_money', amount)
        end
    end)
end)

RegisterServerEvent("coffre:depositItem")
AddEventHandler("coffre:depositItem", function(job, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    local item = xPlayer.getInventoryItem(itemName)
    if item.count >= count then
        xPlayer.removeInventoryItem(itemName, count)
        TriggerEvent('esx_addoninventory:getSharedInventory', 'society_'..job, function(inv)
            inv.addItem(itemName, count)
        end)
    end
end)

RegisterServerEvent("coffre:withdrawItem")
AddEventHandler("coffre:withdrawItem", function(job, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)


    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_'..job, function(inv)
        local item = inv.getItem(itemName)

        if not item or item.count < count then
            print("Erreur : Pas assez d'items dans le coffre")
            return
        end


        inv.removeItem(itemName, count)

        xPlayer.addInventoryItem(itemName, count)
        print("Item retiré du coffre et ajouté à l'inventaire du joueur")
    end)
end)




ESX.RegisterServerCallback("coffre:getInventory", function(source, cb, job)
    if not job then
        print("Erreur : job est nil")
        return cb(nil)
    end

    local xPlayer = ESX.GetPlayerFromId(source)

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
        if not account then return cb(nil) end

        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job..'_black', function(accountBlack)
            if not accountBlack then
                accountBlack = {money = 0}
            end

            TriggerEvent('esx_addoninventory:getSharedInventory', 'society_'..job, function(inv)
                cb({
                    account = account.money,
                    blackMoney = accountBlack.money,
                    items = inv.items
                })
            end)
        end)
    end)
end)


ESX.RegisterServerCallback("coffre:getPlayerInventory", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb({ items = xPlayer.inventory })
end)
