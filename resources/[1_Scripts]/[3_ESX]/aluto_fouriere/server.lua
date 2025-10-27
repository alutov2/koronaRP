ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

ESX.RegisterServerCallback('fourriere:getVehicles', function(source, cb)
    local impoundCars =  {}
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type AND `stored` = @stored', {
        ['@owner'] = xPlayer.identifier,
        ['@type'] = 'car',
        ['@stored'] = false
    }, function(data)
        for k, v in pairs(data) do
            local vehicle = json.decode(v.vehicle)
            table.insert(impoundCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
        end
        cb(impoundCars)
    end)
end)

RegisterServerEvent('fourriere:retrieveImpoundMoney')
AddEventHandler('fourriere:retrieveImpoundMoney', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    xPlayer.removeAccountMoney('bank', 500)
end)

ESX.RegisterServerCallback('fourriere:getDamage', function(source, cb, plate)
    MySQL.Async.fetchScalar('SELECT `damage` FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result then
            local damage = json.decode(result)
            cb(damage)
        else
            cb(nil)
        end
    end)
end)


RegisterServerEvent('fourriere:changeStoredState')
AddEventHandler('fourriere:changeStoredState', function(plate, status)
    local src = source
    MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate', {
		['@stored'] = status,
		['@plate'] = plate
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print('Exploited garage state : '..src)
		end
	end)
end)