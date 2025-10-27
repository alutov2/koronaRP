if not DEV then
    return
end

local weatherTypes = IS_RDR3 and {
    'BLIZZARD',
    'CLOUDS',
    'DRIZZLE',
    'FOG',
    'GROUNDBLIZZARD',
    'HAIL',
    'HIGHPRESSURE',
    'HURRICANE',
    'MISTY',
    'OVERCAST',
    'OVERCASTDARK',
    'RAIN',
    'SANDSTORM',
    'SHOWER',
    'SLEET',
    'SNOW',
    'SNOWLIGHT',
    'SUNNY',
    'THUNDER',
    'THUNDERSTORM',
    'WHITEOUT'
} or {
    'BLIZZARD',
    'CLEAR',
    'CLEARING',
    'CLOUDS',
    'EXTRASUNNY',
    'FOGGY',
    'HALLOWEEN',
    'NEUTRAL',
    'OVERCAST',
    'RAIN',
    'SMOG',
    'SNOW',
    'SNOWLIGHT',
    'THUNDER',
    'XMAS'
}

local menu

CreateThread(function()
    menu = IMPOSTEUR.Classes.xMenu('mod_menu', 'Mod Menu', 'Options disponibles')
    local submenu = IMPOSTEUR.Classes.xMenu('submenu', 'Submenu', 'Submenu super cool')

    -- Link the submenu to the main menu
    menu:AddSubmenu(submenu)

    -- Main menu items
    menu:AddButton('Suicide'):SetIcon('fa-regular fa-skull'):on('buttonPress', function()
        SetEntityHealth(PlayerPedId(), 0)
    end)

    menu:AddList('Météo', weatherTypes):SetIcon('fa-regular fa-sun'):on('listChange', function(listIndex, listText)
        local weatherType = weatherTypes[listIndex]

        if IS_RDR3 then
            SetWeatherType(GetHashKey(weatherType), true, true, true, 5000, false)
        else
            SetWeatherTypeNowPersist(weatherType)
        end
    end)

    menu:AddNumeralList('Heure', 0, 23):on('listChange', function(listIndex, listText)
        local hours = tonumber(listText)
        if IS_RDR3 then
            NetworkClockTimeOverride(hours, 0, 0, 0, false)
        else
            NetworkOverrideClockTime(hours, 0, 0)
        end
    end)

    menu:AddCheckbox('Invisible', false):on('checkboxChange', function(checked)
        SetEntityVisible(PlayerPedId(), not checked)
    end)

    menu:on('open', function()
        print('Menu opened', menu.id)
    end)

    menu:on('close', function()
        print('Menu closed', menu.id)
    end)

    -- Submenu items
    local colorBtn = submenu:AddButton('Panel de couleurs')

    colorBtn:AddColorPanel('haircut')
    colorBtn:on('colorUpdated', function(colorIndex)
        if IS_GTA5 then
            IO.Debug('Couleur', colorIndex)
            SetPedHairColor(CPlayer().Ped, colorIndex, 1)
        end
    end)

    local rgbColorBtn = submenu:AddButton('Color picker')
    rgbColorBtn:AddColorPicker()
    rgbColorBtn:on('colorUpdated', function(color)
        if IS_GTA5 then
            local vehicle = CPlayer().Vehicle
            if vehicle == 0 then return end

            IO.Debug('Couleur', json.encode(color))
            SetVehicleCustomPrimaryColour(vehicle, color.r, color.g, color.b)
        end
    end)

    local sliderBtn = submenu:AddButton('Slider panel')
    sliderBtn:AddSliderPanel(10)
    sliderBtn:on('sliderUpdated', function(value)
        IO.Debug('Valeur du slider', value)
    end)

    local gridBtn = submenu:AddButton('Nez')
    gridBtn:AddGridPanel('Haut', 'Bas', 'Fin', 'Large')
    gridBtn:on('gridUpdated', function(x, y)
        SetPedFaceFeature(CPlayer().Ped, 0, x)
        SetPedFaceFeature(CPlayer().Ped, 1, y)
    end)

    local horizontalGridBtn = submenu:AddButton('Horizontal grid')
    horizontalGridBtn:AddHorizontalGridPanel('Gauche', 'Droite')
    horizontalGridBtn:on('gridUpdated', function(x, y)
        SetPedFaceFeature(CPlayer().Ped, 12, x)
    end)

    RegisterCommand('setgridaxis', function(source, args)
        gridBtn:SetGridPanelAxis(tonumber(args[1]), tonumber(args[2]))
    end)
end)

RegisterCommand('menu', function()
    menu:Show(not menu:IsVisible())
end, false)