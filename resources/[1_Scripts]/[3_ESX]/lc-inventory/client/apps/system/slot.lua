RegisterNUICallback("PutIntoFast", function(data, cb)
    if not Config.BL_SlotInv[data.item.name] then
        if data.item.slot ~= nil then
            Inv.FastWeapons[data.item.slot] = nil
        end
        Inv.FastWeapons[data.slot] = data.item.name
        SetFieldValueFromNameEncode('lc-inventory', {name = Inv.FastWeapons})
        loadPlayerInventory('slot', nil, true, true)
        cb("ok")
    end
end)

RegisterNUICallback("TakeFromFast", function(data, cb)
    Inv.FastWeapons[data.item.slot] = nil
    SetFieldValueFromNameEncode('lc-inventory', {name = Inv.FastWeapons})
    loadPlayerInventory(currentMenu, nil, true, true)
    cb("ok")
end)

-- Enregistrement des keybinds
for k, v in pairs(Config.KeyBinds) do 
    RegisterKeyMapping(v.Command, v.Description, 'keyboard', v.Bind)
end

-- Commandes des touches rapides
RegisterCommand("keybind_1", function() useitem(1) end, false)
RegisterCommand("keybind_2", function() useitem(2) end, false)
RegisterCommand("keybind_3", function() useitem(3) end, false)
RegisterCommand("keybind_4", function() useitem(4) end, false)
RegisterCommand("keybind_5", function() useitem(5) end, false)

-- Fonction d’utilisation ou d’équipement
function useitem(num)
    local ped = PlayerPedId()

    if IsPedRagdoll(ped) then
        NotificationInInventory(Locales[Config.Language]['no_possible'], 'error')
        return
    end

    local item = Inv.FastWeapons[num]

    if not item then
        NotificationInInventory("Aucun item dans ce slot.", "error")
        return
    end

    if Config.BL_SlotInv[item] then return end
    if Inv.isInInventory then return end

    local prefix = string.sub(string.upper(item), 1, 7)

    -- Si ce n’est pas une arme
    if prefix ~= 'WEAPON_' then
        local trigger = Config.Trigger and Config.Trigger["useItem"]
        if trigger then
            TriggerServerEvent(trigger, item)
        else
            print("^1Erreur: Config.Trigger['esx:useItem'] est nil.^7")
            NotificationInInventory("Erreur : trigger manquant.", "error")
        end
        return
    end

    -- Sinon, c’est une arme
    if not weaponLock then
        weaponLock = true

        if weaponEquiped ~= item then
            weaponEquiped = item
            GiveWeaponToPed(ped, item, 250, false, true) -- <- optionnel si jamais l'arme n'est pas encore donnée
            SetCurrentPedWeapon(ped, item, true)
        else
            weaponEquiped = nil
            SetCurrentPedWeapon(ped, 'WEAPON_UNARMED', true)
        end

        Wait(150)
        weaponLock = false
    end
end
