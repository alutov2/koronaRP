ESX = exports["es_extended"]:getSharedObject()
local staffActive = {}
local undercoverMode = {}

RegisterServerEvent("korona:updateStaffMode")
AddEventHandler("korona:updateStaffMode", function(bool)
	local xPlayer = ESX.GetPlayerFromId(source)

	if bool == true then
		staffActive[source] = {
			rankLabel = xPlayer.getGroup(),
			--rankColor = eeee
		}
	end
end)

ESX.RegisterServerCallback("korona:getGroup", function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local group = xPlayer.getGroup()
	if group == nil then
		Wait(1000)
		group = xPlayer.getGroup()
	end
	cb(group)
end)

ESX.RegisterServerCallback("korona:checkAccess", function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local group = xPlayer.getGroup()
	if group ~= user then
		cb(true)
	end
end)

ESX.RegisterServerCallback("korona:checkPlayers", function(source, cb)
	local playerCount = 0
	for _, playerId in ipairs(GetPlayers()) do
		playerCount = playerCount + 1
	end
	cb = playerCount
end)

ESX.RegisterServerCallback("korona:getUIDfromID", function(source, cb, id)
	local UID = UID:getUIDfromID(id)
	cb(UID)
end)

RegisterServerEvent("korona:messageServerSide")
AddEventHandler("korona:messageServerSide", function(id, title, message)
	TriggerClientEvent("korona:displayWarnOnScreen", id, title, message)
end)

ESX.RegisterServerCallback("korona:getPlayerMoneyInfo", function(source, cb, type, id)
	local xPlayer = ESX.GetPlayerFromId(id)
	if type == "money" then
		local cash = xPlayer.getAccount("money").money
		cb(cash)
	elseif type == "bank" then
		local bank = xPlayer.getAccount("bank").money
		cb(bank)
	elseif type == "sale" then
		local sale = xPlayer.getAccount("black_money").money
		cb(sale)
	elseif type == "all" then
		local cash = xPlayer.getAccount("money").money
		local bank = xPlayer.getAccount("bank").money
		local sale = xPlayer.getAccount("black_money").money
		cb({ cash = cash, bank = bank, sale = sale })
	end
end)

ESX.RegisterServerCallback("korona:getPlayerInventoryInfo", function(source, cb, id)
	local xPlayer = ESX.GetPlayerFromId(id)
	local inventory = xPlayer.getInventory()
	local inventorytable = {}
	for i = 1, #inventory do
		if inventory[i].count > 0 then
			table.insert(inventorytable, {
				name = inventory[i].name,
				count = inventory[i].count,
				label = inventory[i].label,
			})
		end
	end
	cb(inventorytable)
end)

ESX.RegisterServerCallback("korona:getPlayerLoadoutInfo", function(source, cb, id)
	local xPlayer = ESX.GetPlayerFromId(id)
	local armes = xPlayer.getLoadout()
	local armestable = {}
	for i = 1, #armes do
		--if armes[i].count > 0 then
		table.insert(armestable, {
			name = armes[i].name,
			ammo = armes[i].ammo,
			label = armes[i].label,
		})
		--end
	end
	--print(armestable)
	cb(armestable)
end)

RegisterServerEvent("korona:getPlayersList")
AddEventHandler("korona:getPlayersList", function()
	sendInfosToStaff(source)
	--print(source)
end)

RegisterServerEvent("korona:screenShotPlayer")
AddEventHandler("korona:screenShotPlayer", function(playerId)
	TriggerClientEvent("korona:screenShotPlayerClient", playerId)
	--print('executed client event')
end)

RegisterServerEvent("korona:updateUndercoverStatus")
AddEventHandler("korona:updateUndercoverStatus", function(status)
	local src = source
	undercoverMode[src] = status
end)

local players = {}

function sendInfosToStaff(targetId)
	local xPlayers = ESX.GetPlayers()
	local cacheplayers = players
	local playerCount, staffCount = 0, 0

	for i = 1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if xPlayer then
			local afk = false
			local playerCoords = GetEntityCoords(GetPlayerPed(xPlayer.source))

			if xPlayer.getGroup() ~= "user" then
				if xPlayer.getGroup() == "modo" then
					rankColor = 26
					rankLabelColor = "~b~"
				elseif xPlayer.getGroup() == "admin" then
					rankColor = 18
					rankLabelColor = "~g~"
				elseif xPlayer.getGroup() == "superadmin" then
					rankColor = 49
					rankLabelColor = "~p~"
				elseif xPlayer.getGroup() == "responsable" then
					rankColor = 148
					rankLabelColor = "~o~"
				elseif xPlayer.getGroup() == "owner" then
					rankColor = 63
					rankLabelColor = "~l~"
				end
				local staffmode = false
				local npd = false
				local shadow = false
				if staffActive[xPlayer.source] then
					staffmode = true
				end

				players[xPlayer.source] = {
					uid = UID:getUIDfromID(xPlayer.source),
					rankName = xPlayer.getGroup(),
					rankLabelColor = rankLabelColor,
					rankColor = rankColor,
					--rankPower = RanksList[PlayersRanks[YveltHelper:getIdentifier(xPlayer.source)].rank].power,
					source = xPlayer.source,
					job1 = xPlayer.getJob().label,
					--job2 = YveltHelper:getJob2(xPlayer.source).label,
					name = GetPlayerName(xPlayer.source),
					--lastMove = move,
					--lastCoords = coords,
					--isAfk = afk,
					staffmode = staffmode,
					--npd = npd,
					--shadow = shadow,
					undercoverMode = undercoverMode[source],
				}

				staffCount = staffCount + 1
			else
				--print('player')
				players[xPlayer.source] = {
					uid = UID:getUIDfromID(xPlayer.source),
					rankName = "user",
					rankLabelColor = "~s~",
					rankColor = 0,
					--rankPower = RanksList[PlayersRanks[YveltHelper:getIdentifier(xPlayer.source)].rank].power,
					source = xPlayer.source,
					job1 = xPlayer.getJob().label,
					--job2 = YveltHelper:getJob2(xPlayer.source).label,
					name = GetPlayerName(xPlayer.source),
					--lastMove = move,
					--lastCoords = coords,
					--isAfk = afk,
					staffmode = false,
					--npd = npd,
					--shadow = shadow,
				}
			end
			playerCount = playerCount + 1
		end
	end

	TriggerClientEvent("korona:receiveInfos", targetId, players, playerCount, staffCount)
end

AddEventHandler("playerDropped", function(reason)
	local source = source
	if players[source] then
		players[source] = nil
	end
end)

RegisterCommand("jail", function(source, args)
	local uid = args[1]
	local id = UID:getIDfromUIDnew(uid)
	local temps = args[2]
	local raison = table.concat(args, " ", 3)
	local staffName = "CONSOLE."
	if source == 0 then
		staffName = GetPlayerName(source)
	end
	TriggerEvent("korona:punishPlayer", "jail", id, temps, raison)
end)

RegisterNetEvent("korona:changeTimeForAll")
AddEventHandler("korona:changeTimeForAll", function(hour, minute)
	TriggerClientEvent("korona:setTime", -1, hour, minute)
end)

RegisterNetEvent("korona:changeWeatherForAll")
AddEventHandler("korona:changeWeatherForAll", function(meteo)
	TriggerClientEvent("korona:setweather", -1, meteo)
end)

RegisterNetEvent("korona:putUnderSurveillance")
AddEventHandler("korona:putUnderSurveillance", function(uid, raison)
	MySQL.Async.execute("INSERT INTO korona_surveillance (uid, raison) VALUES (@uid, @raison)", {
		["@uid"] = uid,
		["@raison"] = raison,
	})
	--print("etetetet")
end)

AddEventHandler("esx:playerLoaded", function(source)
	local uid = UID:getUIDfromID(source)
	MySQL.Async.fetchAll("SELECT * FROM korona_surveillance WHERE uid = @uid", {
		["@uid"] = uid,
	}, function(result)
		if result[1] ~= nil then
			local raison = result[1].raison
			for k, v in pairs(GetPlayers()) do
				local xPlayer = ESX.GetPlayerFromId(v)
				if xPlayer.getGroup() ~= "user" then
					TriggerClientEvent(
						"korona:displayWarnOnScreen",
						v,
						"Surveillance",
						"Le joueur avec l'uid " .. uid .. " s'est reconnecté. Raison : " .. raison
					)
					MySQL.Async.execute("DELETE FROM korona_surveillance WHERE uid = @uid", {
						["@uid"] = uid,
					})
				end
			end
		end
	end)
end)
