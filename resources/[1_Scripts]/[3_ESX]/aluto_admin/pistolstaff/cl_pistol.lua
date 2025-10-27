
pistolStaffIndex = false
IdSelected = 0
local weaponH = GetHashKey("weapon_snspistol_mk2")

-- Optimisation de la récupération de l'ID serveur du joueur
function GetPlayerIdFromPed(ped)
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerPed(player) == ped then
            return GetPlayerServerId(player)
        end
    end
    return 0
end

function boolStaffGun()
    CreateThread(function()
        while pistolStaffIndex do
            local playerPed = PlayerPedId()
            SetWeaponDamageModifier(weaponH, 0.0) -- Désactive les dégâts du pistolet
            SetAmmoInClip(PlayerPedId(), weaponH, 6) -- Limite les balles du chargeur
            Wait(3) -- Délai ajusté pour améliorer les performances

            if IsPedShooting(playerPed) then -- Clic gauche relâché
                --print('Tir de pistolet')
                local weapon = GetSelectedPedWeapon(playerPed)

                if weapon == weaponH then
                    
                    local result, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    
                    if entity ~= 0 then
                        if IsEntityAVehicle(entity) then
                            --print('Véhicule supprimé')
                            DeleteEntity(entity) -- Utilisation de la nouvelle fonction
                        elseif IsEntityAPed(entity) and IsPedAPlayer(entity) then
                            IdSelected = GetPlayerIdFromPed(entity)
                            if IdSelected ~= 0 then
                                --print("Joueur ciblé: "..IdSelected)
                                RageUI.Visible(menuGestionJ, true)
                            end
                        else 
                            --print('Aucun objet ciblé')
                        end
                    end
                end
            end
        end
    end)
end