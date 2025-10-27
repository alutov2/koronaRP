ESX = exports["es_extended"]:getSharedObject()

ESX.RegisterServerCallback('dynastyHUD:getPlayerMoney', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local moneyData = {
            cash = xPlayer.getMoney(),
            bank = xPlayer.getAccount('bank').money,
            dirty = xPlayer.getAccount('black_money').money
        }
        cb(moneyData)
    else
        cb({ cash = 0, bank = 0, dirty = 0 })
    end
end)

-- discord.gg/flashdev