Framework = {}

function Framework:GetPlayerBankMoney(source)
    local xPlayer = Framework:GetPlayer(source)
    if shared.Framework == "qb" then
        return xPlayer.PlayerData.money.bank
    elseif shared.Framework == "esx" then
        return xPlayer.getAccount('bank').money
    else
        return 0
    end
end

function Framework:GetPlayerMoney(source)
    local xPlayer = Framework:GetPlayer(source)
    if shared.Framework == "qb" then
        return xPlayer.PlayerData.money.cash
    elseif shared.Framework == "esx" then
        return xPlayer.getMoney()
    else
        return 0
    end
end

function Framework:AddMoney(source, type, amount)
    amount = tonumber(amount)
    if shared.Framework == "qb" then
        local player = FrameworkObject.Functions.GetPlayer(source)
        if type == "bank" then
                player.Functions.AddMoney("bank", amount)
        elseif type == "cash" then
                player.Functions.AddMoney("cash", amount)
        end
    elseif shared.Framework == "esx" then
        local xPlayer = FrameworkObject.GetPlayerFromId(source)
        if type == "bank" then
            xPlayer.addAccountMoney("bank", amount)
        elseif type == "cash" then
                xPlayer.addMoney(amount)
        end
    end
end

function Framework:GetPlayer(source)
    if shared.Framework == "qb" then
        return FrameworkObject.Functions.GetPlayer(source)
    elseif shared.Framework == "esx" then
        return FrameworkObject.GetPlayerFromId(source)
    else
        return false
    end
end

function Framework:GetPlayerIdentifier(player)
    if player == nil then
        return false
    end
    if shared.Framework == "qb" then
        local identifier = player?.PlayerData?.citizenid
        if identifier == nil then
            return false
        end
        return identifier
    elseif shared.Framework == "esx" then
        return player.getIdentifier()
    else
        return false
    end
end

function Framework:Notify(source, message, tipim)
    if shared.debug then
        print("Server notify", source, message, tip)
    end
    TriggerClientEvent('savana-busjob:client:sendNotifys', source, message, tipim)
end