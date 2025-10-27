ESX = exports["es_extended"]:getSharedObject()
local currentCoffre = nil

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z - 0.035, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        for _, coffre in pairs(Config.Coffres) do
            if ESX.PlayerData.job and ESX.PlayerData.job.name == coffre.job then
                local dist = #(coords - coffre.position)

                if dist < 10.0 then
                    wait = 0

                    DrawMarker(23, coffre.position.x, coffre.position.y, coffre.position.z - 0.98,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.3, 0.3, 0.3,
                        120, 120, 255, 180, false, true, 2, false, nil, nil, false)

                    if dist < 1.5 then
                        DrawText3D(coffre.position.x, coffre.position.y, coffre.position.z + 0.2, "Appuyez sur ~b~E ~s~pour ouvrir le coffre")
                        if IsControlJustReleased(0, 38) then
                            OpenCoffreMenu(coffre.job)
                        end
                    end
                end
            end
        end

        Wait(wait)
    end
end)


function OpenCoffreMenu(jobName)
    ESX.TriggerServerCallback("coffre:getInventory", function(data)
        if not data then
            ESX.ShowNotification("~r~Erreur lors de la récupération du coffre.")
            return
        end

        local mainMenu = RageUI.CreateMenu("Coffre", "Contenu de l'entreprise")
        local argentPropre = data.account or 0
        local argentSale = data.blackMoney or 0
        local items = data.items or {}

        RageUI.Visible(mainMenu, true)
        while mainMenu do
            Wait(1)
            RageUI.IsVisible(mainMenu, function()
                RageUI.Separator("→ Items ("..#items..")")

                RageUI.Button("Déposer un item", nil, {}, true, {
                    onSelected = function()
                        OpenPutItemMenu(jobName)
                    end
                })

                RageUI.Button("Retirer un item", nil, {}, true, {
                    onSelected = function()
                        OpenTakeItemMenu(jobName)
                    end
                })

            end)

            if not RageUI.Visible(mainMenu) then
                mainMenu = RMenu:DeleteType("mainMenu", true)
                break
            end
        end
    end, jobName)
end

function OpenPutItemMenu(jobName)
    ESX.TriggerServerCallback("coffre:getPlayerInventory", function(data)
        if RMenu:Get('coffrejob', 'put') == nil then
            RMenu.Add('coffrejob', 'put', RageUI.CreateMenu("Déposer Item", "Votre inventaire"))
        end

        local itemMenu = RMenu:Get('coffrejob', 'put')
        RageUI.Visible(itemMenu, true)

        CreateThread(function()
            while RageUI.Visible(itemMenu) do
                RageUI.IsVisible(itemMenu, function()
                    for _, item in pairs(data.items) do
                        if item.count > 0 then
                            RageUI.Button(item.label.." [x"..item.count.."]", nil, {}, true, {
                                onSelected = function()
                                    local qty = tonumber(KeyboardInput("Quantité à déposer", "", 10))
                                    if qty and qty > 0 then
                                        TriggerServerEvent("coffre:depositItem", jobName, item.name, qty)
                                    end
                                end
                            })
                        end
                    end
                end)
                Wait(1)
            end
        end)
    end)
end

function OpenTakeItemMenu(jobName)
    ESX.TriggerServerCallback("coffre:getInventory", function(data)
        if not data or not data.items then
            ESX.ShowNotification("~r~Erreur récupération items.")
            return
        end

        if RMenu:Get('coffrejob', 'take') == nil then
            RMenu.Add('coffrejob', 'take', RageUI.CreateMenu("Retirer Item", "Coffre"))
        end

        local itemMenu = RMenu:Get('coffrejob', 'take')
        RageUI.Visible(itemMenu, true)

        CreateThread(function()
            while RageUI.Visible(itemMenu) do
                RageUI.IsVisible(itemMenu, function()
                    for _, item in pairs(data.items) do
                        if item.count > 0 then
                            RageUI.Button(item.label.." [x"..item.count.."]", nil, {}, true, {
                                onSelected = function()
                                    local qty = tonumber(KeyboardInput("Quantité à retirer", "", 10))
                                    if qty and qty > 0 then
                                        TriggerServerEvent("coffre:withdrawItem", jobName, item.name, qty)
                                    end
                                end
                            })
                        end
                    end
                end)
                Wait(1)
            end
        end)
    end, jobName)
end

function KeyboardInput(textEntry, exampleText, maxStringLength)
    AddTextEntry('FMMC_KEY_TIP1', textEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", exampleText, "", "", "", maxStringLength)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do Wait(0) end
    if UpdateOnscreenKeyboard() ~= 2 then
        return GetOnscreenKeyboardResult()
    else
        return nil
    end
end
