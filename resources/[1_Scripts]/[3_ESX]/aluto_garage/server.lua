ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

ESX.RegisterServerCallback('garage:getVehicles', function(source, cb)
    local ownedCars =  {}
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND type = @type AND `stored` = @stored', {
        ['@owner'] = xPlayer.identifier,
        ['@type'] = 'car',
        ['@stored'] = true
    }, function(data)
        for k, v in pairs(data) do
            local vehicle = json.decode(v.vehicle)
            table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate})
        end
        cb(ownedCars)
    end)
end)

ESX.RegisterServerCallback('garage:checkVehicleOwner', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate AND `stored` = @stored', {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = plate,
        ['@stored'] = false
    }, function(data)
        if json.encode(data) == '[]' then 
            cb(false)
        else 
            cb(true)
        end
    end)
end)

ESX.RegisterServerCallback('garage:getDamage', function(source, cb, plate)
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


RegisterServerEvent('garage:changeStoredState')
AddEventHandler('garage:changeStoredState', function(plate, status)
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

RegisterServerEvent('garage:saveDamage')
AddEventHandler('garage:saveDamage', function(plate, damage)
    local src = source
    local jsonDamage = json.encode(damage)

    MySQL.Async.execute('UPDATE owned_vehicles SET `damage` = @damage WHERE plate = @plate', {
        ['@damage'] = jsonDamage,
        ['@plate'] = plate
    }, function(rowsChanged)
        if rowsChanged == 0 then
            print('Exploited garage state : '..src)
        end
    end)
end)
