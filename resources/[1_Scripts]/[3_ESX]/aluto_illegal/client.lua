ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

local leaves = {}
local isWashing = false

function washLeaves(nbToWash)
	print("Lavage des graines/feuilles en cours... " .. nbToWash)

	TriggerServerEvent("illégal:washLeaves", nbToWash)
	exports.rprogress:Start("Traitement en cours...", nbToWash * 3000)
	isWashing = true
end

RegisterNetEvent("illégal:stopWash")
AddEventHandler("illégal:stopWash", function()
	isWashing = false
end)

--[[local pnjTraitement = interact.addModel("s_m_y_dealer_01", {
	label = "Intéragir",
	icon = "hand",
	distance = 2.0,
	holdTime = 1000,
	onSelect = function(data)
		ESX.TriggerServerCallback("illégal:getPochtars", function(cb)
			if cb ~= nil then
				table.insert(pochtars, cb)
				print(cb)
			end
		end)
		openTraitement()
	end,
	canInteract = function(entity, distance, coords, name)
		return distance < 2.0
	end,
})]]

local pointLavage = interact.addCoords(vec3(92.808792, 3754.602295, 40.754639), {
	label = "Intéragir",
	icon = "hand",
	distance = 2.0,
	holdTime = 1000,
	onSelect = function(data)
		openTraitement()
	end,
	canInteract = function(entity, distance, coords, name)
		return distance < 2.0
	end,
})

openTraitement = function()
	local mainMenu = RageUI.CreateMenu("MENU TRAITEMENT", "Menu Traitement")
	mainMenu.EnableMouse = false

	local washMenu = RageUI.CreateSubMenu(mainMenu, "MENU LAVAGE", "Menu Lavage")

	mainMenu.Closed = function()
		leaves = {}
	end

	washMenu.Closed = function()
		leaves = {}
	end

	RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
	while mainMenu do
		Wait(0)
		RageUI.IsVisible(mainMenu, function()
			RageUI.Button("Laver des graines/feuilles", nil, {}, true, {
				onSelected = function()
					ESX.TriggerServerCallback("illégal:getLeaves", function(cb)
						if cb ~= nil then
							table.insert(leaves, cb)
							--print(cb)
						end
					end)
				end,
			}, washMenu)
		end, function() end)

		RageUI.IsVisible(washMenu, function()
			if #leaves > 0 then
				for i, v in pairs(leaves) do
					if v.count > 0 then
						RageUI.Button(
							"Graines/Feuilles : " .. v.count,
							"Type : ~g~" .. v.label .. "~s~\nTemps de lavage : ~r~3s~s~",
							{},
							true,
							{
								onSelected = function()
									local nbToWash = KeyboardInput(
										"Lavage",
										"Combien de graines/feuilles voulez-vous laver ?",
										"",
										3
									)
									if nbToWash ~= nil then
										nbToWash = tonumber(nbToWash)
										if nbToWash > v.count then
											ESX.ShowNotification(
												"~r~Vous n'avez pas assez de graines/feuilles sur vous !"
											)
										elseif nbToWash <= 0 then
											ESX.ShowNotification("~r~Veuillez entrer un nombre valide !")
										elseif nbToWash == nil then
											ESX.ShowNotification("~r~Veuillez entrer un nombre valide !")
										else
											if not isWashing then
												washLeaves(nbToWash)
											else
												ESX.ShowNotification("~r~Vous ne pouvez pas effectuer cette action.")
											end
										end
									else
										ESX.ShowNotification("~r~Vous n'avez pas entré de nombre !")
									end
									RageUI.CloseAll()
									leaves = {}
								end,
							}
						)
					else
						RageUI.Separator("~r~Vous n'avez pas de graines/feuilles sur vous !")
					end
				end
			else
				RageUI.Separator("~r~Vous n'avez pas de graines/feuilles sur vous !")
			end
		end, function() end)
	end
end

function KeyboardInput(entryTitle, textEntry, inputText, maxLength)
	local result = nil

	exports["putin-dialog"]:showDialog(
		entryTitle,
		textEntry,
		inputText,
		maxLength,
		helpText or "",
		function(submittedInput)
			result = submittedInput
		end,
		function()
			result = nil
		end,
		false,
		false
	)

	while result == nil do
		Citizen.Wait(100)
	end

	return result
end
