ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end

local adminModule = Modules.iAm("admin")

local ListIndex = 1

local GridX, GridY = 0, 0

local group = nil

staffMode = false
local gamertagsActive = false
local nbPlayers = 0
local nbStaff = 0
local rechercheJoueurIndex = 1
local tpIndex = 1
local savedCoords = 0
local reportIdSelected = 0
local tpReportGestionIndex = 2
local reportSelected = nil
local playerUID = 0
local cash = 0
local bank = 0
local sale = 0
local inventoryJoueur = {}
local armesJoueurTable = {}
local sanctionsList = {}
local sanctionsIndex = 1
local typeSanction = ""
local tempsSanction = 0
local raisonSanction = ""
local gamerTags = {}
local tpItems = { "Vers moi", "Dernière position", "Parking Central" }
local noclipActive = false
local jailIndex = 1
local banIndex = 1
local PlayersList = {}
local textVisible = false
local rankColor = ""
local clientGroup = "user"
local undercoverMode = false
local rechercheEcrit = nil
local serviceText = ""

ReportsInfos = {
	Waiting = 0,
	Taked = 0,
}

local AnnounceTime = 8

RegisterNetEvent("korona:displayWarnOnScreen")
AddEventHandler("korona:displayWarnOnScreen", function(title, msg)
	displayOnScreen(title, msg)
end)

RegisterNetEvent("korona:setTime")
AddEventHandler("korona:setTime", function(hour, minute)
	NetworkOverrideClockTime(hour, minute, 0)
end)

RegisterNetEvent("korona:setweather")
AddEventHandler("korona:setweather", function(meteo)
	SetOverrideWeather(meteo)
end)

RegisterNetEvent("korona:screenShotPlayerClient")
AddEventHandler("korona:screenShotPlayerClient", function()
	exports["screenshot-basic"]:requestScreenshotUpload(
		"https://canary.discord.com/api/webhooks/1357756005114712135/MWzdUrA6O7_9WbkImLm2RA20ssbBdq1bgis_zLXlXK7tTWj5_MXmVwZG46CSkpWEkrnd",
		"files[]",
		function(data) end
	)
end)

function displayOnScreen(title, msg)
	PlaySoundFrontend(-1, "DELETE", "HUD_DEATHMATCH_SOUNDSET", 1)

	local time = 0

	local function setcountdown(x)
		time = GetGameTimer() + x * 1000
	end
	local function getcountdown()
		return math.floor((time - GetGameTimer()) / 1000)
	end

	setcountdown(AnnounceTime)

	while getcountdown() > 0 do
		Citizen.Wait(1)
		local scaleform = Initialize("mp_big_message_freemode", title, msg)
		DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
	end
end

function Initialize(scaleform, title, msg)
	local scaleform = RequestScaleformMovie(scaleform)
	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(1)
	end
	PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
	PushScaleformMovieFunctionParameterString(title) -- Titre de l'annonce
	PushScaleformMovieFunctionParameterString(msg) -- Message de l'annonce
	PopScaleformMovieFunctionVoid()
	return scaleform
end

openMenuAdmin = function()
	local mainMenu = RageUI.CreateMenu("MENU ADMIN", "Menu Administratif")
	mainMenu.EnableMouse = false

	local menuJoueurs = RageUI.CreateSubMenu(mainMenu, "Joueurs", "Joueurs")
	local menuActions = RageUI.CreateSubMenu(mainMenu, "Actions Admin", "Actions Admin")
	local menuVehicules = RageUI.CreateSubMenu(mainMenu, "Véhicules", "Véhicules")
	local menuRanks = RageUI.CreateSubMenu(mainMenu, "Rangs", "Rangs")
	local menuReports = RageUI.CreateSubMenu(mainMenu, "Reports", "Reports")
	local menuServeur = RageUI.CreateSubMenu(mainMenu, "Serveur", "Serveur")

	menuGestionJ = RageUI.CreateSubMenu(menuJoueurs, "Gestion Joueur", "Gestion Joueur")
	local menuGestReport = RageUI.CreateSubMenu(menuReports, "Gestion Report", "Gestion Report")
	local infoJoueur = RageUI.CreateSubMenu(menuGestionJ, "Informations", "Informations")
	local argentJoueur = RageUI.CreateSubMenu(infoJoueur, "Argent Joueur", "Argent Joueur")
	local inventaireJoueur = RageUI.CreateSubMenu(infoJoueur, "Inventaire Joueur", "Inventaire Joueur")
	local armesJoueur = RageUI.CreateSubMenu(infoJoueur, "Armes Joueur", "Armes Joueur")
	local listeSanctionsJoueur =
		RageUI.CreateSubMenu(menuGestionJ, "Liste des Sanctions du Joueur", "Liste des Sanctions du Joueur")
	local sanctionsJoueur = RageUI.CreateSubMenu(menuGestionJ, "Sanctions", "Sanctions")
	local vehiculesActions = RageUI.CreateSubMenu(menuVehicules, "Véhicules Actions", "Véhicules Actions")
	local gestionTempsMeteo = RageUI.CreateSubMenu(menuServeur, "Gestion Temps/Meteo", "Gestion Temps/Meteo")

	mainMenu.closed = function()
		rechercheEcrit = nil
		rechercheJoueurIndex = 1
	end
	menuJoueurs.closed = function()
		rechercheEcrit = nil
		rechercheJoueurIndex = 1
	end
	menuGestionJ.closed = function()
		rechercheEcrit = nil
		rechercheJoueurIndex = 1
	end

	RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
	while mainMenu do
		Wait(0)
		RageUI.IsVisible(mainMenu, function()
			RageUI.Checkbox("Mode Administratif", "Activer le mode admin", staffMode, {}, {
				onChecked = function()
					staffMode = true
					TriggerServerEvent("korona:updateStaffMode", staffMode)
				end,
				onUnChecked = function()
					pistolStaffDeactivate()
					if noclipActive then
						koronaNoclip()
					end
					staffMode = false
					TriggerServerEvent("korona:updateStaffMode", staffMode)
				end,
				onSelected = function(Index)
					staffMode = Index
				end,
			})
			if staffMode then
				RageUI.Button("Joueurs en ligne", "Gestion des joueurs", { RightLabel = "→→→" }, true, {
					onSelected = function()
						TriggerServerEvent("korona:getPlayersList")
						Wait(100)
						--print("PlayersList:", json.encode(PlayersList))
					end,
				}, menuJoueurs)
				RageUI.Button(
					"Actions admin",
					"Actions administratives",
					{ RightLabel = "→→→" },
					true,
					{},
					menuActions
				)
				RageUI.Button(
					"Véhicules",
					"Gestion des véhicules",
					{ RightLabel = "→→→" },
					true,
					{},
					menuVehicules
				)
				--RageUI.Button("Rangs", "Gestion des rangs", {RightLabel = '→→→'}, true, {}, menuRanks)
				RageUI.Button("Reports", "Gestion des reports", { RightLabel = "→→→" }, true, {}, menuReports)
				if clientGroup == "owner" then
					RageUI.Button(
						"Gestion Serveur",
						"Gestion du serveur",
						{ RightLabel = "→→→" },
						true,
						{},
						menuServeur
					)
				end
				RageUI.Button(
					"Surveillance",
					"Mettre un joueur sous surveillance",
					{ RightLabel = "→→→" },
					true,
					{
						onSelected = function()
							local uid = KeyboardInput(
								"SURVEILLANCE",
								"Entrez l'uid du joueur a mettre sous surveillance",
								"",
								10
							)
							local raison = KeyboardInput("SURVEILLANCE", "Entrez la raison de la surveillance", "", 50)
							TriggerServerEvent("korona:putUnderSurveillance", uid, raison)
						end,
					}
				)
			end
		end, function() end)

		RageUI.IsVisible(menuJoueurs, function()
			RageUI.List("Rechercher un joueur", { "ID/UID", "Pseudo" }, rechercheJoueurIndex, nil, {}, true, {
				onListChange = function(Index)
					rechercheJoueurIndex = Index
				end,
				onSelected = function()
					if rechercheJoueurIndex == 1 then
						rechercheEcrit = KeyboardInput(
							"RECHERCHE PAR ID/UID",
							"Entrez l'ID/UID du joueur que vous souhaitez rechercher",
							"",
							50
						)
						if rechercheEcrit == nil then
							ESX.ShowNotification("~r~La recherche a été annulée!")
						end
					elseif rechercheJoueurIndex == 2 then
						rechercheEcrit = KeyboardInput(
							"RECHERCHE PAR PSEUDO",
							"Entrez le pseudo du joueur que vous souhaitez rechercher",
							"",
							50
						)
						if rechercheEcrit == nil then
							ESX.ShowNotification("~r~La recherche a été annulée!")
						end
					end
					if rechercheEcrit ~= nil then
						--print(rechercheEcrit)
					end
				end,
			})

			RageUI.Separator("~g~Joueurs en ligne : ~s~" .. nbPlayers .. " | ~g~Staff en ligne : ~s~" .. nbStaff)

			for k, v in pairs(PlayersList) do
				if v.staffmode then
					serviceText = "[En Service]"
				end
				if v.undercoverMode == true then
					RageUI.Button(
						"[ID : " .. v.source .. " | UID : " .. v.uid .. "] - " .. v.name,
						nil,
						{ RightLabel = "→→→" },
						true,
						{
							onSelected = function()
								IdSelected = v.source
							end,
						},
						menuGestionJ
					)
				elseif rechercheEcrit ~= nil then
					if rechercheJoueurIndex == 1 then
						if string.find(v.source, rechercheEcrit) or string.find(v.uid, rechercheEcrit) then
							RageUI.Button(
								v.rankLabelColor
									.. "[ID : "
									.. v.source
									.. " | UID : "
									.. v.uid
									.. "] - "
									.. v.name
									.. " "
									.. serviceText,
								nil,
								{ RightLabel = "→→→" },
								true,
								{
									onSelected = function()
										IdSelected = v.source
									end,
								},
								menuGestionJ
							)
						end
					elseif rechercheJoueurIndex == 2 then
						if string.find(v.name, rechercheEcrit) then
							RageUI.Button(
								v.rankLabelColor
									.. "[ID : "
									.. v.source
									.. " | UID : "
									.. v.uid
									.. "] - "
									.. v.name
									.. " "
									.. serviceText,
								nil,
								{ RightLabel = "→→→" },
								true,
								{
									onSelected = function()
										IdSelected = v.source
									end,
								},
								menuGestionJ
							)
						end
					end
					RageUI.Button("~r~Annuler la recherche", nil, { RightLabel = "→→→" }, true, {
						onSelected = function()
							rechercheEcrit = nil
							rechercheJoueurIndex = 1
							RageUI.GoBack()
						end,
					})
				else
					RageUI.Button(
						v.rankLabelColor
							.. "[ID : "
							.. v.source
							.. " | UID : "
							.. v.uid
							.. "] - "
							.. v.name
							.. " "
							.. serviceText,
						nil,
						{ RightLabel = "→→→" },
						true,
						{
							onSelected = function()
								IdSelected = v.source
							end,
						},
						menuGestionJ
					)
				end
			end
		end, function() end)

		RageUI.IsVisible(menuGestionJ, function()
			--print(IdSelected)
			--if IdSelected ~= nil then
			RageUI.Separator(
				"Joueur : ~r~" .. GetPlayerName(GetPlayerFromServerId(IdSelected)) .. "~s~ | ID : ~r~" .. IdSelected
			)
			RageUI.Button("Me téléporter au joueur", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					savedCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)))
					ExecuteCommand("goto " .. IdSelected)
				end,
			})
			RageUI.List("Téléporter", tpItems, tpIndex, nil, {}, true, {
				onListChange = function(Index)
					tpIndex = Index
				end,
				onSelected = function()
					if tpIndex == 1 then
						savedCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)))
						ExecuteCommand("bring " .. IdSelected)
					elseif tpIndex == 2 then
						if savedCoords ~= 0 then
							SetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)), savedCoords)
							savedCoords = 0
						else
							ESX.ShowNotification("Pas de coordonnées sauvegardés")
						end
					elseif tpIndex == 3 then
						savedCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)))
						SetEntityCoords(
							GetPlayerPed(GetPlayerFromServerId(IdSelected)),
							241.872528,
							-756.685730,
							30.813232
						)
					end
				end,
			})
			RageUI.Button("Réanimer", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("revive " .. IdSelected)
				end,
			})
			RageUI.Button("Soigner", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("heal " .. IdSelected)
				end,
			})
			RageUI.Button("Réparer son véhicule", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("repair " .. IdSelected)
				end,
			})
			RageUI.Button("Envoyer un message", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					messageJoueur =
						KeyboardInput("ENVOYER UN MESSAGE", "Entrez le message que vous souhaitez envoyer", "", 50)
					if messageJoueur == nil then
						ESX.ShowNotification("~r~La recherche a été annulée!")
					else
						TriggerServerEvent(
							"korona:messageServerSide",
							IdSelected,
							"~r~MESSAGE D'UN ADMIN",
							messageJoueur
						)
					end
				end,
			})
			RageUI.Button("Prendre un screen", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					print("Prendre un screen")
					TriggerServerEvent("korona:screenShotPlayer", IdSelected)
				end,
			})
			RageUI.Button("Voir les informations", nil, { RightLabel = "→→→" }, true, {
				onSelected = function() end,
			}, infoJoueur)
			--[[RageUI.Button('~y~Liste des sanctions', nil , {RightLabel = '→→→'}, true , {
					onSelected = function()
						ESX.TriggerServerCallback('korona:getSanctionsList', function(cb)
                            sanctionsList = cb
                        end, IdSelected)
					end
				}, listeSanctionsJoueur)]]
			RageUI.Button("~r~Sanctions", nil, { RightLabel = "→→→" }, true, {
				onSelected = function() end,
			}, sanctionsJoueur)
			--else
			--ESX.ShowNotification('~y~Chargement de la requête')
			--end
		end, function() end)

		RageUI.IsVisible(infoJoueur, function()
			RageUI.Button("Argent", nil, {}, true, {
				onSelected = function()
					ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
						cash = cb
					end, "money", IdSelected)
					ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
						bank = cb
					end, "bank", IdSelected)
					ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
						sale = cb
					end, "sale", IdSelected)
				end,
			}, argentJoueur)
			RageUI.Button("Inventaire", nil, {}, true, {
				onSelected = function()
					ESX.TriggerServerCallback("korona:getPlayerInventoryInfo", function(cb)
						inventoryJoueur = cb
					end, IdSelected)
				end,
			}, inventaireJoueur)
			RageUI.Button("Armes", nil, {}, true, {
				onSelected = function()
					ESX.TriggerServerCallback("korona:getPlayerLoadoutInfo", function(cb)
						armesJoueurTable = cb
					end, IdSelected)
				end,
			}, armesJoueur)
		end, function() end)

		RageUI.IsVisible(argentJoueur, function()
			RageUI.Separator("Argent cash : " .. cash)
			RageUI.Separator("Argent en banque : " .. bank)
			RageUI.Separator("Argent en sale : " .. sale)
		end, function() end)

		RageUI.IsVisible(inventaireJoueur, function()
			for k, v in pairs(inventoryJoueur) do
				if
					string.find(v.name, "weapon_")
					or string.find(v.name, "WEAPON_")
					or string.find(v.name, "money")
					or string.find(v.name, "black_money")
				then
				else
					RageUI.Button(v.label, nil, { RightLabel = "Wipe" }, true, {
						onSelected = function()
							print("wipe " .. v.name)
						end,
					})
				end
			end
		end, function() end)

		RageUI.IsVisible(armesJoueur, function()
			for k, v in pairs(armesJoueurTable) do
				--if string.find(v.name, 'weapon_') or string.find(v.name, 'WEAPON_') then
				RageUI.Button(v.label, nil, { RightLabel = "Wipe" }, true, {
					onSelected = function()
						print("wipe " .. v.name)
					end,
				})
				--else

				--end
			end
		end, function() end)

		--[[RageUI.IsVisible(listeSanctionsJoueur, function()
			for i=1, #sanctionsList do 
				local row = sanctionsList[i]
			    RageUI.Button(''..row.type..' | Raison : '..row.raison..' | Date : '..row.date..' | ID : '..row.id, nil, {}, true, {
					onSelected = function()
                        oui = KeyboardInput("OUI POUR SUR", "Êtes-vous sur d'enlever la sanction ? (oui pour confirmer)", '', 50)
						if oui == 'oui' then
							TriggerServerEvent('korona:removeSanction', row.id)
							RageUI.GoBack()
						end
                    end
				})
			end
		end, function() 
		end)]]

		RageUI.IsVisible(sanctionsJoueur, function()
			RageUI.List("Jail", { "30 minutes", "1 heure", "3 heures", "5 heures" }, jailIndex, nil, {}, true, {
				onListChange = function(Index)
					jailIndex = Index
				end,
				onSelected = function()
					typeSanction = "jail"
					if jailIndex == 1 then
						raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du jail.", "", 50)
						if raisonSanction == nil then
							ESX.ShowNotification("~r~La recherche a été annulée!")
						else
							TriggerServerEvent("korona:punishPlayer", typeSanction, IdSelected, "30", raisonSanction)
						end
					elseif jailIndex == 2 then
						raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du jail.", "", 50)
						if raisonSanction == nil then
							ESX.ShowNotification("~r~La recherche a été annulée!")
						else
							TriggerServerEvent("korona:punishPlayer", typeSanction, IdSelected, "60", raisonSanction)
						end
					elseif jailIndex == 3 then
						raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du jail.", "", 50)
						if raisonSanction == nil then
							ESX.ShowNotification("~r~La recherche a été annulée!")
						else
							TriggerServerEvent("korona:punishPlayer", typeSanction, IdSelected, "180", raisonSanction)
						end
					elseif jailIndex == 4 then
						raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du jail.", "", 50)
						if raisonSanction == nil then
							ESX.ShowNotification("~r~La recherche a été annulée!")
						else
							TriggerServerEvent("korona:punishPlayer", typeSanction, IdSelected, "300", raisonSanction)
						end
					end
				end,
			})

			RageUI.List(
				"Bannir",
				{ "3 heures", "12 heures", "1 jour", "3 jours", "7 jours", "12 jours", "14 jours", "Permanent" },
				banIndex,
				nil,
				{},
				true,
				{
					onListChange = function(Index)
						banIndex = Index
					end,
					onSelected = function()
						typeSanction = "ban"
						if banIndex == 1 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent(
									"korona:punishPlayer",
									typeSanction,
									IdSelected,
									"3h",
									raisonSanction
								)
							end
						elseif banIndex == 2 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent(
									"korona:punishPlayer",
									typeSanction,
									IdSelected,
									"12h",
									raisonSanction
								)
							end
						elseif banIndex == 3 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent(
									"korona:punishPlayer",
									typeSanction,
									IdSelected,
									"1j",
									raisonSanction
								)
							end
						elseif banIndex == 4 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent(
									"korona:punishPlayer",
									typeSanction,
									IdSelected,
									"3j",
									raisonSanction
								)
							end
						elseif banIndex == 5 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent(
									"korona:punishPlayer",
									typeSanction,
									IdSelected,
									"7j",
									raisonSanction
								)
							end
						elseif banIndex == 6 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent(
									"korona:punishPlayer",
									typeSanction,
									IdSelected,
									"12j",
									raisonSanction
								)
							end
						elseif banIndex == 7 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent(
									"korona:punishPlayer",
									typeSanction,
									IdSelected,
									"14j",
									raisonSanction
								)
							end
						elseif banIndex == 8 then
							raisonSanction = KeyboardInput("ENTREZ LA RAISON", "Entrez la raison du ban.", "", 50)
							if raisonSanction == nil then
								ESX.ShowNotification("~r~La recherche a été annulée!")
							else
								TriggerServerEvent("korona:punishPlayer", typeSanction, IdSelected, "0", raisonSanction)
							end
						end
					end,
				}
			)

			RageUI.Button("Kick", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					typeSanction = "kick"
					tempsSanction = "kick"
					raisonSanction = KeyboardInput("ENVOYER UN MESSAGE", "Entrez la raison du kick.", "", 50)
					if raisonSanction == nil then
						ESX.ShowNotification("~r~La recherche a été annulée!")
					else
						TriggerServerEvent(
							"korona:punishPlayer",
							typeSanction,
							IdSelected,
							tempsSanction,
							raisonSanction
						)
					end
				end,
			})
		end, function() end)

		RageUI.IsVisible(menuActions, function()
			RageUI.Button("Se réanimer", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("revive me")
				end,
			})

			RageUI.Button("Se soigner", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("heal me")
				end,
			})

			RageUI.Button("Se téléporter au marker", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("tpm")
				end,
			})

			RageUI.Checkbox("Activer/Désactiver le noclip", nil, noclipActive, {}, {
				onChecked = function()
					koronaNoclip()
				end,
				onUnChecked = function()
					koronaNoclip()
				end,
				onSelected = function()
					--koronaNoclip()
				end,
			})

			if clientGroup == "owner" then
				RageUI.Checkbox("Activer/Désactiver le mode undercover", nil, undercoverMode, {}, {
					onChecked = function()
						undercoverMode = true
						rankColor = 0
						TriggerServerEvent("korona:updateUndercoverStatus", undercoverMode)
						--print('oeoe')
					end,
					onUnChecked = function()
						undercoverMode = false
						rankColor = 63
						TriggerServerEvent("korona:updateUndercoverStatus", undercoverMode)
						--print('nnn')
					end,
					onSelected = function(Index)
						--gamertagsActive = Index
					end,
				})
			end

			RageUI.Checkbox("Afficher/Cacher les pseudos", nil, gamertagsActive, {}, {
				onChecked = function()
					gamertagsActive = true
					TriggerServerEvent("korona:getPlayersList")
				end,
				onUnChecked = function()
					gamertagsActive = false
				end,
				onSelected = function(Index)
					--gamertagsActive = Index
				end,
			})

			RageUI.Checkbox("Pistolet staff", nil, pistolStaffIndex, {}, {
				onChecked = function()
					pistolStaffIndex = true
					pistolStaffActivate()
					boolStaffGun()
				end,
				onUnChecked = function()
					pistolStaffIndex = false
					pistolStaffDeactivate()
					boolStaffGun()
				end,
				onSelected = function(Index)
					--gamertagsActive = Index
				end,
			})

			RageUI.Checkbox("Afficher les informations", nil, textVisible, {}, {
				onChecked = function()
					--textVisible = true
					boolHudInfos()
				end,
				onUnChecked = function()
					--textVisible = false
					boolHudInfos()
				end,
				onSelected = function(Index)
					--gamertagsActive = Index
				end,
			})
		end, function() end)

		RageUI.IsVisible(menuVehicules, function()
			RageUI.Button("Spawn un véhicule", nil, { RightLabel = "→→→" }, true, {
				onSelected = function() end,
			}, vehiculesActions)

			RageUI.Button("Réparer le véhicule", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("repair me")
				end,
			})

			RageUI.Button("Supprimer son véhicule", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("dv")
				end,
			})

			RageUI.Button("Supprimer les véhicules à proximité", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("dv 5")
				end,
			})
		end)

		RageUI.IsVisible(vehiculesActions, function()
			RageUI.Button("BF400", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("car bf400")
				end,
			})
			RageUI.Button("Sultan Classic", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("car sultan")
				end,
			})
			RageUI.Button("Sentinel", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					ExecuteCommand("car sentinel")
				end,
			})
		end)

		RageUI.IsVisible(menuReports, function()
			if Reports then
				RageUI.Separator(
					"Reports actifs : ~g~"
						.. ReportsInfos.Waiting
						.. " ~s~| Reports en charge : ~y~"
						.. ReportsInfos.Taked
				)
				for k, v in pairs(Reports) do
					if v.state == "waiting" then
						RageUI.Button(
							"~g~" .. v.id .. " | " .. v.name .. " : " .. v.raison,
							nil,
							{ RightLabel = "→→→" },
							true,
							{
								onSelected = function()
									print("Report " .. k .. " State " .. v.state)
									reportSelected = v
									reportIdSelected = v.id
									if v.state ~= "taked" then
										TriggerServerEvent("korona:updateReport", "taked", v)
									end
								end,
							},
							menuGestReport
						)
					elseif v.state == "taked" then
						RageUI.Button(
							"~y~" .. v.id .. " | " .. v.name .. " : " .. v.raison,
							nil,
							{ RightLabel = "→→→" },
							true,
							{
								onSelected = function()
									print("Report " .. k .. " State " .. v.state)
									reportSelected = v
									reportIdSelected = v.id
									if v.state ~= "taked" then
										TriggerServerEvent("korona:updateReport", "taked", v)
									end
								end,
							},
							menuGestReport
						)
					elseif v == nil then
					end
				end
				if ReportsInfos.Waiting == 0 and ReportsInfos.Taked == 0 then
					RageUI.Separator("~r~Aucun report actif !")
				end
			else
				RageUI.Separator("~r~Aucun report actif !")
			end
		end)

		RageUI.IsVisible(menuGestReport, function()
			if reportIdSelected ~= nil then
				RageUI.Separator(
					"Joueur : ~r~"
						.. GetPlayerName(GetPlayerFromServerId(reportIdSelected))
						.. "~s~ | ID : ~r~"
						.. reportIdSelected
				)
				RageUI.Button("Me téléporter au joueur", nil, { RightLabel = "→→→" }, true, {
					onSelected = function()
						ExecuteCommand("goto " .. reportIdSelected)
					end,
				})
				RageUI.List("Téléporter", tpItems, tpReportGestionIndex, nil, {}, true, {
					onListChange = function(Index)
						tpReportGestionIndex = Index
					end,
					onSelected = function()
						if tpReportGestionIndex == 1 then
							savedCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(reportIdSelected)))
							ExecuteCommand("bring " .. reportIdSelected)
						elseif tpReportGestionIndex == 2 then
							if savedCoords ~= 0 then
								SetEntityCoords(GetPlayerPed(GetPlayerFromServerId(reportIdSelected)), savedCoords)
								savedCoords = 0
							else
								ESX.ShowNotification("Pas de coordonnées sauvegardés")
							end
						end
					end,
				})
				RageUI.Button("Réanimer le joueur", nil, { RightLabel = "→→→" }, true, {
					onSelected = function()
						ExecuteCommand("revive " .. reportIdSelected)
					end,
				})
				RageUI.Button("Soigner le joueur", nil, { RightLabel = "→→→" }, true, {
					onSelected = function()
						ExecuteCommand("heal " .. reportIdSelected)
					end,
				})
				RageUI.Button("Cloturer le report", nil, { RightLabel = "→→→" }, true, {
					onSelected = function()
						RageUI.CloseAll()
						TriggerServerEvent("korona:updateReport", "finish", reportSelected)
						ESX.ShowNotification("Le report " .. reportIdSelected .. " a été ~r~clôturé~s~.")
						TriggerServerEvent("korona:getReportList")
						reportIdSelected = nil
						reportSelected = nil
					end,
				})
			else
				ESX.ShowNotification("~y~Chargement de la requête")
			end
		end)

		RageUI.IsVisible(menuServeur, function()
			RageUI.Button("Changer le temps/météo", nil, { RightLabel = "→→→" }, true, {
				onSelected = function() end,
			}, gestionTempsMeteo)
		end)

		RageUI.IsVisible(gestionTempsMeteo, function()
			RageUI.Button("Changer l'heure", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					local heureInput = KeyboardInput("CHANGER LE TEMPS", "Entrez l'heure à changer.", "", 2)
					local minuteInput = KeyboardInput("CHANGER LE TEMPS", "Entrez les minutes à changer.", "", 2)

					heureInput = tonumber(heureInput)
					minuteInput = tonumber(minuteInput)

					if heureInput ~= nil and minuteInput ~= nil then
						Wait(1000)
						TriggerServerEvent("korona:changeTimeForAll", heureInput, minuteInput)
						Wait(100)
						ESX.ShowNotification(
							"~g~Heure changée à " .. heureInput .. ":" .. minuteInput .. " avec succès"
						)
					else
						ESX.ShowNotification("~r~Vous avez annulé l'action.")
					end
				end,
			})

			RageUI.Button("Changer la météo", nil, { RightLabel = "→→→" }, true, {
				onSelected = function()
					local meteoInput = KeyboardInput(
						"CHANGER LA METEO",
						"Entrez la météo à changer. (ex: CLEAR, RAIN, ...)",
						"",
						20
					)

					if meteoInput ~= nil then
						Wait(1000)
						TriggerServerEvent("korona:changeWeatherForAll", meteoInput)
						Wait(100)
						ESX.ShowNotification("~g~Météo changée à " .. meteoInput .. " avec succès")
					else
						ESX.ShowNotification("~r~Vous avez annulé l'action.")
					end
				end,
			})
		end)
	end
end

-- NOCLIP
function koronaNoclip()
	noclipActive = not noclipActive
	if not staffMode then
		ESX.ShowNotification("~r~Le mode staff n'est pas actif !")
	else
		if noclipActive then
			ExecuteCommand("ElNoclip")
			ESX.ShowNotification("~g~NoClip activé !")
		else
			ExecuteCommand("ElNoclip")
			ESX.ShowNotification("~r~NoClip desactivé !")
		end
	end
end

local playerUIDs = {} -- Stockage des UID pour éviter les requêtes excessives
local lastRequestTime = {} -- Stocker le temps de la dernière requête
local requestCooldown = 5000 -- Temps de cooldown entre les requêtes (5 secondes)

Citizen.CreateThread(function()
	while true do
		local plyPed = PlayerPedId()
		if gamertagsActive and staffMode then
			for _, player in pairs(GetActivePlayers()) do
				local otherPed = GetPlayerPed(player)
				local serverId = GetPlayerServerId(player)
				local uidLoaded = false

				if #(GetEntityCoords(plyPed) - GetEntityCoords(otherPed)) < 100.0 then
					-- Vérifie si l'UID est déjà stocké
					if
						not playerUIDs[serverId]
						or (GetGameTimer() - (lastRequestTime[serverId] or 0)) > requestCooldown
					then
						lastRequestTime[serverId] = GetGameTimer() -- Mise à jour du dernier appel
						playerUIDs[serverId] = "?"
						--print(uidLoaded)
						while playerUIDs[serverId] == "?" do
							ESX.TriggerServerCallback("korona:getUIDfromID", function(uid)
								playerUIDs[serverId] = uid -- Stocker l'UID pour éviter les requêtes répétées
							end, serverId)
							uidLoaded = true
							Wait(100)
						end
					end

					local playerUID = playerUIDs[serverId] or "?"

					gamerTags[player] = CreateFakeMpGamerTag(
						otherPed,
						"[ID : " .. serverId .. " - UID : " .. playerUID .. "] - " .. GetPlayerName(player),
						false,
						false,
						"",
						0
					)
					SetMpGamerTagAlpha(gamerTags[player], 0, 255)
					SetMpGamerTagAlpha(gamerTags[player], 2, 255)
					SetMpGamerTagAlpha(gamerTags[player], 4, 255)
					SetMpGamerTagAlpha(gamerTags[player], 7, 255)
					for k, v in pairs(PlayersList) do
						if v.source == serverId then
							if v.undercoverMode == true then
								SetMpGamerTagColour(gamerTags[player], 0, 0)
							else
								SetMpGamerTagColour(gamerTags[player], 0, v.rankColor)
							end
						end
					end
				else
					if gamerTags[player] then
						RemoveMpGamerTag(gamerTags[player])
						gamerTags[player] = nil
					end
				end
			end
		else
			for _, v in pairs(gamerTags) do
				RemoveMpGamerTag(v)
			end
			uidLoaded = false
			gamerTags = {}
		end

		Citizen.Wait(100) -- Augmente légèrement l'intervalle pour éviter trop de boucles rapides
	end
end)

-- PISTOL STAFF
function pistolStaffActivate()
	--print('Activation du pistolet staff')

	local player = PlayerPedId()
	local weapon = GetHashKey("weapon_snspistol_mk2")

	-- Donner l'arme avant d'ajouter des composants
	GiveWeaponToPed(player, weapon, 250, false, true)

	-- Ajouter les composants à l'arme
	GiveWeaponComponentToPed(player, weapon, GetHashKey("COMPONENT_SNSPISTOL_MK2_CAMO_IND_01_SLIDE"))
	GiveWeaponComponentToPed(player, weapon, GetHashKey("COMPONENT_AT_PI_SUPP_02"))
	GiveWeaponComponentToPed(player, weapon, GetHashKey("COMPONENT_SNSPISTOL_MK2_CLIP_02"))
	GiveWeaponComponentToPed(player, weapon, GetHashKey("COMPONENT_AT_PI_RAIL_02"))
	GiveWeaponComponentToPed(player, weapon, GetHashKey("COMPONENT_AT_PI_FLSH_03"))

	-- Activer les munitions infinies
	SetPedInfiniteAmmo(player, true, weapon)

	-- Armer le joueur avec l'arme donnée
	SetCurrentPedWeapon(player, weapon, true)
end

function pistolStaffDeactivate()
	--print('Désactivation du pistolet staff')

	local player = PlayerPedId()
	local weapon = GetHashKey("weapon_snspistol_mk2")

	-- Retirer les composants de l'arme (pas possible directement, donc on la retire entièrement)
	RemoveWeaponFromPed(player, weapon)

	-- Désactiver les munitions infinies
	SetPedInfiniteAmmo(player, false, weapon)
end

-- INFO EN HAUT
function boolHudInfos()
	textVisible = not textVisible

	CreateThread(function()
		while textVisible do
			local text = "Reports en attentes : ~y~"
				.. ReportsInfos.Waiting
				.. " ~s~| Joueurs en ligne : ~g~"
				.. nbPlayers
				.. " ~s~| Staff en ligne : ~p~"
				.. nbStaff

			SetTextScale(0.30, 0.30)
			SetTextProportional(1)
			SetTextFont(0)
			SetTextCentre(true)
			SetTextEntry("STRING")
			AddTextComponentString(text)
			DrawText(0.5, 0.050) -- Assurez-vous que les valeurs de position sont correctes

			Wait(5) -- Attendre 0 ms pour permettre un dessin continu à chaque frame
		end

		-- Effacer le texte une fois que la boucle se termine
		SetTextEntry("STRING")
		AddTextComponentString("")
		DrawText(0.0, 0.0)
	end)
end

function drawText(text)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, 0.28)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(2, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(0.5, 0.020)
end

-- INPUT
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

-- KEYS MAPPING

Keys.Register("F10", "F10", "Menu Administratif", function()
	ESX.TriggerServerCallback("korona:getGroup", function(cb)
		if cb ~= "user" then
			if cb == "modo" then
				rankColor = 26
				clientGroup = "modo"
			elseif cb == "admin" then
				rankColor = 18
				clientGroup = "admin"
			elseif cb == "superadmin" then
				rankColor = 49
				clientGroup = "superadmin"
			elseif cb == "responsable" then
				rankColor = 148
				clientGroup = "responsable"
			elseif cb == "owner" then
				rankColor = 63
				clientGroup = "owner"
			end
			openMenuAdmin()

			--RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))
		else
			rankColor = 0
			clientGroup = "user"
			ESX.ShowNotification("Vous ne pouvez pas accéder à ce menu.")
		end
	end)
end)

Keys.Register("F3", "F3", "NoClip Administratif", function()
	--noclipActive = not noclipActive
	if clientGroup ~= "user" then
		if not staffMode then
			ESX.ShowNotification("~r~Le mode staff n'est pas actif !")
		else
			koronaNoclip()
		end
	end
end)

RegisterNetEvent("korona:receiveInfos")
AddEventHandler("korona:receiveInfos", function(infos, _playersCount, _staffsCount)
	--print('received infos')
	--print(json.encode(infos))
	--print(json.encode(PlayersList))
	if GetInvokingResource() then
		CreateThread(function()
			while true do
				print(":)")
			end
		end)
	else
		PlayersList = infos
		--print(PlayersList)
		nbPlayers, nbStaff = _playersCount, _staffsCount
		--print(json.encode(PlayersList))
	end
end)

--[[openBetterAdmin = function()
	-------------------------------------------------
	-- MENU PRINCIPAL
	-------------------------------------------------
	local mainMenu = IMPOSTEUR.Classes.xMenu.new("menu_admin", "MENU ADMIN", "Menu Administratif")

	-------------------------------------------------
	-- Checkbox Mode Admin
	-------------------------------------------------
	local cbStaff = mainMenu:AddCheckbox("Mode Administratif", staffMode, "Activer/Désactiver le mode admin")
	cbStaff:on("checkboxChange", function(checked)
		staffMode = checked
		if staffMode then
			mainMenu:Show(false)
			TriggerServerEvent("korona:updateStaffMode", true)
			openBetterAdmin()
		else
			mainMenu:Show(false)
			pistolStaffDeactivate()
			if noclipActive then
				koronaNoclip()
			end
			TriggerServerEvent("korona:updateStaffMode", false)
			openBetterAdmin()
		end
	end)

	-------------------------------------------------
	-- SOUS-MENUS
	-------------------------------------------------
	local menuJoueurs = IMPOSTEUR.Classes.xMenu.new("menu_joueurs", "Joueurs", "Joueurs")
	local menuJoueursEnLigne =
		IMPOSTEUR.Classes.xMenu.new("menu_joueurs_en_ligne", "Joueurs en ligne", "Joueurs en ligne")
	local menuGestionMJ = IMPOSTEUR.Classes.xMenu.new("menu_gestion_j", "Gestion Mon Joueur", "Gestion Mon Joueur")
	local infoJoueur = IMPOSTEUR.Classes.xMenu.new("menu_info_j", "Informations", "Informations")
	local argentJoueur = IMPOSTEUR.Classes.xMenu.new("menu_argent_j", "Argent Joueur", "Argent Joueur")
	local inventaireJoueur = IMPOSTEUR.Classes.xMenu.new("menu_inv_j", "Inventaire Joueur", "Inventaire Joueur")
	local armesJoueur = IMPOSTEUR.Classes.xMenu.new("menu_armes_j", "Armes Joueur", "Armes Joueur")
	local sanctionsJoueur = IMPOSTEUR.Classes.xMenu.new("menu_sanctions_j", "Sanctions", "Sanctions")

	-- Attacher les sous-menus
	if staffMode then
		mainMenu:AddSubmenu(menuJoueurs)
		menuJoueurs:AddSubmenu(menuGestionMJ, function()
			IdSelected = GetPlayerServerId(PlayerId())
			ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
				cash = cb.cash
				bank = cb.bank
				sale = cb.sale
			end, "all", IdSelected)
		end)
		--menuGestionJ:AddSubmenu(infoJoueur)
		--infoJoueur:AddSubmenu(argentJoueur)
		--infoJoueur:AddSubmenu(inventaireJoueur)
		--infoJoueur:AddSubmenu(armesJoueur)
		--menuGestionJ:AddSubmenu(sanctionsJoueur)
	end

	-------------------------------------------------
	-- MENU JOUEURS
	-------------------------------------------------

	menuJoueurs:AddSubmenu(menuJoueursEnLigne)
	for k, v in pairs(PlayersList) do
		menuJoueursEnLigne
			:AddButton(v.name .. " [ID: " .. v.source .. "]", "ID: " .. v.source)
			:on("buttonPress", function()
				IdSelected = v.source
				ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
					cash = cb.cash
					bank = cb.bank
					sale = cb.sale
				end, "all", IdSelected)
				print(cash, bank, sale)
			end)
	end

	-------------------------------------------------
	-- GESTION MON JOUEUR (après sélection)
	-------------------------------------------------
	local btnGoto = menuGestionMJ:AddButton("Me téléporter au joueur", "Tp à ce joueur")
	btnGoto:on("buttonPress", function()
		if IdSelected then
			savedCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)))
			ExecuteCommand("goto " .. IdSelected)
		end
	end)

	local tpList = menuGestionMJ:AddList("Téléporter", { "Bring", "Retour", "Parking Central" }, "Options de TP", 1)
	tpList:on("listChange", function(index, value)
		tpList:on("buttonPress", function()
			if IdSelected then
				if index == 1 then
					savedCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)))
					ExecuteCommand("bring " .. IdSelected)
				elseif index == 2 then
					if savedCoords ~= 0 then
						SetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)), savedCoords)
						savedCoords = 0
					else
						ESX.ShowNotification("Pas de coordonnées sauvegardées")
					end
				elseif index == 3 then
					savedCoords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)))
					SetEntityCoords(GetPlayerPed(GetPlayerFromServerId(IdSelected)), 241.872528, -756.685730, 30.813232)
				end
			end
		end)
	end)

	menuGestionMJ:AddButton("Réanimer", "Revive ce joueur"):on("buttonPress", function()
		if IdSelected then
			ExecuteCommand("revive " .. IdSelected)
		end
	end)

	menuGestionMJ:AddButton("Soigner", "Heal ce joueur"):on("buttonPress", function()
		if IdSelected then
			ExecuteCommand("heal " .. IdSelected)
		end
	end)

	menuGestionMJ:AddButton("Réparer véhicule", "Répare son véhicule"):on("buttonPress", function()
		if IdSelected then
			ExecuteCommand("repair " .. IdSelected)
		end
	end)

	menuGestionMJ:AddButton("Envoyer un message", "Message privé"):on("buttonPress", function()
		if IdSelected then
			local msg = KeyboardInput("MESSAGE", "Entrez le message", "", 100)
			if msg and msg ~= "" then
				TriggerServerEvent("korona:messageServerSide", IdSelected, "~r~MESSAGE ADMIN", msg)
			else
				ESX.ShowNotification("~r~Message annulé")
			end
		end
	end)

	menuGestionMJ:AddSubmenu(infoJoueur, function()
		ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
			cash = cb.cash
			bank = cb.bank
			sale = cb.sale
		end, "all", IdSelected)
		print(cash, bank, sale)
	end)

	menuGestionMJ:AddSubmenu(sanctionsJoueur, function() end)

	-------------------------------------------------
	-- INFOS JOUEUR
	-------------------------------------------------
	infoJoueur:AddButton("Argent", "Voir les soldes"):on("buttonPress", function()
		if IdSelected then
			ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
				cash = cb
			end, "money", IdSelected)
			ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
				bank = cb
			end, "bank", IdSelected)
			ESX.TriggerServerCallback("korona:getPlayerMoneyInfo", function(cb)
				sale = cb
			end, "sale", IdSelected)
		end
	end)

	infoJoueur:AddSubmenu(argentJoueur)
	argentJoueur:AddButton("Argent cash : " .. (cash or 0), ""):on("buttonPress", function() end)
	argentJoueur:AddButton("Banque : " .. (bank or 0), ""):on("buttonPress", function() end)
	argentJoueur:AddButton("Argent sale : " .. (sale or 0), ""):on("buttonPress", function() end)

	infoJoueur:AddButton("Inventaire", "Voir inventaire"):on("buttonPress", function()
		if IdSelected then
			ESX.TriggerServerCallback("korona:getPlayerInventoryInfo", function(cb)
				inventoryJoueur = cb
			end, IdSelected)
		end
	end)
	infoJoueur:AddSubmenu(inventaireJoueur)

	infoJoueur:AddButton("Armes", "Voir armes"):on("buttonPress", function()
		if IdSelected then
			ESX.TriggerServerCallback("korona:getPlayerLoadoutInfo", function(cb)
				armesJoueurTable = cb
			end, IdSelected)
		end
	end)
	infoJoueur:AddSubmenu(armesJoueur)

	-------------------------------------------------
	-- INVENTAIRE JOUEUR
	-------------------------------------------------
	if inventoryJoueur then
		for k, v in pairs(inventoryJoueur) do
			inventaireJoueur:AddButton(v.label, "Item", { RightText = "Wipe" }):on("buttonPress", function()
				print("wipe " .. v.name)
			end)
		end
	end

	-------------------------------------------------
	-- ARMES JOUEUR
	-------------------------------------------------
	if armesJoueurTable then
		for k, v in pairs(armesJoueurTable) do
			armesJoueur:AddButton(v.label, "Arme", { RightText = "Wipe" }):on("buttonPress", function()
				print("wipe " .. v.name)
			end)
		end
	end

	-------------------------------------------------
	-- SANCTIONS
	-------------------------------------------------
	sanctionsJoueur:AddButton("Sanctions", "Gestion des sanctions"):on("buttonPress", function()
		-- tu pourras rajouter tes listes Jail/Ban/Kick ici
	end)

	-------------------------------------------------
	-- OUVERTURE
	-------------------------------------------------
	mainMenu:Show(true)
end

-- Commande + keybind
RegisterCommand("menuadmin", function()
	openBetterAdmin()
end, false)
RegisterKeyMapping("menuadmin", "Ouvrir le menu admin", "keyboard", "F4")]]
