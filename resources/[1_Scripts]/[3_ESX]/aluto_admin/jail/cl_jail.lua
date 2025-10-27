local jailCoords = vector3(3257.459228, -138.619782, 16.187500)
local sortieCoords = vector3(215.419784, -810.382446, 30.712036)
local infos = {}
inJail = false
local time = 999999999 

--print("FUIGIFUUIZTDIYTZFDZ")

function setInJail(table)
    --print('oee')
    RageUI.CloseAll()
    SetEntityCoords(PlayerPedId(), jailCoords)
    displayOnScreen('~r~Jail', 'Vous avez été jail par ~y~'..table.staffName..'~s~ pour ~y~'..table.raison..'~s~ pendant ~y~'..table.temps)
    boolCountjailTime(table.temps)
    jailHudInfos()
    Citizen.CreateThread(function() 
        while inJail do 
            Wait(1)
            if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), jailCoords, true) > 60.0 then
                SetEntityCoords(PlayerPedId(), jailCoords)
            end
        end
    end)
end

RegisterNetEvent("korona:setInJail")
AddEventHandler("korona:setInJail", function(uid, temps, raison, staffName)
    local _source = source
    --print('in jail')
    infos = {
        uid = uid,
        temps = temps,
        raison = raison,
        staffName = staffName
    }
    setInJail(infos)
end)

RegisterNetEvent("korona:unjailClient")
AddEventHandler("korona:unjailClient", function(staffName)
    --print(staffName)
    inJail = false 
    Wait(1000)
    SetEntityCoords(PlayerPedId(), sortieCoords)
    displayOnScreen('~r~Jail', 'Vous avez été unjail par ~y~'..staffName)
end)

function jailHudInfos()
    inJail = not inJail

    CreateThread(function()
        while inJail do
            local text = 'Temps restant : '..time..' minutes.'

            SetTextScale(0.50, 0.50)
            SetTextProportional(1)
            SetTextFont(0)
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString(text)
            DrawText(0.5, 0.050)  -- Assurez-vous que les valeurs de position sont correctes

            Wait(2)  -- Attendre 0 ms pour permettre un dessin continu à chaque frame
        end

        -- Effacer le texte une fois que la boucle se termine
        SetTextEntry("STRING")
        AddTextComponentString('')
        DrawText(0.0, 0.0)
    end)
end

function boolCountjailTime(timeGet)
    time = timeGet
    CreateThread(function()
        while inJail do
            TriggerServerEvent('korona:updateJailedTime', infos.uid, time)
            Wait(1000 * 60)
            if time == 0 then
                inJail = false
                TriggerServerEvent('korona:endOfJail', PlayerId(), infos.uid, nil)
                infos = {}
                displayOnScreen('~r~Jail', 'Vous avez fini votre temps de Jail.')
                SetEntityCoords(PlayerPedId(), sortieCoords)
            else
                time = time - 1
            end
        end
    end)
end