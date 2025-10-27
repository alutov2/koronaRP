ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

ESX.RegisterServerCallback("illégal:getPochtars", function(src, cb)
	local xPlayer = ESX.GetPlayerFromId(src)
	local poch = xPlayer.getInventoryItem("weed_poch")
	cb(poch)
end)

ESX.RegisterServerCallback("illégal:getLeaves", function(src, cb)
	local xPlayer = ESX.GetPlayerFromId(src)
	local leaves = xPlayer.getInventoryItem("weed_leave")
	cb(leaves)
end)

ESX.RegisterUsableItem("weed_poch", function(source)
	print("utilisation poch")
end)

ESX.RegisterUsableItem("weed_leave", function(source)
	print("utilisation feuille")
end)

RegisterServerEvent("illégal:washLeaves")
AddEventHandler("illégal:washLeaves", function(nbToWash)
	local xPlayer = ESX.GetPlayerFromId(source)
	local leaves = xPlayer.getInventoryItem("weed_leave").count
	if leaves >= nbToWash then
		for i = 1, nbToWash do
			Citizen.Wait(3000)
			xPlayer.removeInventoryItem("weed_leave", 1)
			xPlayer.addInventoryItem("weed_leave_clean", 1)
			xPlayer.showNotification("1 feuille lavée.")
		end
		xPlayer.showNotification("Vos ~g~" .. nbToWash .. "~s~ feuilles ont été ~g~lavées~s~ !")
		TriggerClientEvent("illégal:stopWash", source)
	else
		xPlayer.showNotification("~r~Vous n'avez pas assez de feuilles sur vous !")
	end
end)
