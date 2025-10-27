--[[ INIT ]]--
IMPOSTEUR = IMPOSTEUR or {}

IMPOSTEUR.ServerCallbacks = {}

IMPOSTEUR.Classes = IMPOSTEUR.Classes or {}
IMPOSTEUR.Frames = {}
IMPOSTEUR.Frames.Ready = false
IMPOSTEUR.Frames.List = {}
IMPOSTEUR.Frames.FocusOrder = {}

IMPOSTEUR.UI = {}
IMPOSTEUR.UI.Component = {}
IMPOSTEUR.UI.HUD = {}
IMPOSTEUR.UI.Menu = {}
IMPOSTEUR.UI.Menu.Opened = {}

IMPOSTEUR.Global = IMPOSTEUR.Global or {}
IMPOSTEUR.Global.ModulesStarted = false
IMPOSTEUR.Global.SwitchFinished = false
IMPOSTEUR.Global.IsFirstSpawn = true
IMPOSTEUR.Global.ActivesUI = {}
IMPOSTEUR.Global.UiBusy = { state = false, component = "none" }

IMPOSTEUR.Enums = IMPOSTEUR.Enums or {}

IMPOSTEUR.Enums.ScaleformTypes = {
    ["Movie"] = 1,
    ["MovieInteractive"] = 2,
    ["ScriptHudMovie"] = 3
}

IMPOSTEUR.Thread(function()
    while true do
        Wait(0)
            local modules = Modules.GetList()
            for i = 1, #modules do
                modules[i]:Start()
            end
    end
end)

local ServerCallbacksRequestIID = IID.NewFactory()
function IMPOSTEUR.TriggerServerCallback(name, cb, ...)
    local requestId = ServerCallbacksRequestIID:NextId()
    IMPOSTEUR.ServerCallbacks[requestId] = cb
    IMPOSTEUR.EmitServer("triggerServerCallback", name, requestId, ...)
end

function IMPOSTEUR.PlaySoundFile(fileName, volume)
    SendNUIMessage({ action = 'play_sound', sound = './sounds/' .. fileName, volume = volume })
end

function IMPOSTEUR.OpenUrl(url)
    SendNUIMessage({ action = 'open_url', url = url })
end

do
    local localStorageRequests <const> = {}
    local LocalStorageRequestIID = IID.NewFactory()

    RegisterNUICallback('nui:get_local_storage:response', function(data, cb)
        localStorageRequests[data.requestId](data.value)
        localStorageRequests[data.requestId] = nil
        cb('ok')
    end)

    ---@param key string
    ---@param cb fun(value: string)
    function IMPOSTEUR.GetLocalStorage(key, cb)
        local requestId = LocalStorageRequestIID:NextId()
        localStorageRequests[requestId] = cb
        SendNUIMessage({ action = 'get_local_storage', requestId = requestId, key = key })
    end
end

---@param key string
---@param value string
function IMPOSTEUR.SetLocalStorage(key, value)
    SendNUIMessage({ action = 'set_local_storage', key = key, value = value })
end

--[[ FRAME MANAGER ]]--
function IMPOSTEUR.GetFrames()
    return IMPOSTEUR.Frames.List
end

function IMPOSTEUR.GetFrame(frameName)
    return IMPOSTEUR.Frames.List[frameName]
end

function IMPOSTEUR.UnfocusAllFrames()
    IMPOSTEUR.Frames.FocusOrder = {}
    SetNuiFocus(false)
end

--- @return Frame
function IMPOSTEUR.AddFrame(name, url, visible)
    assert(type(name) == "string", "IMPOSTEUR.AddFrame expects 'name' as a 'string'")
    assert(type(url) == "string", "IMPOSTEUR.AddFrame expects 'url' as a 'string'")

    if IMPOSTEUR.GetFrame(name) then
        return nil
    end

    local frame = IMPOSTEUR.Classes.Frame(name, url, visible)

    frame:once('destroyed', function()
        IMPOSTEUR.Frames.List[name] = nil
    end)

    IMPOSTEUR.Frames.List[name] = frame

    return frame
end

--[[ GAME EXTRA ]]--

if IS_GTA5 then
    function GAME.ClearScreen()
        ClearCloudHat()
        HideHudAndRadarThisFrame()
    end
elseif IS_RDR3 then
    function GAME.ClearScreen()
        HideHudAndRadarThisFrame()
    end
end

if IS_GTA5 then
    --- @param eventName string
    function GAME.PlayMusicEvent(eventName)
        PrepareMusicEvent(eventName)
        TriggerMusicEvent(eventName)
    end
end

if IS_GTA5 then
    function GAME.RenderVehicleInfo(vehicle)
        local model = GetEntityModel(vehicle)
        local vehName = GetLabelText(GetDisplayNameFromVehicleModel(model))
        local licensePlate = GetVehicleNumberPlateText(vehicle)

        SetTextFont(0)
        SetTextScale(0.0, 0.55)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()

        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(("Modèle: %s\nPlaque: %s"):format(vehName, licensePlate))
        EndTextCommandDisplayText(0.45, 0.9)
    end
end

if IS_GTA5 then
    function GAME.SpawnPlayer(model, coords, heading, cbInProgress)
        if not IMPOSTEUR.Global.IsFirstSpawn and not IsScreenFadedOut() then
            DoScreenFadeOut(0)
            while not IsScreenFadedOut() do
                Wait(0)
            end
        end

        GAME.FreezePlayer(true, IMPOSTEUR.Global.IsFirstSpawn)

        local spawnInfo = { model = model or 0, coords = coords, heading = heading }

        IMPOSTEUR.EmitSync('playerSpawning', spawnInfo, IMPOSTEUR.Global.IsFirstSpawn)

        if spawnInfo.model ~= 0 then
            CPlayer.SetModel(spawnInfo.model)
        end
        Wait(0)

        local PlayerPed = CPlayer().Ped
        GAME.Teleport(PlayerPed, spawnInfo.coords, { heading = spawnInfo.heading, noOffset = true })

        local gameplayCamHeading, gameplayCamPitch = GetGameplayCamRelativeHeading(), GetGameplayCamRelativePitch()

        NetworkResurrectLocalPlayer(spawnInfo.coords.x, spawnInfo.coords.y, spawnInfo.coords.z, spawnInfo.heading, 0, false)

        SetGameplayCamRelativeHeading(gameplayCamHeading)
        SetGameplayCamRelativePitch(gameplayCamPitch, 1.0)

        ClearPedTasksImmediately(PlayerPed)
        RemoveAllPedWeapons(PlayerPed, false)

        SetEntityHealth(PlayerPed, GetEntityMaxHealth(PlayerPed)) -- NetworkResurrectLocalPlayer set health to 200

        if cbInProgress then
            cbInProgress()
        end

        if IMPOSTEUR.Global.IsFirstSpawn then
            IMPOSTEUR.Global.IsFirstSpawn = false

            GAME.FreezePlayer(false, true)

            IMPOSTEUR.Emit("playerSpawned", spawnInfo, true)

            GAME.LoadingPromptHide()
            if not IsScreenFadedIn() then
                DoScreenFadeIn(2000)
                while not IsScreenFadedIn() do
                    Wait(0)
                end
            end

            if IMPOSTEUR.Global.LoginCamHandle > 0 then
                RenderScriptCams(false, GlobalCFG.SwitchInOnSpawn, 5000, false, false, 0)
                ClearFocus()
                Wait(5000)
                DestroyCam(IMPOSTEUR.Global.LoginCamHandle)
                IMPOSTEUR.Global.LoginCamHandle = 0
            end

            IMPOSTEUR.Global.SwitchFinished = true
            IMPOSTEUR.Emit("switchFinished")
        else
            GAME.FreezePlayer(false, false)

            IMPOSTEUR.Emit("playerSpawned", spawnInfo, false)

            GAME.LoadingPromptHide()
            if not IsScreenFadedIn() then
                DoScreenFadeIn(500)
                while not IsScreenFadedIn() do
                    Wait(0)
                end
            end
        end
    end
elseif IS_RDR3 then
    function GAME.SpawnPlayer(model, coords, heading, cbInProgress)
        if not IMPOSTEUR.Global.IsFirstSpawn and not IsScreenFadedOut() then
            DoScreenFadeOut(0)
            while not IsScreenFadedOut() do
                Wait(0)
            end
        end

        GAME.FreezePlayer(true, IMPOSTEUR.Global.IsFirstSpawn)

        local spawnInfo = { model = model or 0, coords = coords, heading = heading }

        IMPOSTEUR.EmitSync('playerSpawning', spawnInfo, IMPOSTEUR.Global.IsFirstSpawn)

        if spawnInfo.model ~= 0 then
            CPlayer.SetModel(spawnInfo.model)
        end
        Wait(0)

        local PlayerPed = CPlayer().Ped
        GAME.Teleport(PlayerPed, spawnInfo.coords, { heading = spawnInfo.heading, noOffset = true })

        local gameplayCamHeading, gameplayCamPitch = GetGameplayCamRelativeHeading(), GetGameplayCamRelativePitch()

        NetworkResurrectLocalPlayer(spawnInfo.coords.x, spawnInfo.coords.y, spawnInfo.coords.z, spawnInfo.heading, 0, false, 0, true)

        SetGameplayCamRelativeHeading(gameplayCamHeading, 1.0)
        SetGameplayCamRelativePitch(gameplayCamPitch, 1.0)

        ClearPedTasksImmediately(PlayerPed, false, true)
        RemoveAllPedWeapons(PlayerPed, true, true)

        if cbInProgress then
            cbInProgress()
        end

        if IMPOSTEUR.Global.IsFirstSpawn then
            IMPOSTEUR.Global.IsFirstSpawn = false

            GAME.FreezePlayer(false, true)

            IMPOSTEUR.Emit("playerSpawned", spawnInfo, true)

            GAME.LoadingPromptHide()
            if not IsScreenFadedIn() then
                DoScreenFadeIn(2000)
                while not IsScreenFadedIn() do
                    Wait(0)
                end
            end

            if IMPOSTEUR.Global.LoginCamHandle > 0 then
                RenderScriptCams(false, GlobalCFG.SwitchInOnSpawn, 5000, false, false, 0)
                Wait(5000)
                ClearFocus()
                DestroyCam(IMPOSTEUR.Global.LoginCamHandle)
                IMPOSTEUR.Global.LoginCamHandle = 0
            end

            IMPOSTEUR.Global.SwitchFinished = true
            IMPOSTEUR.Emit("switchFinished")
        else
            GAME.FreezePlayer(false, false)

            IMPOSTEUR.Emit("playerSpawned", spawnInfo, true)

            GAME.LoadingPromptHide()
            if not IsScreenFadedIn() then
                DoScreenFadeIn(500)
                while not IsScreenFadedIn() do
                    Wait(0)
                end
            end
        end
    end
end

---@return Blip
function GAME.RegisterBlip(target)
    local blip = IMPOSTEUR.Classes.Blip(target)

    blip:once('destroyed', function()
        for i = 1, #IMPOSTEUR.Blips do
            if IMPOSTEUR.Blips[i] == blip then
                table.remove(IMPOSTEUR.Blips, i)
                break
            end
        end
    end)

    IMPOSTEUR.Blips[#IMPOSTEUR.Blips + 1] = blip
    return blip
end

IMPOSTEUR.OnNet('setEntityOwner', function(entityNetId)
    local entity = GAME.GetEntityFromNetworkId(entityNetId)
    IO.Debug('setEntityOwner:1', entityNetId, entity)
    if entity <= 0 then
        return
    end

    local isAlreadyOwner = NetworkRequestControlOfEntity(entity)
    IO.Debug('setEntityOwner:2', isAlreadyOwner, IsEntityAMissionEntity(entity))

    if not isAlreadyOwner then
        local failTimer = GetGameTimer() + 10000

        while not NetworkHasControlOfEntity(entity) do
            Wait(0)
            IO.Debug('setEntityOwner:3', 'has no control')
            if not DoesEntityExist(entity) or failTimer <= GetGameTimer() then
                return
            end
        end
    end

    IMPOSTEUR.EmitServer('setEntityOwner:success', entityNetId)
end)

IMPOSTEUR.OnNet("serverCallback", function(requestId, ...)
    IMPOSTEUR.ServerCallbacks[requestId](...)
    IMPOSTEUR.ServerCallbacks[requestId] = nil
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= CURRENT_RESOURCE then
        return
    end

    for i = 1, #IMPOSTEUR.Blips do
        IMPOSTEUR.Blips[i]:Remove()
    end
end)

--[[ Player ]]--
local Player = { }

-- Player --
Player.ID = PlayerId()
Player.ServerID = GetPlayerServerId(Player.ID)
Player.Name = GetPlayerName(Player.ID)
Player.Ped = 0

-- Player / Exist --
Player.Exist = false
Player.RoutingBucket = 0
Player.Coords = vector3(0.0, 0.0, 0.0)
Player.Heading = 0.0
Player.Dead = false
Player.Health = 200
Player.Armor = 100
Player.Shooting = false
Player.Fighting = false
Player.OnFoot = true
Player.Weapon = `WEAPON_UNARMED`

-- Player / Exist / InVehicle --
Player.InVehicle = false
Player.Vehicle = 0
Player.IsDriver = false

if IS_GTA5 then
    Player.Skin = {
        model = `player_zero`,
        head = {
            motherId = 1,
            fatherId = 1,
            shapeMix = 0.5,
            skinMix = 0.5
        },
        faceFeatures = { },
        headOverlays = { },
        components = { },
        props = { },
        extra = { },
        decorations = { }
    }
else
    Player.Skin = {
        model = `mp_male`
    }
end

Player.GM = { }

-- Player - Extended --
Player.KnockedOut = false

-- Player - Init --
Player.Init = true

-- Player - Functions --
function Player.Get(k)
    return Player[k]
end

function Player.Set(k, v)
    Player[k] = v
end

local updatePlayer = nil

if IS_GTA5 then
    updatePlayer = function()
        local PlayerPed = PlayerPedId()
        Player.Ped = PlayerPed

        local wasInVehicle = Player.InVehicle
        local wasDriver = Player.IsDriver
        local lastVehicle = Player.Vehicle

        if DoesEntityExist(Player.Ped) and Player.Ped > 0 then
            Player.Exist = true
            local PlayerCoords = GetEntityCoords(Player.Ped, false)
            Player.Coords = PlayerCoords
            Player.Heading = GetEntityPhysicsHeading(Player.Ped)

            local wasDead = Player.Dead
            local PlayerDead = IsEntityDead(PlayerPed)
            Player.Dead = PlayerDead

            if wasDead ~= PlayerDead and PlayerDead then
                local data = {}

                local deathSource, deathCause = GetPedSourceOfDeath(PlayerPed), GetPedCauseOfDeath(PlayerPed)

                data.victimCoords = PlayerCoords
                data.deathCause = deathCause

                if deathSource ~= PlayerPed then
                    local killer = NetworkGetPlayerIndexFromPed(deathSource)

                    if killer and NetworkIsPlayerActive(killer) then
                        data.killedByPlayer = true
                        data.killer = killer
                        data.killerServerId = GetPlayerServerId(killer)
                        data.killerCoords = GetEntityCoords(GetPlayerPed(killer), false)
                        data.deathCause = deathCause
                        data.deathSource = deathSource
                    end
                end

                data.killedByPlayer = data.killer ~= nil

                IMPOSTEUR.Emit('playerDied', data)
            end

            Player.Health = GetEntityHealth(Player.Ped)
            Player.Armor = GetPedArmour(Player.Ped)
            Player.Shooting = IsPedShooting(Player.Ped)
            Player.Fighting = IsPedInMeleeCombat(Player.Ped)
            Player.OnFoot = IsPedOnFoot(Player.Ped)
            Player.Weapon = GetSelectedPedWeapon(Player.Ped)

            if IsPedInAnyVehicle(Player.Ped, false) then
                local vehicle = GetVehiclePedIsUsing(Player.Ped)

                if vehicle > 0 then
                    Player.InVehicle = true
                    Player.Vehicle = vehicle
                    Player.IsDriver = GetPedInVehicleSeat(Player.Vehicle, -1) == Player.Ped
                else
                    Player.InVehicle = false
                    Player.Vehicle = 0
                    Player.IsDriver = false
                end
            else
                Player.InVehicle = false
                Player.Vehicle = 0
                Player.IsDriver = false
            end
        else
            Player.Exist = false
            Player.Coords = vector3(0.0, 0.0, 0.0)
            Player.Heading = 0.0
            Player.Dead = false
            Player.Health = 200
            Player.Armor = 100
            Player.Shooting = false
            Player.Fighting = false
            Player.OnFoot = true
            Player.Weapon = `WEAPON_UNARMED`
            Player.InVehicle = false
            Player.Vehicle = 0
            Player.IsDriver = false
        end

        if wasInVehicle and Player.Vehicle ~= lastVehicle then
            IMPOSTEUR.Emit('playerExitedVehicle', lastVehicle, wasDriver)
        end

        if Player.InVehicle and Player.Vehicle ~= lastVehicle then
            IMPOSTEUR.Emit('playerEnteredVehicle', Player.Vehicle)
        end
    end
elseif IS_RDR3 then
    updatePlayer = function()
        local PlayerPed = PlayerPedId()
        Player.Ped = PlayerPed

        local wasInVehicle = Player.InVehicle
        local lastVehicle = Player.Vehicle

        if DoesEntityExist(PlayerPed) and PlayerPed > 0 then
            Player.Exist = true
            local PlayerCoords = GetEntityCoords(PlayerPed, false, true)
            Player.Coords = PlayerCoords
            Player.Heading = GetEntityHeading(PlayerPed)

            local wasDead = Player.Dead
            local PlayerDead = IsEntityDead(PlayerPed)
            Player.Dead = PlayerDead

            if wasDead ~= PlayerDead and PlayerDead then
                local data = {}

                local deathSource, deathCause = GetPedSourceOfDeath(PlayerPed), GetPedCauseOfDeath(PlayerPed)

                if deathCause ~= `WEAPON_UNARMED` then
                    data.victimCoords = PlayerCoords
                    data.deathCause = deathCause

                    if deathSource ~= PlayerPed then
                        local killer = NetworkGetPlayerIndexFromPed(deathSource)

                        if killer and NetworkIsPlayerActive(killer) then
                            data.killedByPlayer = true
                            data.killer = killer
                            data.killerServerId = GetPlayerServerId(killer)
                            data.killerCoords = GetEntityCoords(GetPlayerPed(killer), false, true)
                            data.deathCause = deathCause
                            data.deathSource = deathSource
                        end
                    end

                    data.killedByPlayer = data.killer ~= nil

                    IMPOSTEUR.Emit('playerDied', data)
                end
            end

            Player.Health = GetEntityHealth(PlayerPed)
            Player.Shooting = IsPedShooting(PlayerPed)
            Player.Fighting = IsPedInMeleeCombat(PlayerPed)
            Player.OnFoot = IsPedOnFoot(PlayerPed)
            local _, weapon = GetCurrentPedWeapon(PlayerPed, true, 0, false)
            Player.Weapon = weapon

            if IsPedInAnyVehicle(PlayerPed, false) then
                local vehicle = GetVehiclePedIsUsing(PlayerPed)

                if vehicle > 0 then
                    Player.InVehicle = true
                    Player.Vehicle = vehicle
                    Player.IsDriver = GetPedInVehicleSeat(Player.Vehicle, -1) == PlayerPed
                else
                    Player.InVehicle = false
                    Player.Vehicle = 0
                    Player.IsDriver = false
                end
            else
                Player.InVehicle = false
                Player.Vehicle = 0
                Player.IsDriver = false
            end
        else
            Player.Exist = false
            Player.Coords = vector3(0.0, 0.0, 0.0)
            Player.Heading = 0.0
            Player.Dead = false
            Player.Health = 200
            Player.Shooting = false
            Player.Fighting = false
            Player.OnFoot = true
            Player.Weapon = `WEAPON_UNARMED`
            Player.InVehicle = false
            Player.Vehicle = 0
            Player.IsDriver = false
        end

        if wasInVehicle and Player.Vehicle ~= lastVehicle then
            IMPOSTEUR.Emit('playerExitedVehicle', lastVehicle)
        end

        if Player.InVehicle and Player.Vehicle ~= lastVehicle then
            IMPOSTEUR.Emit('playerEnteredVehicle', Player.Vehicle)
        end
    end
end

-- Player - Thread --
IMPOSTEUR.On('internal:player:init', function()
    Player.Name = GetPlayerName(Player.ID)
    updatePlayer()

    if Player.Init then
        Player.Init = nil
        IMPOSTEUR.Emit("player:init")
    end

    IMPOSTEUR.Thread(function()
        while true do
            updatePlayer()
            Wait(0)
        end
    end)
end)

function Player.GetModel(forced)
    if forced then
        return GetEntityModel(Player.Ped)
    end

    return Player.Skin.model
end

if IS_GTA5 then
    function Player.SetModel(modelName, noComponent, forced)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if not forced and model == Player.Skin.model then
            return
        end

        if not IsModelInCdimage(model) then
            IO.Warn(("Attempted to set Player to an invalid model : %i"):format(model))
            return
        end

        local playerSkin = Player.Skin
        local oldModel = playerSkin.model

        local freeModel = Streaming.RequestModel(model)
        SetPlayerModel(Player.ID, model)
        freeModel()

        playerSkin.model = model

        Wait(0)

        if not noComponent then
            SetPedDefaultComponentVariation(Player.Ped)
        end

        playerSkin.head.motherId = 1
        playerSkin.head.fatherId = 1
        playerSkin.head.shapeMix = 0.5
        playerSkin.head.skinMix = 0.5

        table.wipe(playerSkin.faceFeatures)
        table.wipe(playerSkin.headOverlays)
        table.wipe(playerSkin.components)
        table.wipe(playerSkin.props)
        table.wipe(playerSkin.decorations)
        table.wipe(playerSkin.extra)

        if Player.IsPedFreemode(model) then
            Player.SetPedFreemodeDefaultValues()
        end

        IMPOSTEUR.Emit('modelUpdated', model, oldModel)
    end
elseif IS_RDR3 then
    function Player.SetModel(modelName, noComponent, forced)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if not forced and model == Player.Skin.model then
            return
        end

        if not IsModelInCdimage(model) then
            IO.Warn(("Attempted to set Player to an invalid model : %i"):format(model))
            return
        end

        local playerSkin = Player.Skin
        local oldModel = playerSkin.model

        local freeModel = Streaming.RequestModel(model)
        SetPlayerModel(Player.ID, model, false)
        freeModel()

        playerSkin.model = model

        Wait(0)

        if not noComponent then
            SetRandomOutfitVariation(Player.Ped, true)
        end

        if IS_GTA5 then
            table.wipe(playerSkin.faceFeatures)
        end

        IMPOSTEUR.Emit('modelUpdated', model, oldModel)
    end
end

if IS_GTA5 then
    function Player.GetPedHead(forced)
        if forced then
            local headBlendData = GAME.GetPedHeadBlendData(Player.Ped)

            return {
                motherId = headBlendData.shapeFirst,
                fatherId = headBlendData.shapeSecond,
                shapeMix = headBlendData.shapeMix + 0.0,
                skinMix = headBlendData.skinMix + 0.0
            }
        end

        return Player.Skin.head
    end

    function Player.SetPedHead(motherId, fatherId, shapeMix, skinMix, forced)
        local playerSkinHead = Player.Skin.head

        motherId = motherId or playerSkinHead.motherId
        fatherId = fatherId or playerSkinHead.fatherId
        shapeMix = shapeMix and (shapeMix + 0.0) or playerSkinHead.shapeMix
        skinMix = skinMix and (skinMix + 0.0) or playerSkinHead.skinMix

        if not forced and
            motherId == playerSkinHead.motherId and
            fatherId == playerSkinHead.fatherId and
            shapeMix == playerSkinHead.shapeMix and
            skinMix == playerSkinHead.skinMix
        then
            return
        end

        SetPedHeadBlendData(Player.Ped, motherId, fatherId, 0, motherId, fatherId, 0, shapeMix, skinMix, 0.0, true)
        playerSkinHead.motherId = motherId
        playerSkinHead.fatherId = fatherId
        playerSkinHead.shapeMix = shapeMix
        playerSkinHead.skinMix = skinMix
    end

    function Player.AddPedDecoration(collectionHash, nameHash)
        local playerDecorations = Player.Skin.decorations
        IO.Debug(("Decoration added (Collection: %u | Overlay: %u)"):format(collectionHash, nameHash))
        AddPedDecorationFromHashes(Player.Ped, collectionHash, nameHash)
        playerDecorations[#playerDecorations + 1] = {
            collectionHash = collectionHash,
            nameHash = nameHash
        }
    end
    
    function Player.ClearPedDecorations()
        ClearPedDecorations(Player.Ped)
        Player.Skin.decorations = {}
    end

    --[[
    function Player.GetPedFaceFeatures(forced)
        if forced then
            local faceFeatures = { }

            for featureIndex = 0, (rageE.FaceFeature - 1), 1 do
                faceFeatures[tostring(featureIndex)] = GetPedFaceFeature(Player.Ped, featureIndex)
            end

            return faceFeatures
        end

        return Player.Skin.faceFeatures
    end
    ]]

    function Player.GetPedFaceFeature(featureIndex, forced)
        featureIndex = tonumber(featureIndex)
        if featureIndex < 0 or featureIndex > (rageE.FaceFeatureNUM - 1) then
            return
        end

        if forced then
            return GetPedFaceFeature(Player.Ped, featureIndex)
        end

        local featureKey = tostring(featureIndex)
        if not featureKey then
            return
        end

        local playerSkinFaceFeatures = Player.Skin.faceFeatures
        local playerSkinFaceFeature = playerSkinFaceFeatures[featureKey]

        if not playerSkinFaceFeature then
            playerSkinFaceFeature = 0.0
            playerSkinFaceFeatures[featureKey] = playerSkinFaceFeature
        end

        return playerSkinFaceFeature
    end

    function Player.SetPedFaceFeature(featureIndex, featureScale, forced)
        featureIndex = tonumber(featureIndex)
        if featureIndex < 0 or featureIndex > (rageE.FaceFeatureNUM - 1) then
            return
        end

        local featureKey = tostring(featureIndex)
        if not featureKey then
            return
        end

        local playerSkinFaceFeatures = Player.Skin.faceFeatures
        local playerSkinFaceFeature = playerSkinFaceFeatures[featureKey]

        if not playerSkinFaceFeature then
            playerSkinFaceFeature = 0.0
            playerSkinFaceFeatures[featureKey] = playerSkinFaceFeature
        end

        featureScale = featureScale and (featureScale + 0.0) or playerSkinFaceFeature

        if not forced and featureScale == playerSkinFaceFeature then
            return
        end

        SetPedFaceFeature(Player.Ped, featureIndex, featureScale)
        playerSkinFaceFeatures[featureKey] = featureScale
    end

    function Player.GetPedHeadOverlay(overlayIndex, forced)
        overlayIndex = tonumber(overlayIndex)
        if overlayIndex < 0 or overlayIndex > (rageE.PedOverlayNUM - 1) then
            return
        end

        if forced then
            local olValue, olColourType, olFirstColor, olSecondColor, olOpacity = GetPedHeadOverlayData(Player.Ped, overlayIndex)

            return {
                value = olValue,
                colourType = olColourType,
                firstColor = olFirstColor,
                secondColor = olSecondColor,
                opacity = olOpacity + 0.0
            }
        end

        local overlayKey = tostring(overlayIndex)
        if not overlayKey then
            return
        end

        local playerSkinHeadOverlays = Player.Skin.headOverlays
        local playerSkinHeadOverlay = playerSkinHeadOverlays[overlayKey]

        if not playerSkinHeadOverlay then
            local olValue, olColourType, olFirstColor, olSecondColor, olOpacity = GetPedHeadOverlayData(Player.Ped, overlayIndex)

            playerSkinHeadOverlay = {
                value = olValue,
                colourType = olColourType,
                firstColor = olFirstColor,
                secondColor = olSecondColor,
                opacity = olOpacity + 0.0
            }

            playerSkinHeadOverlays[overlayKey] = playerSkinHeadOverlay
        end

        return playerSkinHeadOverlay
    end

    function Player.SetPedHeadOverlay(overlayIndex, overlayValue, overlayOpacity, forced)
        overlayIndex = tonumber(overlayIndex)
        if overlayIndex < 0 or overlayIndex > (rageE.PedOverlayNUM - 1) then
            return
        end

        local overlayKey = tostring(overlayIndex)
        if not overlayKey then
            return
        end

        local playerSkinHeadOverlays = Player.Skin.headOverlays
        local playerSkinHeadOverlay = playerSkinHeadOverlays[overlayKey]

        if not playerSkinHeadOverlay then
            local olValue, olColourType, olFirstColor, olSecondColor, olOpacity = GetPedHeadOverlayData(Player.Ped, overlayIndex)

            playerSkinHeadOverlay = {
                value = olValue,
                colourType = olColourType,
                firstColor = olFirstColor,
                secondColor = olSecondColor,
                opacity = olOpacity + 0.0
            }

            playerSkinHeadOverlays[overlayKey] = playerSkinHeadOverlay
        end

        overlayValue = overlayValue or playerSkinHeadOverlay.value
        overlayOpacity = overlayOpacity and (overlayOpacity + 0.0) or playerSkinHeadOverlay.opacity

        if not forced and
            overlayValue == playerSkinHeadOverlay.value and
            overlayOpacity == playerSkinHeadOverlay.opacity
        then
            return
        end

        SetPedHeadOverlay(Player.Ped, overlayIndex, overlayValue, overlayOpacity)
        playerSkinHeadOverlay.value = overlayValue
        playerSkinHeadOverlay.opacity = overlayOpacity
    end

    local colorTypes = {
        [rageE.PedOverlay.Eyebrows] = 1,
        [rageE.PedOverlay.FacialHair] = 1,
        [rageE.PedOverlay.ChestHair] = 1,
        [rageE.PedOverlay.Blush] = 2,
        [rageE.PedOverlay.Makeup] = 2,
        [rageE.PedOverlay.Lipstick] = 2
    }

    function Player.SetPedHeadOverlayColor(overlayIndex, firstColorId, secondColorId, forced)
        overlayIndex = tonumber(overlayIndex)
        if overlayIndex < 0 or overlayIndex > (rageE.PedOverlayNUM - 1) then
            return
        end

        local overlayKey = tostring(overlayIndex)
        if not overlayKey then
            return
        end

        local playerSkinHeadOverlays = Player.Skin.headOverlays
        local playerSkinHeadOverlay = playerSkinHeadOverlays[overlayKey]

        if not playerSkinHeadOverlay then
            local olValue, olColourType, olFirstColor, olSecondColor, olOpacity = GetPedHeadOverlayData(Player.Ped, overlayIndex)

            playerSkinHeadOverlay = {
                value = olValue,
                colourType = olColourType,
                firstColor = olFirstColor,
                secondColor = olSecondColor,
                opacity = olOpacity + 0.0
            }

            playerSkinHeadOverlays[overlayKey] = playerSkinHeadOverlay
        end

        firstColorId = firstColorId or playerSkinHeadOverlay.firstColor
        secondColorId = secondColorId or playerSkinHeadOverlay.secondColor

        if not forced and
            firstColorId == playerSkinHeadOverlay.firstColor and
            secondColorId == playerSkinHeadOverlay.secondColor and
            colorTypes[overlayIndex] == playerSkinHeadOverlay.colourType
        then
            return
        end

        SetPedHeadOverlayColor(Player.Ped, overlayIndex, colorTypes[overlayIndex] or 0, firstColorId, secondColorId)
        playerSkinHeadOverlay.firstColor = firstColorId
        playerSkinHeadOverlay.secondColor = secondColorId
    end

    function Player.GetPedComponentVariation(componentId, forced)
        componentId = tonumber(componentId)
        if componentId < 0 or componentId > (rageE.PedComponentNUM - 1) then
            return
        end

        if forced then
            return {
                drawable = GetPedDrawableVariation(Player.Ped, componentId),
                texture = GetPedTextureVariation(Player.Ped, componentId),
                palette = GetPedPaletteVariation(Player.Ped, componentId)
            }
        end

        local componentKey = tostring(componentId)
        if not componentKey then
            return
        end

        local playerSkinComponents = Player.Skin.components
        local playerSkinComponent = playerSkinComponents[componentKey]

        if not playerSkinComponent then
            playerSkinComponent = {
                drawable = GetPedDrawableVariation(Player.Ped, componentId),
                texture = GetPedTextureVariation(Player.Ped, componentId),
                palette = GetPedPaletteVariation(Player.Ped, componentId)
            }

            playerSkinComponents[componentKey] = playerSkinComponent
        end

        return playerSkinComponent
    end

    function Player.SetPedComponentVariation(componentId, drawableId, textureId, paletteId, forced)
        componentId = tonumber(componentId)
        if componentId < 0 or componentId > (rageE.PedComponentNUM - 1) then
            return
        end

        local componentKey = tostring(componentId)
        if not componentKey then
            return
        end

        if paletteId and (paletteId < 0 or paletteId > 3) then
            return
        end

        local playerSkinComponents = Player.Skin.components
        local playerSkinComponent = playerSkinComponents[componentKey]

        if not playerSkinComponent then
            playerSkinComponent = {
                drawable = GetPedDrawableVariation(Player.Ped, componentId),
                texture = GetPedTextureVariation(Player.Ped, componentId),
                palette = GetPedPaletteVariation(Player.Ped, componentId)
            }

            playerSkinComponents[componentKey] = playerSkinComponent
        end

        drawableId = drawableId or playerSkinComponent.drawable
        textureId = textureId or playerSkinComponent.texture
        paletteId = paletteId or playerSkinComponent.palette

        if not forced and
            drawableId == playerSkinComponent.drawable and
            textureId == playerSkinComponent.texture and
            paletteId == playerSkinComponent.palette
        then
            return
        end

        SetPedComponentVariation(Player.Ped, componentId, drawableId, textureId, paletteId)
        playerSkinComponent.drawable = drawableId
        playerSkinComponent.texture = textureId
        playerSkinComponent.palette = paletteId
    end

    function Player.SetPedFreemodeDefaultValues()
        Player.SetPedHead(21, 0, 0.5, 0.5, true)
        Player.SetPedHairColor(0, 0, true)
        for overlayIndex = 0, rageE.PedOverlayNUM - 1, 1 do
            if colorTypes[overlayIndex] then
                Player.SetPedHeadOverlayColor(overlayIndex, 0, 0, true)
            end
        end
    end

    --[[
    if (iParam2 == -1)
    {
        CLEAR_PED_PROP(iParam0, iParam1);
        if (iParam1 == 0)
        {
            SET_PED_CONFIG_FLAG(iParam0, 34, 0);
            SET_PED_CONFIG_FLAG(iParam0, 36, 0);
        }
    }
    else
    {
        SET_PED_PROP_INDEX(iParam0, iParam1, iParam2, iParam3, NETWORK_IS_GAME_IN_PROGRESS());
        if (iParam1 == 0)
        {
            iVar0 = func_453(iParam0, iParam2, iParam3, iParam1);
            if (func_557(GET_ENTITY_MODEL(iParam0), 14, iVar0, GET_HASH_NAME_FOR_PROP(iParam0, 0, iParam2, iParam3)))
            {
                SET_PED_CONFIG_FLAG(iParam0, 34, 1);
                SET_PED_CONFIG_FLAG(iParam0, 36, 1);
            }
            else
            {
                SET_PED_CONFIG_FLAG(iParam0, 34, 0);
                SET_PED_CONFIG_FLAG(iParam0, 36, 0);
            }
        }
    }
    ]]

    function Player.GetPedPropIndex(propId, forced)
        propId = tonumber(propId)
        if propId < 0 or propId > (rageE.PedPropNUM - 1) then
            return
        end

        if forced then
            return {
                drawable = GetPedPropIndex(Player.Ped, propId),
                texture = GetPedPropTextureIndex(Player.Ped, propId),
                attach = false
            }
        end

        local propKey = tostring(propId)
        if not propKey then
            return
        end

        local playerSkinProps = Player.Skin.props
        local playerSkinProp = playerSkinProps[propKey]

        if not playerSkinProp then
            playerSkinProp = {
                drawable = GetPedPropIndex(Player.Ped, propId),
                texture = GetPedPropTextureIndex(Player.Ped, propId),
                attach = false
            }

            playerSkinProps[propKey] = playerSkinProp
        end

        return playerSkinProp
    end

    function Player.SetPedPropIndex(propId, drawableId, textureId, attach, forced)
        propId = tonumber(propId)
        if propId < 0 or propId > (rageE.PedPropNUM - 1) then
            return
        end

        local propKey = tostring(propId)
        if not propKey then
            return
        end

        if drawableId and drawableId == -1 then
            textureId, attach = -1, false
        end

        local playerSkinProps = Player.Skin.props
        local playerSkinProp = playerSkinProps[propKey]

        if not playerSkinProp then
            playerSkinProp = {
                drawable = GetPedPropIndex(Player.Ped, propId),
                texture = GetPedPropTextureIndex(Player.Ped, propId),
                attach = false
            }

            playerSkinProps[propKey] = playerSkinProp
        end

        drawableId = drawableId or playerSkinProp.drawable
        textureId = textureId or playerSkinProp.texture
        attach = attach or playerSkinProp.attach

        if not forced and
            drawableId == playerSkinProp.drawable and
            textureId == playerSkinProp.texture and
            attach == playerSkinProp.attach
        then
            return
        end

        if drawableId == -1 then
            ClearPedProp(Player.Ped, propId)
        else
            SetPedPropIndex(Player.Ped, propId, drawableId, textureId, attach)
        end

        playerSkinProp.drawable = drawableId
        playerSkinProp.texture = textureId
        playerSkinProp.attach = attach
    end

    function Player.GetPedHairColor(forced)
        if forced then
            return GetPedHairColor(Player.Ped)
        end

        local playerSkinExtra = Player.Skin.extra

        if not playerSkinExtra.hairColor then
            local color = GetPedHairColor(Player.Ped)
            playerSkinExtra.hairColor = color
        end

        return playerSkinExtra.hairColor
    end

    function Player.GetPedHairHighlightColor(forced)
        if forced then
            return GetPedHairHighlightColor(Player.Ped)
        end

        local playerSkinExtra = Player.Skin.extra

        if not playerSkinExtra.hairHighlightColor then
            local highlightColor = GetPedHairHighlightColor(Player.Ped)
            playerSkinExtra.hairHighlightColor = highlightColor
        end

        return playerSkinExtra.hairHighlightColor
    end

    function Player.SetPedHairColor(colorId, highlightColorId, forced)
        local playerSkinExtra = Player.Skin.extra

        if not playerSkinExtra.hairColor then
            local color = GetPedHairColor(Player.Ped)
            playerSkinExtra.hairColor = color
        end

        if not playerSkinExtra.hairHighlightColor then
            local highlightColor = GetPedHairHighlightColor(Player.Ped)
            playerSkinExtra.hairHighlightColor = highlightColor
        end

        colorId = colorId or playerSkinExtra.hairColor
        highlightColorId = highlightColorId or playerSkinExtra.hairHighlightColor

        if not forced and
            colorId == playerSkinExtra.hairColor and
            highlightColorId == playerSkinExtra.hairHighlightColor
        then
            return
        end

        SetPedHairColor(Player.Ped, colorId, highlightColorId)
        playerSkinExtra.hairColor = colorId
        playerSkinExtra.hairHighlightColor = highlightColorId
    end

    function Player.GetPedEyeColor(forced)
        if forced then
            return GetPedEyeColor(Player.Ped)
        end

        local playerSkinExtra = Player.Skin.extra

        if not playerSkinExtra.eyeColor then
            local color = GetPedEyeColor(Player.Ped)
            playerSkinExtra.eyeColor = color
        end

        return playerSkinExtra.eyeColor
    end

    function Player.SetPedEyeColor(colorId, forced)
        local playerSkinExtra = Player.Skin.extra

        if not playerSkinExtra.eyeColor then
            local color = GetPedEyeColor(Player.Ped)
            playerSkinExtra.eyeColor = color
        end

        colorId = colorId or playerSkinExtra.eyeColor

        if not forced and colorId == playerSkinExtra.eyeColor then
            return
        end

        SetPedEyeColor(Player.Ped, colorId)
        playerSkinExtra.eyeColor = colorId
    end

    local Components = {
        ['model'] = {
            type = 'model',
            get = function(forced)
                return Player.GetModel(forced)
            end,
            set = function(value, forced)
                Player.SetModel(value, true, forced)
            end
        },
        ['mother'] = {
            type = 'head',
            get = function(forced)
                return Player.GetPedHead(forced).motherId
            end,
            set = function(value, forced)
                Player.SetPedHead(value, nil, nil, nil, forced)
            end
        },
        ['father'] = {
            type = 'head',
            get = function(forced)
                return Player.GetPedHead(forced).fatherId
            end,
            set = function(value, forced)
                Player.SetPedHead(nil, value, nil, nil, forced)
            end
        },
        ['shapeMix'] = {
            type = 'head',
            get = function(forced)
                return Player.GetPedHead(forced).shapeMix
            end,
            set = function(value, forced)
                Player.SetPedHead(nil, nil, value, nil, forced)
            end
        },
        ['skinMix'] = {
            type = 'head',
            get = function(forced)
                return Player.GetPedHead(forced).skinMix
            end,
            set = function(value, forced)
                Player.SetPedHead(nil, nil, nil, value, forced)
            end
        },
        ['hairColor'] = {
            type = 'extra',
            get = Player.GetPedHairColor,
            set = function(value, forced)
                Player.SetPedHairColor(value, nil, forced)
            end
        },
        ['hairSecondColor'] = {
            type = 'extra',
            get = Player.GetPedHairHighlightColor,
            set = function(value, forced)
                Player.SetPedHairColor(nil, value, forced)
            end
        },
        ['eyeColor'] = {
            type = 'extra',
            get = Player.GetPedEyeColor,
            set = Player.SetPedEyeColor
        }
    }

    for k, v in pairs(rageE.PedComponent) do
        Components[k:lowerFirst()] = {
            type = 'component',
            get = function(forced)
                return Player.GetPedComponentVariation(v, forced).drawable
            end,
            set = function(value, forced)
                Player.SetPedComponentVariation(v, value, nil, nil, forced)
            end
        }

        Components[('%sTexture'):format(k:lowerFirst())] = {
            type = 'component',
            get = function(forced)
                return Player.GetPedComponentVariation(v, forced).texture
            end,
            set = function(value, forced)
                Player.SetPedComponentVariation(v, nil, value, nil, forced)
            end
        }

        Components[('%sPalette'):format(k:lowerFirst())] = {
            type = 'component',
            get = function(forced)
                return Player.GetPedComponentVariation(v, forced).palette
            end,
            set = function(value, forced)
                Player.SetPedComponentVariation(v, nil, nil, value, forced)
            end
        }
    end

    for k, v in pairs(rageE.PedProp) do
        Components[k:lowerFirst()] = {
            type = 'prop',
            get = function(forced)
                return Player.GetPedPropIndex(v, forced).drawable
            end,
            set = function(value, forced)
                Player.SetPedPropIndex(v, value, nil, forced)
            end
        }

        Components[('%sTexture'):format(k:lowerFirst())] = {
            type = 'prop',
            get = function(forced)
                return Player.GetPedPropIndex(v, forced).texture
            end,
            set = function(value, forced)
                Player.SetPedPropIndex(v, nil, value, forced)
            end
        }
    end

    for k, v in pairs(rageE.PedOverlay) do
        Components[k:lowerFirst()] = {
            type = 'headOverlay',
            get = function(forced)
                return Player.GetPedHeadOverlay(v, forced).value
            end,
            set = function(value, forced)
                Player.SetPedHeadOverlay(v, value, nil, forced)
            end
        }

        Components[('%sOpacity'):format(k:lowerFirst())] = {
            type = 'headOverlay',
            get = function(forced)
                return Player.GetPedHeadOverlay(v, forced).opacity
            end,
            set = function(value, forced)
                Player.SetPedHeadOverlay(v, nil, value, forced)
            end
        }

        if colorTypes[v] then
            Components[('%sColor'):format(k:lowerFirst())] = {
                type = 'headOverlay',
                get = function(forced)
                    return Player.GetPedHeadOverlay(v, forced).firstColor
                end,
                set = function(value, forced)
                    Player.SetPedHeadOverlayColor(v, value, nil, forced)
                end
            }

            Components[('%sSecondColor'):format(k:lowerFirst())] = {
                type = 'headOverlay',
                get = function(forced)
                    return Player.GetPedHeadOverlay(v, forced).secondColor
                end,
                set = function(value, forced)
                    Player.SetPedHeadOverlayColor(v, nil, value, forced)
                end
            }
        end
    end

    for k, v in pairs(rageE.FaceFeature) do
        Components[k:lowerFirst()] = {
            type = 'faceFeature',
            get = function(forced)
                return Player.GetPedFaceFeature(v, forced)
            end,
            set = function(value, forced)
                Player.SetPedFaceFeature(v, value, forced)
            end
        }
    end

    function Player.GetPartialSkinIdsFromType(_type)
        local ids = {}

        for id, value in pairs(Components) do
            if value.type == _type then
                ids[#ids + 1] = id
            end
        end

        return ids
    end

    function Player.GetPartialSkin(ids, forced)
        local partialSkin = { }

        for i = 1, #ids do
            local id = ids[i]
            if Components[id] then
                partialSkin[id] = Components[id].get(forced)
            end
        end

        return partialSkin
    end

    function Player.GetPartialSkinByType(type, forced)
        local partialSkin = { }

        local ids = Player.GetPartialSkinIdsFromType(type)

        for i = 1, #ids do
            local id = ids[i]
            if Components[id] then
                partialSkin[id] = Components[id].get(forced)
            end
        end

        return partialSkin
    end

    function Player.ApplyPartialSkin(partialSkin, forced)
        for id, value in pairs(partialSkin) do
            if Components[id] then
                Components[id].set(value, forced)
            end
        end
    end

    function Player.GetSkin()
        return Player.Skin
    end

    function Player.ApplySkin(skin, forced)
        --Player.SetModel(skin.model, false, forced)
        Player.SetPedHead(skin.head.motherId, skin.head.fatherId, skin.head.shapeMix, skin.head.skinMix, forced)

        for k, v in pairs(skin.faceFeatures) do
            Player.SetPedFaceFeature(k, v, forced)
        end

        for k, v in pairs(skin.headOverlays) do
            Player.SetPedHeadOverlay(k, v.value, v.opacity, forced)
            Player.SetPedHeadOverlayColor(k, v.firstColor, v.secondColor, forced)
        end

        for k, v in pairs(skin.components) do
            Player.SetPedComponentVariation(k, v.drawable, v.texture, v.palette, forced)
        end

        for k, v in pairs(skin.props) do
            Player.SetPedPropIndex(k, v.drawable, v.texture, v.attach, forced)
        end

        for _, v in pairs(skin.decorations) do
            Player.AddPedDecoration(v.collectionHash, v.nameHash)
        end

        Player.SetPedHairColor(skin.extra.hairColor, skin.extra.hairHighlightColor, forced)
        Player.SetPedEyeColor(skin.extra.eyeColor, forced)
    end
end

function Player.IsPedFreemode()
    return GlobalCFG.PedsByHash[Player.Skin.model] ~= nil and GlobalCFG.PedsByHash[Player.Skin.model].freemode == true
end

function Player.IsPedMale()
    return GlobalCFG.PedsByHash[Player.Skin.model] ~= nil and GlobalCFG.PedsByHash[Player.Skin.model].male == true
end

function Player.IsPedFemale()
    return GlobalCFG.PedsByHash[Player.Skin.model] ~= nil and GlobalCFG.PedsByHash[Player.Skin.model].female == true
end

function Player.IsInAddonGroup(addonGroup)
    local addonGroups = Player.GM.addonGroups

    for i = 1, #addonGroups do
        if addonGroups[i].name == addonGroup then
            return true
        end
    end

    return false
end

function Player.GetUsername()
    return Player.GM.username
end

function Player.GetMail()
    return Player.GM.mail
end

function Player.GetNickname()
    return Player.GM.nickname
end

function Player.IsTemporaryAccount()
    return Player.GM.isTemporaryAccount or false
end

function Player.GetShopTokens()
    return Player.GM.shopTokens or 0
end

function Player.GetCharacterIdentifier()
    if not Player.GM.character then
        return nil
    end

    return Player.GM.character.identifier
end

-- TODO: Make a shortcut table like societyById for performance
function Player.IsCharacterInSociety(societyId)
    if not Player.GM.character then
        return false
    end

    if not Player.GM.character.societies then
        return false
    end

    local societies = Player.GM.character.societies

    for i = 1, #societies do
        if societies[i].id == societyId then
            return true
        end
    end

    return false
end

function Player.GetCharacterSociety(societyId)
    local societies = Player.GM.character.societies

    for i = 1, #societies do
        if societies[i].id == societyId then
            return societies[i]
        end
    end

    return nil
end

function Player.GetCharacterSocietyGrade(society, gradeId)
    local grades = society.grades

    for i = 1, #grades do
        if grades[i].id == gradeId then
            return i, grades[i]
        end
    end

    return -1, nil
end

function Player.GetCharacterCurrency(currencyName)
    return Player.GM.character.currencies[currencyName]
end

function Player.GetCharacterOwnedVehicle(vehicleId)
    if not Player.GM.character.vehiclesById then
        return nil
    end

    return Player.GM.character.vehiclesById[vehicleId]
end

function Player.GetCharacterExclusiveKvpKey(key)
    return CPlayer.GetCharacterIdentifier() .. ':' .. key
end

function Player.Init()
    while not NetworkIsSessionStarted() do
        Wait(0)
    end

    IMPOSTEUR.Emit("internal:player:init")
end

RegisterNetEvent('routingBucketUpdated', function(routingBucket)
    Player.RoutingBucket = routingBucket
end)

setmetatable(Player, {
    __call = function(self)
        return Player
    end
})

IMPOSTEUR.Classes.CPlayer = Player
CPlayer = Player

E.ControlFlags = {
    DEFAULT = 0,
    ALLOW_DEATH = 1 << 0
}

IMPOSTEUR.Thread(function()
    local temporarilyHiddenFrames = {}

    while true do
        Wait(0)

        local isPauseMenuActive = GetCurrentFrontendMenuVersion() == `FE_MENU_VERSION_MP_PAUSE`

        if #IMPOSTEUR.Frames.FocusOrder > 0 then
            -- Text Chat
            DisableControlAction(0, IS_RDR3 and `INPUT_MP_TEXT_CHAT_ALL` or 245, true)

            local focusedFrame = IMPOSTEUR.Frames.FocusOrder[#IMPOSTEUR.Frames.FocusOrder]
            if not focusedFrame.keepInput then
                DisableAllControlActions(0)
            end

            if focusedFrame.name ~= "main" and focusedFrame.visible and isPauseMenuActive then
                focusedFrame:Hide()

                local hasFocus, hasCursor, keepInput = focusedFrame.hasFocus, focusedFrame.hasCursor, focusedFrame.keepInput
                if hasFocus then
                    focusedFrame:Unfocus()
                end

                temporarilyHiddenFrames[#temporarilyHiddenFrames + 1] = {
                    frame = focusedFrame,
                    hasFocus = hasFocus,
                    hasCursor = hasCursor,
                    keepInput = keepInput
                }
            end
        end

        if not isPauseMenuActive then
            for i = #temporarilyHiddenFrames, 1, -1 do
                local hiddenFrame = temporarilyHiddenFrames[i]

                hiddenFrame.frame:Show()

                if hiddenFrame.hasFocus then
                    hiddenFrame.frame:Focus(hiddenFrame.hasCursor, hiddenFrame.keepInput)
                end
            end

            table.wipe(temporarilyHiddenFrames)
        end
    end
end)

function IMPOSTEUR.IsAnyFrameFocused()
    return #IMPOSTEUR.Frames.FocusOrder > 0
end

local createFrame = function(name, url, visible)
    if visible == nil then
        visible = true
    end
    SendNUIMessage({ action = 'create_frame', name = name, url = url, visible = visible })
end

local sendFrameMessage = function(name, msg)
    SendNUIMessage({ target = name, data = msg })
end

local focusFrame = function(name, cursor, keepInput)
    SendNUIMessage({ action = 'focus_frame', name = name })
    SetNuiFocus(true, cursor)

    if not IS_RDR3 then -- RDR3 doesn't support well SetNuiFocusKeepInput
        SetNuiFocusKeepInput(keepInput)
    else
        SetNuiFocusKeepInput(true)
    end
end

local blurFrame = function(name)
    SendNUIMessage({ action = 'blur_frame', name = name })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local showFrame = function(name)
    SendNUIMessage({ action = 'show_frame', name = name })
end

local hideFrame = function(name)
    SendNUIMessage({ action = 'hide_frame', name = name })
end

local topFrame = function(name)
    SendNUIMessage({ action = 'top_frame', name = name })
end

local destroyFrame = function(name)
    SendNUIMessage({ action = 'destroy_frame', name = name })
end

RegisterNUICallback('nui:ready', function(data, cb)
    IMPOSTEUR.Frames.Ready = true
    IMPOSTEUR.Emit('nui:ready')
    cb('ok')
end)

--[[ Frame Class ]]--
--- @class Frame : EventBase
local Frame = {}
local __instance = {
    __index = Frame,
    __type = "Frame"
} -- Metatable for instances

function Frame.New(name, url, visible)
    local self = setmetatable(EventBase(), __instance)

    self.name = name
    self.url = url
    self.handlers = {}
    self.loaded = false
    self.hasFocus = false
    self.hasCursor = false
    self.keepInput = false
    self.visible = visible
    self.destroyed = false

    RegisterNUICallback(('frame:%s:load'):format(self.name), function(data, cb)
        if not self.loaded then
            self.loaded = true
            self:emit('load')
        end

        cb('ok')
    end)

    RegisterNUICallback(('frame:%s:message'):format(self.name), function(data, cb)
        local cbCalled = false

        self:emit('message', data, function(...)
            if cbCalled then
                IO.Warn(("[frame] Frame '%s' callback can only be called once, data: %s"):format(self.name, Utils.StringSerializer(data)))
                return
            end

            cbCalled = true
            cb(...)
        end)
    end)

    createFrame(name, url, visible)

    return self
end

--- @deprecated
function Frame:OnLoad(onLoad)
    self:on('load', onLoad)
    return self
end

--- @deprecated
function Frame:OnMessage(onMessage)
    self:on('message', onMessage)
    return self
end

function Frame:SendMessage(msg)
    if self.loaded then
        sendFrameMessage(self.name, msg)
    else
        self:on('load', function()
            sendFrameMessage(self.name, msg)
        end)
    end

    return self
end

function Frame:Focus(cursor, input)
    local newFocusOrder = {}

    for i = 1, #IMPOSTEUR.Frames.FocusOrder do
        local frame = IMPOSTEUR.Frames.FocusOrder[i]

        if frame ~= self then
            newFocusOrder[#newFocusOrder + 1] = frame
        end
    end

    newFocusOrder[#newFocusOrder + 1] = self
    IMPOSTEUR.Frames.FocusOrder = newFocusOrder

    self.hasFocus = true
    self.hasCursor = cursor
    self.keepInput = input

    focusFrame(self.name, self.hasCursor, self.keepInput)

    self:emit('focus')
    return self
end

function Frame:Unfocus()
    local newFocusOrder = {}

    for i = 1, #IMPOSTEUR.Frames.FocusOrder do
        local frame = IMPOSTEUR.Frames.FocusOrder[i]

        if frame ~= self then
            newFocusOrder[#newFocusOrder + 1] = frame
        end
    end

    IMPOSTEUR.Frames.FocusOrder = newFocusOrder

    if #newFocusOrder > 0 then
        local previousFrame = newFocusOrder[#newFocusOrder]
        focusFrame(previousFrame.name, previousFrame.hasCursor, previousFrame.keepInput)
    else
        blurFrame(self.name)
    end

    self.hasFocus = false
    self.hasCursor = false
    self.keepInput = false

    self:emit('unfocus')
    return self
end

function Frame:Show()
    self.visible = true
    showFrame(self.name)
    self:emit('show')
    return self
end

function Frame:Top()
    topFrame(self.name)
    self:emit('top')
    return self
end

function Frame:Hide()
    self.visible = false
    hideFrame(self.name)
    self:emit('hide')
    return self
end

function Frame:Destroy()
    self:Unfocus()
    self.destroyed = true
    destroyFrame(self.name)
    self:emit('destroyed')
    return self
end

setmetatable(Frame, {
    __index = EventBase,
    __call = function(self, ...)
        return Frame.New(...)
    end
})

IMPOSTEUR.Classes.Frame = Frame