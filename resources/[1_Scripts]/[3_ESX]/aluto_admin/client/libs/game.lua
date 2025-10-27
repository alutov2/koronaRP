GAME = GAME or {}
GAME.CreatedPeds, GAME.CreatedObjects, GAME.CreatedVehicles = {}, {}, {}

local netAttachedEntities = {}

if IS_GTA5 then
    function GAME.RequestCollisionAtCoords(coords, radius, tickCb)
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        if not NewLoadSceneStart(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, radius or 100.0, 0) then
            return false
        end

        local failTimer = GetGameTimer() + 2000
        while not toboolean(IsNewLoadSceneLoaded()) and failTimer > GetGameTimer() do
            Wait(0)

            if tickCb then
                tickCb()
            end
        end

        NewLoadSceneStop()
        return true
    end
elseif IS_RDR3 then
    function GAME.RequestCollisionAtCoords(coords, radius, tickCb)
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        local failTimer = GetGameTimer() + 2000
        while not toboolean(HasCollisionLoadedAtCoord(coords.x, coords.y, coords.z)) and failTimer > GetGameTimer() do
            Wait(0)

            if tickCb then
                tickCb()
            end
        end

        return true
    end
end

if IS_GTA5 then
    function GAME.PlaySound(audioName, audioRef)
        PlaySoundFrontend(-1, audioName, audioRef, true)
    end
elseif IS_RDR3 then
    function GAME.PlaySound(audioName, audioRef)
        PlaySoundFrontend(audioName, audioRef, true, 0)
    end
end

if IS_GTA5 then
    function GAME.GetPedMugshot(ped, transparent)
        local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)

        local started = GetGameTimer()
        while not IsPedheadshotReady(mugshot) do
            if (GetGameTimer() - started) > 10000 then
                return nil
            end

            Wait(0)
        end

        return mugshot, GetPedheadshotTxdString(mugshot)
    end
end

do
    local camsCreated = {}
    local rotatingCamIBMgr = nil

    local function setupInstructionalButtons()
        local instructionalButtonsMgr <const> = BiteUI.InstructionalButton.New()

        instructionalButtonsMgr:Add("Tourner à droite", 206)
        instructionalButtonsMgr:Add("Tourner à gauche", 205)

        instructionalButtonsMgr:Refresh()
        instructionalButtonsMgr:Visible(true)

        return instructionalButtonsMgr
    end

    function GAME.CreateRotatingEntityCamera(entity, bone, zOffset, distFromEntity)
        if not entity then
            IO.Error("GAME.CreateRotatingEntityCamera entity is undefined")
            return
        end

        local isCamAlreadyCreated = #camsCreated > 0
        local heading = isCamAlreadyCreated and camsCreated[#camsCreated].heading or GetEntityHeading(entity) + 90.0

        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        local camObj = { handle = cam, heading = heading }
        camsCreated[#camsCreated + 1] = camObj

        if not rotatingCamIBMgr then
            rotatingCamIBMgr = setupInstructionalButtons()
        end

        SetCamRot(cam, 0.0, 0.0, 0.0, true)

        local function disableControls()
            local actions = IS_GTA5 and
                { 24, 25, 30, 31, 32, 33, 34, 35, 44, 205, 206 } or
                { `INPUT_ATTACK`, `INPUT_AIM`, `INPUT_MOVE_LR`, `INPUT_MOVE_UD`, `INPUT_MOVE_UP_ONLY`, `INPUT_MOVE_DOWN_ONLY`, `INPUT_MOVE_LEFT_ONLY`, `INPUT_MOVE_RIGHT_ONLY`, `INPUT_COVER`, `INPUT_FRONTEND_LB`, `INPUT_FRONTEND_RB` }

            for i = 1, #actions do
                DisableControlAction(0, actions[i], true)
            end
        end

        local function calculatePosition(coords, angle)
            local angleRad = angle * math.pi / 180.0
            local theta = vec2(math.cos(angleRad), math.sin(angleRad))
            return coords.xy + distFromEntity * theta
        end

        Citizen.CreateThreadNow(function()
            while true do
                if not DoesCamExist(cam) or not DoesEntityExist(entity) then
                    DestroyCam(cam, false)
                    local camsLen = #camsCreated

                    for i = 1, camsLen do
                        if camsCreated[i].handle == cam then
                            camsLen = camsLen - 1
                            table.remove(camsCreated, i)
                            break
                        end
                    end

                    if camsLen == 0 then
                        RenderScriptCams(false, true, 500, true, true)
                    end

                    break
                end

                disableControls()

                local coords = bone and GetPedBoneCoords(entity, bone) or GetEntityCoords(entity, false)

                local camCoords = vec3(calculatePosition(coords, heading), coords.z + zOffset)
                local camCoordsToLook = vec3(calculatePosition(coords, heading - 180.0), coords.z + zOffset)

                SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
                PointCamAtCoord(cam, camCoordsToLook.x, camCoordsToLook.y, camCoordsToLook.z)

                if IsDisabledControlPressed(0, IS_GTA5 and 205 or `INPUT_FRONTEND_LB`) then
                    heading = heading - 1.0
                elseif IsDisabledControlPressed(0, IS_GTA5 and 206 or `INPUT_FRONTEND_RB`) then
                    heading = heading + 1.0
                end

                heading = (heading + 360) % 360
                camObj.heading = heading

                rotatingCamIBMgr:Draw()

                Wait(0)
            end

            if #camsCreated == 0 then
                rotatingCamIBMgr:Destroy()
                rotatingCamIBMgr = nil
            end
        end)

        SetCamActive(cam, true)
        RenderScriptCams(true, true, 750, true, true)

        return cam
    end
end

if IS_GTA5 then
    function GAME.IsPressingAimControl()
        return IsControlPressed(0, 24) or
            IsControlPressed(0, 25) or
            IsControlPressed(0, 68) or
            IsControlPressed(0, 69) or
            IsControlPressed(0, 70) or
            IsControlPressed(0, 91) or
            IsControlPressed(0, 92)
    end
end

if IS_GTA5 then
    function GAME.Teleport(entity, coords, options)
        if entity == -1 then
            entity = PlayerPedId()
        end

        if not options then options = {} end
        options.ignoreWater = not not options.ignoreWater

        local function setCoords(_coords)
            FreezeEntityPosition(entity, true)

            if options.withVehicle then
                local playerPed = PlayerPedId()
                local veh = GetVehiclePedIsIn(playerPed, false)

                if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == playerPed then
                    SetPedCoordsKeepVehicle(entity, _coords.x, _coords.y, _coords.z)
                else
                    SetEntityCoordsNoOffset(entity, _coords.x, _coords.y, _coords.z, true --[[KeepTasks]], true --[[KeepIK]], true --[[DoWarp]])
                end
            elseif options.noOffset then
                SetEntityCoordsNoOffset(entity, _coords.x, _coords.y, _coords.z, true --[[KeepTasks]], true --[[KeepIK]], true --[[DoWarp]])
            else
                SetEntityCoords(entity, _coords.x, _coords.y, _coords.z, false --[[DoDeadCheck]], true --[[KeepTasks]], true --[[KeepIK]], true --[[DoWarp]])
            end

            if options.heading then
                SetEntityHeading(entity, options.heading)
            end
        end

        setCoords(coords)

        if not options.findGround then
            GAME.RequestCollisionAtCoords(coords, nil, function()
                setCoords(coords)
            end)
        else
            local zCoords = -500.0
            while true do
                zCoords += 10.0
                RequestCollisionAtCoord(coords.x, coords.y, zCoords)
                Wait(0)
                local foundGround, _zCoords = GetGroundZFor_3dCoord(coords.x, coords.y, zCoords, options.ignoreWater)
                if foundGround then
                    zCoords = _zCoords
                    break
                else
                    if zCoords >= 1000.0 then
                        zCoords = 0.0
                        break
                    end
                end
            end

            setCoords(vec3(coords.x, coords.y, zCoords + 1.0))
        end

        FreezeEntityPosition(entity, false)
    end
elseif IS_RDR3 then
    function GAME.Teleport(entity, coords, options)
        if entity == -1 then
            entity = PlayerPedId()
        end

        if not options then options = {} end
        options.ignoreWater = not not options.ignoreWater

        local function setCoords(_coords)
            if options.heading then
                if options.noOffset then
                    SetEntityCoordsAndHeadingNoOffset(entity, coords.x, coords.y, coords.z, options.heading, false, false)
                else
                    SetEntityCoordsAndHeading(entity, coords.x, coords.y, coords.z, options.heading, false, false, false)
                end
            else
                if options.noOffset then
                    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, true)
                else
                    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false)
                end
            end
        end

        setCoords(coords)

        if not options.findGround then
            GAME.RequestCollisionAtCoords(coords, nil, function()
                setCoords(coords)
            end)
        else
            local zCoords = -500.0
            while true do
                zCoords += 10.0
                RequestCollisionAtCoord(coords.x, coords.y, zCoords)
                Wait(0)
                local foundGround, _zCoords = GetGroundZFor_3dCoord(coords.x, coords.y, zCoords, options.ignoreWater)
                if foundGround then
                    zCoords = _zCoords
                    break
                else
                    if zCoords >= 1000.0 then
                        zCoords = 0.0
                        break
                    end
                end
            end

            setCoords(vec3(coords.x, coords.y, zCoords))
        end
    end
end

if IS_GTA5 then
    local trackedToEntities = {}

    local trackedToEntityHandlesLen = 0
    local trackedToEntityHandles = {}

    local trackedToPlayers = {}

    local function findTrackedToEntityHandle(toEntity)
        for i = 1, trackedToEntityHandlesLen do
            if trackedToEntityHandles[i] == toEntity then
                return i
            end
        end

        return -1
    end

    local function deleteNetAttachedEntity(netAttachedEntity, trackedToEntityOrPlayer)
        if not trackedToEntityOrPlayer then
            trackedToEntityOrPlayer = netAttachedEntity.toPlayerServerId and
                trackedToPlayers[netAttachedEntity.toPlayerServerId] or
                trackedToEntities[netAttachedEntity.toEntity]
        end

        trackedToEntityOrPlayer.netAttachedEntitiesByKeyIdx[netAttachedEntity.stateKeyIdx] = nil

        DeleteEntity(netAttachedEntity.handle)
        netAttachedEntities[netAttachedEntity.id] = nil

        local netAttachedEntitiesLen = #trackedToEntityOrPlayer.netAttachedEntities
        for i = 1, netAttachedEntitiesLen do
            if trackedToEntityOrPlayer.netAttachedEntities[i].id == netAttachedEntity.id then
                netAttachedEntitiesLen = netAttachedEntitiesLen - 1
                table.remove(trackedToEntityOrPlayer.netAttachedEntities, i)
                break
            end
        end

        if netAttachedEntitiesLen == 0 then
            table.wipe(trackedToEntityOrPlayer)

            if netAttachedEntity.toPlayerServerId then
                trackedToPlayers[netAttachedEntity.toPlayerServerId] = nil
            else
                trackedToEntities[netAttachedEntity.toEntity] = nil

                local trackedToEntityHandleIdx = findTrackedToEntityHandle(netAttachedEntity.toEntity)
                if trackedToEntityHandleIdx ~= -1 then
                    trackedToEntityHandlesLen = trackedToEntityHandlesLen - 1
                    table.remove(trackedToEntityHandles, trackedToEntityHandleIdx)
                end
            end
        end

        IMPOSTEUR.Emit('netAttachedEntity:deleted', netAttachedEntity)
    end

    CreateThread(function()
        while true do
            for i = 1, trackedToEntityHandlesLen do
                local trackedToEntityHandle = trackedToEntityHandles[i]

                if not DoesEntityExist(trackedToEntityHandle) then
                    local trackedToEntity = trackedToEntities[trackedToEntityHandle]

                    for j = 1, #trackedToEntity.netAttachedEntities do
                        local netAttachedEntity = trackedToEntity.netAttachedEntities[j]
                        IO.Debug('entity:netAttachedEntity:deleting', netAttachedEntity.id, 'toEntity deleted')
                        DeleteEntity(netAttachedEntity.handle)
                        netAttachedEntities[netAttachedEntity.id] = nil
                    end

                    table.wipe(trackedToEntity)
                    trackedToEntities[trackedToEntityHandle] = nil

                    trackedToEntityHandlesLen = trackedToEntityHandlesLen - 1
                    table.remove(trackedToEntityHandles, i)

                    break
                end
            end

            Wait(0)
        end
    end)

    RegisterNetEvent('onPlayerDropped', function(playerServerId, playerName, playerId)
        local trackedToPlayer = trackedToPlayers[playerServerId]
        if not trackedToPlayer then
            return
        end

        for i = 1, #trackedToPlayer.netAttachedEntities do
            local netAttachedEntity = trackedToPlayer.netAttachedEntities[i]
            IO.Debug('player:netAttachedEntity:deleting', netAttachedEntity.id, 'player dropped')
            DeleteEntity(netAttachedEntity.handle)
            netAttachedEntities[netAttachedEntity.id] = nil
        end

        table.wipe(trackedToPlayer)
        trackedToPlayers[playerServerId] = nil
    end)

    local function attachNetAttachedEntity(netAttachedEntity)
        local attach = netAttachedEntity.attach
        local boneIdx = 0

        if type(attach.boneTag) == 'number' then
            boneIdx = attach.boneTag <= 0 and attach.boneTag or
                (GetEntityType(netAttachedEntity.toEntity) == rageE.EntityType['Ped'] and GetPedBoneIndex(netAttachedEntity.toEntity, attach.boneTag))
        elseif type(attach.boneTag) == 'string' then
            boneIdx = GetEntityBoneIndexByName(netAttachedEntity.toEntity, attach.boneTag)
        end

        AttachEntityToEntity(
            netAttachedEntity.handle,
            netAttachedEntity.toEntity,
            boneIdx,
            attach.offset.x, attach.offset.y, attach.offset.z,
            attach.rotation.x, attach.rotation.y, attach.rotation.z,
            attach.detachWhenDead,
            attach.detachWhenRagdoll,
            attach.activeCollisions,
            attach.basicAttachIfPed,
            attach.rotOrder,
            attach.attachOffsetIsRelative
        )
    end

    local function createAttachedEntity(netAttachedEntity, toEntity, toPlayerServerId)
        local presentNetAttachedEntity = netAttachedEntities[netAttachedEntity.id]
        if presentNetAttachedEntity then
            local oldState = presentNetAttachedEntity.state
            local stateUpdated = netAttachedEntity.state ~= oldState
            if stateUpdated then
                presentNetAttachedEntity.state = netAttachedEntity.state
            end

            local presentAttach = presentNetAttachedEntity.attach
            local attach = netAttachedEntity.attach

            presentAttach.boneTag = attach.boneTag
            presentAttach.offset = attach.offset
            presentAttach.rotation = attach.rotation
            presentAttach.detachWhenDead = attach.detachWhenDead
            presentAttach.detachWhenRagdoll = attach.detachWhenRagdoll
            presentAttach.activeCollisions = attach.activeCollisions
            presentAttach.basicAttachIfPed = attach.basicAttachIfPed
            presentAttach.rotOrder = attach.rotOrder
            presentAttach.attachOffsetIsRelative = attach.attachOffsetIsRelative

            attachNetAttachedEntity(presentNetAttachedEntity)

            if stateUpdated then
                IMPOSTEUR.Emit('netAttachedEntity:stateUpdated', netAttachedEntity, netAttachedEntity.state, oldState)
            end

            return
        end

        netAttachedEntity.toEntity = toEntity
        netAttachedEntity.toPlayerServerId = toPlayerServerId

        local entity = nil
        local coords = GetEntityCoords(toEntity) - vec3(0.0, 0.0, 50.0)

        if netAttachedEntity.type == rageE.EntityType.Ped then
            local freeModel = Streaming.RequestModel(netAttachedEntity.model)
            entity = CreatePed(4, netAttachedEntity.model, coords.x, coords.y, coords.z, netAttachedEntity.heading, false, false)
            freeModel()
        elseif netAttachedEntity.type == rageE.EntityType.Vehicle then
            local freeModel = Streaming.RequestModel(netAttachedEntity.model)
            entity = CreateVehicle(netAttachedEntity.model, coords.x, coords.y, coords.z, netAttachedEntity.heading, false, false)
            freeModel()
        elseif netAttachedEntity.type == rageE.EntityType.Object then
            local freeModel = Streaming.RequestModel(netAttachedEntity.model)
            entity = CreateObjectNoOffset(netAttachedEntity.model, coords.x, coords.y, coords.z, false, false, true)
            freeModel()
        elseif netAttachedEntity.type == 4 then
            local extra = netAttachedEntity.extra

            do
                local freeCustomModel = nil

                if extra.customModel ~= 0 then
                    freeCustomModel = Streaming.RequestModel(extra.customModel)
                end

                local freeWeaponAsset = Streaming.RequestWeaponAsset(netAttachedEntity.model)
                entity = CreateWeaponObject(netAttachedEntity.model, 0, coords.x, coords.y, coords.z, extra.createDefaultComponents, extra.scale, extra.customModel, false, true)
                freeWeaponAsset()

                if freeCustomModel then
                    freeCustomModel()
                end
            end

            ActivatePhysics(entity)

            if extra.tintIndex ~= -1 then
                SetWeaponObjectTintIndex(entity, extra.tintIndex)
            end

            if extra.liveryColor then
                SetWeaponObjectLiveryColor(entity, extra.liveryColor.camoComponentHash, extra.liveryColor.colorIndex)
            end

            for i = 1, #extra.components do
                local componentHash = extra.components[i]
                local weaponComponentModel = GetWeaponComponentTypeModel(componentHash)
                local freeModel = Streaming.RequestModel(weaponComponentModel)
                GiveWeaponComponentToWeaponObject(entity, componentHash)
                freeModel()
            end
        end

        netAttachedEntity.handle = entity

        attachNetAttachedEntity(netAttachedEntity)

        if toPlayerServerId then
            local trackedToPlayer = trackedToPlayers[toPlayerServerId]
            if not trackedToPlayer then
                trackedToPlayer = { netAttachedEntities = {}, netAttachedEntitiesByKeyIdx = {} }
                trackedToPlayers[toPlayerServerId] = trackedToPlayer
            end

            trackedToPlayer.netAttachedEntities[#trackedToPlayer.netAttachedEntities + 1] = netAttachedEntity
            trackedToPlayer.netAttachedEntitiesByKeyIdx[netAttachedEntity.stateKeyIdx] = netAttachedEntity
        else
            local trackedToEntity = trackedToEntities[toEntity]
            if not trackedToEntity then
                trackedToEntity = { netAttachedEntities = {}, netAttachedEntitiesByKeyIdx = {} }
                trackedToEntities[toEntity] = trackedToEntity

                trackedToEntityHandlesLen = trackedToEntityHandlesLen + 1
                trackedToEntityHandles[trackedToEntityHandlesLen] = toEntity
            end

            trackedToEntity.netAttachedEntities[#trackedToEntity.netAttachedEntities + 1] = netAttachedEntity
            trackedToEntity.netAttachedEntitiesByKeyIdx[netAttachedEntity.stateKeyIdx] = netAttachedEntity
        end

        netAttachedEntities[netAttachedEntity.id] = netAttachedEntity
        IMPOSTEUR.Emit('netAttachedEntityCreated', netAttachedEntity)

        return entity
    end

    AddStateBagChangeHandler('', '', function(bagName, key, value, reserved, replicated)
        if replicated then return end
        local netAttachedEntityLen = ('netAttachedEntity:'):len()
        if string.sub(key, 1, netAttachedEntityLen) ~= 'netAttachedEntity:' then return end

        local stateKeyIdx = tonumber(string.sub(key, netAttachedEntityLen + 1))
        IO.Debug(bagName, key, value, reserved, replicated)
        if not stateKeyIdx or stateKeyIdx < 0 or stateKeyIdx > GAME.GetMaxNetAttachedEntities() then return end

        if string.sub(bagName, 1, ('entity:'):len()) == 'entity:' then
            local toEntityNetId = GAME.GetEntityNetIdFromStateBagName(bagName)
            if toEntityNetId == 0 then return end

            local toEntity = GAME.GetEntityFromNetworkId(toEntityNetId, -1)
            if toEntity == 0 then
                IO.Debug('entity:netAttachedEntity:returned', toEntityNetId, 'entity not found')
                Wait(0)
                if GAME.GetEntityFromNetworkId(toEntityNetId, -1) > 0 then
                    IO.Debug('entity:netAttachedEntity:returned', key, toEntityNetId, 'entity found after waiting one tick')
                end
                return
            end

            if not value then
                IO.Debug('player:netAttachedEntity:processing', toEntityNetId, 'value is nil')
                local trackedToEntity = trackedToEntities[toEntity]
                if not trackedToEntity then
                    return
                end

                local netAttachedEntity = trackedToEntity.netAttachedEntitiesByKeyIdx[stateKeyIdx]
                if not netAttachedEntity then
                    return
                end

                IO.Debug('player:netAttachedEntity:deleting', key, toEntity, 'deleting attached entity')
                deleteNetAttachedEntity(netAttachedEntity, trackedToEntity)

                return
            end

            local netAttachedEntity = GAME.UnpackNetAttachedEntity(value)
            IO.Debug('player:netAttachedEntity:processing', toEntityNetId, 'spawning entity')

            netAttachedEntity.stateKeyIdx = stateKeyIdx

            createAttachedEntity(netAttachedEntity, toEntity, nil)
        elseif string.sub(bagName, 1, ('player:'):len()) == 'player:' then
            local toPlayerServerId = GAME.GetPlayerServerIdFromStateBagName(bagName)
            if toPlayerServerId == 0 then return end

            local toPlayer = GetPlayerFromServerId(toPlayerServerId)
            if toPlayer == -1 then
                IO.Debug('entity:netAttachedEntity:returned', toPlayerServerId, 'player not found')
                return
            end

            local toPlayerPed = GAME.GetPlayerPedFromPlayerId(toPlayer)
            if toPlayerPed == 0 then
                IO.Debug('entity:netAttachedEntity:returned', toPlayerServerId, toPlayer, 'player ped not found')
                return
            end

            if not value then
                IO.Debug('player:netAttachedEntity:processing', key, toPlayerServerId, 'value is nil')
                local trackedToPlayer = trackedToPlayers[toPlayerServerId]
                if not trackedToPlayer then
                    return
                end

                local netAttachedEntity = trackedToPlayer.netAttachedEntitiesByKeyIdx[stateKeyIdx]
                if not netAttachedEntity then
                    return
                end

                IO.Debug('player:netAttachedEntity:deleting', key, toPlayerServerId, 'deleting attached entity')
                deleteNetAttachedEntity(netAttachedEntity, trackedToPlayer)

                return
            end

            local netAttachedEntity = GAME.UnpackNetAttachedEntity(value)
            IO.Debug('player:netAttachedEntity:processing', toPlayerServerId, 'spawning entity')

            netAttachedEntity.stateKeyIdx = stateKeyIdx

            createAttachedEntity(netAttachedEntity, toPlayerPed, toPlayerServerId)
        end
    end)
end

if IS_GTA5 then
    function GAME.SpawnObject(modelName, coords, isNetworked, dynamic, noOffset)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if isNetworked == nil then
            isNetworked = false
        end
        if dynamic == nil then
            dynamic = true
        end
        if noOffset == nil then
            noOffset = false
        end

        local freeModel = Streaming.RequestModel(model)

        local object = nil
        if noOffset then
            object = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, isNetworked, false, dynamic)
        else
            object = CreateObject(model, coords.x, coords.y, coords.z, isNetworked, false, dynamic)
        end

        freeModel()

        if isNetworked then
            local networkId = NetworkGetNetworkIdFromEntity(object)
            SetNetworkIdCanMigrate(networkId, true)
        end

        SetEntityAsMissionEntity(object, false, false)

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        GAME.CreatedObjects[object] = true

        local failTimer = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(object) and failTimer > GetGameTimer() do
            Wait(0)
        end

        return object
    end
elseif IS_RDR3 then
    function GAME.SpawnObject(modelName, coords, isNetworked, dynamic, noOffset)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if isNetworked == nil then
            isNetworked = false
        end
        if dynamic == nil then
            dynamic = true
        end
        if noOffset == nil then
            noOffset = false
        end

        local freeModel = Streaming.RequestModel(model)

        local object = nil
        if noOffset then
            object = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, isNetworked, false, dynamic, false)
        else
            object = CreateObject(model, coords.x, coords.y, coords.z, isNetworked, false, dynamic, false, false)
        end

        freeModel()

        SetEntityAsMissionEntity(object, false, false)

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        GAME.CreatedObjects[object] = true

        local failTimer = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(object) and failTimer > GetGameTimer() do
            Wait(0)
        end

        return object
    end
end

if IS_GTA5 then
    function GAME.SpawnVehicle(modelName, coords, heading, isNetworked)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if isNetworked == nil then
            isNetworked = false
        end
        --print(model, modelName)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, isNetworked, false)
        --freeModel()

        if isNetworked then
            local networkId = NetworkGetNetworkIdFromEntity(vehicle)
            SetNetworkIdCanMigrate(networkId, true)
        end

        SetEntityAsMissionEntity(vehicle, false, false)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehRadioStation(vehicle, "OFF")

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        GAME.CreatedVehicles[vehicle] = true

        local failTimer = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(vehicle) and failTimer > GetGameTimer() do
            Wait(0)
        end
        --print(DoesEntityExist(vehicle), vehicle)
        return vehicle
    end
elseif IS_RDR3 then
    function GAME.SpawnVehicle(modelName, coords, heading, isNetworked)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if isNetworked == nil then
            isNetworked = false
        end

        local freeModel = Streaming.RequestModel(model)
        local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, isNetworked, false, false, false)
        freeModel()

        SetEntityAsMissionEntity(vehicle, false, false)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        GAME.CreatedVehicles[vehicle] = true

        local failTimer = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(vehicle) and failTimer > GetGameTimer() do
            Wait(0)
        end

        return vehicle
    end
end

if IS_GTA5 then
    function GAME.SpawnPed(pedType, modelName, coords, heading, isNetworked)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if isNetworked == nil then
            isNetworked = false
        end

        local freeModel = Streaming.RequestModel(model)
        local ped = CreatePed(pedType, model, coords.x, coords.y, coords.z, heading, isNetworked, false)
        freeModel()

        GAME.CreatedPeds[ped] = true

        if isNetworked then
            local networkId = NetworkGetNetworkIdFromEntity(ped)
            SetNetworkIdCanMigrate(networkId, true)
        end

        SetEntityAsMissionEntity(ped, false, false)

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        local failTimer = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(ped) and failTimer > GetGameTimer() do
            Wait(0)
        end

        return ped
    end
elseif IS_RDR3 then
    function GAME.SpawnPed(modelName, coords, heading, isNetworked)
        local model = type(modelName) == "number" and modelName or GetHashKey(modelName)
        if isNetworked == nil then
            isNetworked = false
        end

        local freeModel = Streaming.RequestModel(model)
        local ped = CreatePed(model, coords.x, coords.y, coords.z, heading, isNetworked, false, false, false)
        freeModel()

        GAME.CreatedPeds[ped] = true

        SetEntityAsMissionEntity(ped, false, false)
        SetRandomOutfitVariation(ped, true)

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        local failTimer = GetGameTimer() + 2000
        while not HasCollisionLoadedAroundEntity(ped) and failTimer > GetGameTimer() do
            Wait(0)
        end

        return ped
    end
end

function GAME.DeleteEntity(entity)
    if not DoesEntityExist(entity) then
        return
    end

    SetEntityAsMissionEntity(entity, false, false)
    DeleteEntity(entity)

    if GAME.CreatedPeds[entity] then
        GAME.CreatedPeds[entity] = nil
    elseif GAME.CreatedObjects[entity] then
        GAME.CreatedObjects[entity] = nil
    elseif GAME.CreatedVehicles[entity] then
        GAME.CreatedVehicles[entity] = nil
    end

    IO.Debug('GAME entity deleted', entity)
end

function GAME.IsVehicleEmpty(vehicle)
    local passengers, driverSeatFree = GetVehicleNumberOfPassengers(vehicle), IsVehicleSeatFree(vehicle, -1)
    return passengers == 0 and driverSeatFree
end

function GAME.GetClosestEntity(entities, coords, modelFilter, filterFn, playerEntities)
    local entitiesLen = #entities
    local closestEntity, closestEntityDistance = -1, -1
    coords = coords or GetEntityCoords(PlayerPedId())

    if modelFilter then
        local filteredEntities, filteredEntitiesLen = {}, 0

        for i = 1, entitiesLen do
            if modelFilter[GetEntityModel(entities[i])] then
                filteredEntitiesLen = filteredEntitiesLen + 1
                filteredEntities[filteredEntitiesLen] = entities[i]
            end
        end

        entities = filteredEntities
        entitiesLen = filteredEntitiesLen
    end

    if filterFn then
        local filteredEntities, filteredEntitiesLen = {}, 0

        for i = 1, entitiesLen do
            if filterFn(entities[i]) then
                filteredEntitiesLen = filteredEntitiesLen + 1
                filteredEntities[filteredEntitiesLen] = entities[i]
            end
        end

        entities = filteredEntities
        entitiesLen = filteredEntitiesLen
    end

    for i = 1, entitiesLen do
        local distance = #(coords - GetEntityCoords(entities[i]))

        if closestEntityDistance == -1 or distance < closestEntityDistance then
            closestEntity, closestEntityDistance = entities[i], distance
        end
    end

    if playerEntities then
        closestEntity = NetworkGetPlayerIndexFromPed(closestEntity)
    end

    return closestEntity, closestEntityDistance
end

function GAME.GetEntitiesInArea(entities, coords, maxDistance, modelFilter, playerEntities)
    local nearbyEntities, nearbyEntitiesLen = {}, 0
    coords = coords or GetEntityCoords(PlayerPedId())

    if modelFilter then
        local filteredEntities = {}

        for i = 1, #entities do
            if modelFilter[GetEntityModel(entities[i])] then
                filteredEntities[#filteredEntities + 1] = entities[i]
            end
        end

        entities = filteredEntities
    end

    for i = 1, #entities do
        if #(coords - GetEntityCoords(entities[i])) < maxDistance then
            nearbyEntitiesLen = nearbyEntitiesLen + 1
            nearbyEntities[nearbyEntitiesLen] = entities[i]
        end
    end

    if playerEntities then
        for i = 1, #entities do
            entities[i] = NetworkGetPlayerIndexFromPed(entities[i])
        end
    end

    return nearbyEntities
end

function GAME.GetObjects()
    return GetGamePool('CObject')
end

function GAME.GetVehicles()
    return GetGamePool('CVehicle')
end

function GAME.GetPeds(onlyOtherPeds)
    if onlyOtherPeds then
        local peds = GetGamePool('CPed')
        local playerPedId = PlayerPedId()

        for i = 1, #peds do
            if peds[i] == playerPedId then
                table.remove(peds, i)
                break
            end
        end

        return peds
    end

    return GetGamePool('CPed')
end

function GAME.GetPlayers(onlyOtherPlayers, returnPeds)
    local players, myPlayer = {}, PlayerId()
    local activePlayers = GetActivePlayers()

    for i = 1, #activePlayers, 1 do
        local ped = GetPlayerPed(activePlayers[i])

        if DoesEntityExist(ped) and ((onlyOtherPlayers and activePlayers[i] ~= myPlayer) or not onlyOtherPlayers) then
            if returnPeds then
                table.insert(players, ped)
            else
                table.insert(players, activePlayers[i])
            end
        end
    end

    return players
end

function GAME.GetClosestObject(coords, modelFilter, filterFn)
    return GAME.GetClosestEntity(GAME.GetObjects(), coords, modelFilter, filterFn, false)
end

function GAME.GetClosestVehicle(coords, modelFilter, filterFn)
    return GAME.GetClosestEntity(GAME.GetVehicles(), coords, modelFilter, filterFn, false)
end

function GAME.GetClosestPed(coords, modelFilter, filterFn)
    return GAME.GetClosestEntity(GAME.GetPeds(true), coords, modelFilter, filterFn, false)
end

function GAME.GetClosestPlayer(coords, modelFilter, filterFn)
    return GAME.GetClosestEntity(GAME.GetPlayers(true, true), coords, modelFilter, filterFn, true)
end

function GAME.GetObjectsInArea(coords, maxDistance, modelFilter)
    return GAME.GetEntitiesInArea(GAME.GetObjects(), coords, maxDistance, modelFilter)
end

function GAME.GetVehiclesInArea(coords, maxDistance, modelFilter)
    return GAME.GetEntitiesInArea(GAME.GetVehicles(), coords, maxDistance, modelFilter)
end

function GAME.GetPedsInArea(coords, maxDistance, modelFilter)
    return GAME.GetEntitiesInArea(GAME.GetPeds(), coords, maxDistance, modelFilter)
end

function GAME.GetPlayersInArea(coords, maxDistance, modelFilter)
    return GAME.GetEntitiesInArea(GAME.GetPlayers(true, true), coords, maxDistance, modelFilter, true)
end

function GAME.IsSpawnPointClear(coords, maxDistance, modelFilter)
    return #GAME.GetVehiclesInArea(coords, maxDistance, modelFilter) == 0
end

function GAME.GetVehicleInFront(entity)
    local entityCoords = GetEntityCoords(entity, false)
    local forwardCoords = GetOffsetFromEntityInWorldCoords(entity, 0.0, 4.0, 0.0)

    local shapeTestHandle = StartShapeTestLosProbe(
        entityCoords.x, entityCoords.y, entityCoords.z,
        forwardCoords.x, forwardCoords.y, forwardCoords.z,
        2,
        GetEntityType(entity) == rageE.EntityType.Ped and GetVehiclePedIsIn(entity, false) or 0,
        0
    )

    local shapeTestStatus, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTestHandle)
    while shapeTestStatus ~= 0 and shapeTestStatus ~= 2 do
        Wait(0)
        shapeTestStatus, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTestHandle)
    end

    return (shapeTestStatus == 2 and hit) and entityHit or 0
end

function GAME.StartParticleFx(assetName, effectName, looped, target, offset, rot, scale, boneIndex)
    Streaming.RequestNamedPtfxAsset(assetName)
    UseParticleFxAsset(assetName)

    local ptfx = nil

    if looped then
        if type(target) == 'number' then
            offset = offset or vec3(0)
            rot = rot or vec3(0)

            if boneIndex then
                ptfx = StartParticleFxLoopedOnEntityBone(effectName, target, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneIndex, scale or 1.0, false, false, false)
            else
                ptfx = StartParticleFxLoopedOnEntity(effectName, target, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
            end
        else
            ptfx = StartParticleFxLoopedAtCoord(effectName, target, rot.x, rot.y, rot.z, scale or 1.0, false, false, false, false)
        end
    else
        if type(target) == 'number' then
            offset = offset or vec3(0)
            rot = rot or vec3(0)

            if boneIndex then
                ptfx = StartParticleFxNonLoopedOnPedBone(effectName, target, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, boneIndex, scale or 1.0, false, false, false)
            else
                ptfx = StartParticleFxNonLoopedOnEntity(effectName, target, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
            end
        else
            ptfx = StartParticleFxNonLoopedAtCoord(effectName, target, rot.x, rot.y, rot.z, scale or 1.0, false, false, false)
        end
    end

    RemoveNamedPtfxAsset(assetName)

    return ptfx
end

function GAME.GetSkin(ped)
    if DoesEntityExist(ped) then
    end
end

function GAME.SetSkin(ped)
    if DoesEntityExist(ped) then
    end
end

if IS_GTA5 then
    function GAME.Notification(msg, flash, saveToBrief, hudColorIndex)
        if saveToBrief == nil then
            saveToBrief = true
        end
        if flash == nil then
            flash = false
        end
        AddTextEntry("GAME:Notification", msg)
        BeginTextCommandThefeedPost("GAME:Notification")
        if hudColorIndex then
            ThefeedNextPostBackgroundColor(hudColorIndex)
        end
        EndTextCommandThefeedPostTicker(flash, saveToBrief)
    end
elseif IS_RDR3 then
    function GAME.Notification(msg)
        local optionsView = DataView.ArrayBuffer(56)
            :SetInt32(0, -2)
            :SetInt64(8, 0)
            :SetInt64(16, 0)
            :SetInt32(24, 0) -- flags : 1 - ?, 3 - no sound

        local msgVarString = VarString(10, "LITERAL_STRING", msg)

        local msgView = DataView.ArrayBuffer(8 * 2)
                                :SetInt64(8, msgVarString)

        UiFeedPostFeedTicker(optionsView:Buffer(), msgView:Buffer(), true)
    end
end

function GAME.AdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if saveToBrief == nil then
        saveToBrief = true
    end
    if flash == nil then
        flash = false
    end
    AddTextEntry("GAME:AdvancedNotification", msg)
    BeginTextCommandThefeedPost("GAME:AdvancedNotification")
    if hudColorIndex then
        ThefeedNextPostBackgroundColor(hudColorIndex)
    end
    local notificationId = EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
    EndTextCommandThefeedPostTicker(flash, saveToBrief)
    return notificationId
end

function GAME.RemoveNotification(id)
    ThefeedRemoveItem(id)
end

if IS_GTA5 then
    function GAME.HelpText(msg, duration, beep)
        AddTextEntry("GAME:HelpText", msg)

        if duration == nil then
            DisplayHelpTextThisFrame("GAME:HelpText", false)
        else
            if beep == nil then
                beep = true
            end
            BeginTextCommandDisplayHelp("GAME:HelpText")
            EndTextCommandDisplayHelp(0, false, beep, duration)
        end
    end
elseif IS_RDR3 then
    function GAME.HelpText(msg, duration)
        local optionsView = DataView.ArrayBuffer(56)
            :SetInt32(0, duration or -1)
            :SetInt64(8, 0)
            :SetInt64(16, 0)
            :SetInt32(24, 0) -- flags : 1 - ?, 3 - no sound

        local msgVarString = VarString(10, "LITERAL_STRING", msg)

        local msgView = DataView.ArrayBuffer(8 * 2)
            :SetInt64(8, msgVarString)

        return UiFeedPostHelpText(optionsView:Buffer(), msgView:Buffer(), true)
    end
end

if IS_RDR3 then
    --[[
    function GAME.UpdateNotification(msg, duration)
        local optionsView = DataView.ArrayBuffer(56)
            :SetInt32(0, duration or -2)
            :SetInt64(8, 0)
            :SetInt64(16, 0)
            :SetInt32(24, 0) -- flags : 1 - ?, 3 - no sound

        local msgVarString = VarString(10, "LITERAL_STRING", msg)

        local msgView = DataView.ArrayBuffer(8 * 3)
            :SetInt64(8, msgVarString)
            :SetInt64(16, GetHashKey("COLOR_WHITE"))

        UiFeedPostGameUpdateShard(optionsView:Buffer(), msgView:Buffer(), true)
    end
    ]]

    function GAME.LocationNotification(location, msg, duration)
        local optionsView = DataView.ArrayBuffer(56)
            :SetInt32(0, duration or -2)
            :SetInt64(8, 0)
            :SetInt64(16, 0)
            :SetInt32(24, 0) -- flags : 1 - ?, 3 - no sound

        local locationVarString = VarString(10, "LITERAL_STRING", location)
        local msgVarString = VarString(10, "LITERAL_STRING", msg)

        local msgView = DataView.ArrayBuffer(8 * 3)
            :SetInt64(8, locationVarString)
            :SetInt64(16, msgVarString)

        UiFeedPostLocationShard(optionsView:Buffer(), msgView:Buffer(), true, true)
    end

    function GAME.MissionName(msg, duration)
        local optionsView = DataView.ArrayBuffer(56)
            :SetInt32(0, duration or -2)
            :SetInt64(8, 0)
            :SetInt64(16, 0)
            :SetInt32(24, 0) -- flags : 1 - ?, 3 - no sound

        local msgVarString = VarString(10, "LITERAL_STRING", msg)

        local msgView = DataView.ArrayBuffer(8 * 2)
            :SetInt64(8, msgVarString)

        UiFeedPostMissionName(optionsView:Buffer(), msgView:Buffer(), false)
    end
end

function GAME.FloatingHelpText(msg, coords)
    AddTextEntry("GAME:FloatingHelpText", msg)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp("GAME:FloatingHelpText")
    EndTextCommandDisplayHelp(2, false, false, -1)
end

if IS_GTA5 then
    function GAME.MissionText(msg, duration)
        ClearPrints()

        AddTextEntry("GAME:MissionText", msg)
        BeginTextCommandPrint("GAME:MissionText")
        EndTextCommandPrint(duration or 0, true)
    end
elseif IS_RDR3 then
    function GAME.MissionText(msg, duration)
        GAME.ClearMissionText()

        local optionsView = DataView.ArrayBuffer(56)
            :SetInt32(0, duration or -1)
            :SetInt64(8, 0)
            :SetInt64(16, 0)
            :SetInt32(24, 0) -- flags : 1 - ?, 3 - no sound

        local msgVarString = VarString(10, "LITERAL_STRING", msg)

        local msgView = DataView.ArrayBuffer(8 * 2)
            :SetInt64(8, msgVarString)

        UiFeedPostObjective(optionsView:Buffer(), msgView:Buffer(), true)
    end

    function GAME.ClearMissionText()
        UiFeedClearChannel(3, true, true)
    end
end

if IS_GTA5 then
    ---@param loadingText string
    ---@param spinnerType number
    function GAME.LoadingPrompt(loadingText, spinnerType)
        if BusyspinnerIsOn() then
            BusyspinnerOff()
        end

        local spinnerText = ""

        if loadingText then
            AddTextEntry("GAME:LoadingPrompt", loadingText)
            spinnerText = "GAME:LoadingPrompt"
        end

        BeginTextCommandBusyspinnerOn(spinnerText)
        EndTextCommandBusyspinnerOn(spinnerType)
    end
elseif IS_RDR3 then
    ---@param loadingText string
    function GAME.LoadingPrompt(loadingText)
        if BusyspinnerIsOn() then
            BusyspinnerOff()
        end

        local spinnerVarString = ""

        if loadingText then
            spinnerVarString = VarString(10, "LITERAL_STRING", loadingText)
        end

        BusyspinnerSetText(spinnerVarString)
    end
end

function GAME.LoadingPromptHide()
    if BusyspinnerIsOn() then
        BusyspinnerOff()
    end
end

function GAME.GetScreenResolution()
    -- rdr3 doesn't have GetActiveScreenResolution
    if IS_RDR3 then
        return vec2(1920, 1080)
    end

    return vec2(GetActiveScreenResolution())
end

-- converts pixel to viewport units
function GAME.PxToVp(coords)
    return coords / GAME.GetScreenResolution()
end

function GAME.PxToVpX(x)
    return x / GAME.GetScreenResolution().x
end

function GAME.PxToVpY(y)
    return y / GAME.GetScreenResolution().y
end

-- converts viewport units to pixel
function GAME.VpToPx(coords)
    return coords * GAME.GetScreenResolution()
end

function GAME.VpToPxX(x)
    return x * GAME.GetScreenResolution().x
end

function GAME.VpToPxY(y)
    return y * GAME.GetScreenResolution().y
end

function GAME.GetMinimapCoordsAndSize()
    local aspectRatio = GetAspectRatio(false)
    local resolution = GAME.GetScreenResolution()

    local scaleX = 1 / resolution.x
    local scaleY = 1 / resolution.y

    local minimapX, minimapY, minimapWidth, minimapHeight = nil, nil, nil, nil

    SetScriptGfxAlign(string.byte('L'), string.byte('B'))

    if IsBigmapActive() then
        minimapX, minimapY = GetScriptGfxPosition(-0.003975, 0.022)
        minimapWidth = scaleX * (resolution.x / (2.52 * aspectRatio))
        minimapHeight = scaleY * (resolution.y / (2.3374))
    else
        minimapX, minimapY = GetScriptGfxPosition(-0.0045, 0.002)
        minimapWidth = scaleX * (resolution.x / (4 * aspectRatio))
        minimapHeight = scaleY * (resolution.y / (5.674))
    end

    ResetScriptGfxAlign()

    return vec2(minimapX, 1.0 - minimapY), vec2(minimapWidth, minimapHeight)
end

if IS_GTA5 then
    local function getCharacterCount(str)
        local chars = 0

        for c in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
            chars = chars + 1
        end

        return chars
    end

    local function addTextComponentSubstrings(text)
        local chars = getCharacterCount(text)

        if chars < 100 then
            AddTextComponentSubstringPlayerName(text)
        else
            local strsNeeded = (chars % 100 == 0) and chars / 100 or (chars / 100) + 1

            for i = 0, strsNeeded do
                AddTextComponentSubstringPlayerName(text:sub(i * 100, (i * 100) + 100))
            end
        end
    end

    ---@param text string
    ---@param coords vec2
    ---@param size number
    ---@param font number
    ---@param color number[]
    ---@param centre boolean
    function GAME.DrawText(text, coords, size, font, color, centre)
        size = size or 1.0
        font = font or 0
        color = color or { 255, 255, 255, 255 }

        SetTextScale(size, size)
        SetTextFont(font)
        SetTextColour(color[1], color[2], color[3], color[4])
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()

        if centre then
            SetTextCentre(true)
        end

        if DoesTextLabelExist(text) then
            BeginTextCommandDisplayText(text)
        else
            BeginTextCommandDisplayText("CELL_EMAIL_BCON")
            addTextComponentSubstrings(text)
        end

        EndTextCommandDisplayText(coords.x, coords.y)
    end

    function GAME.DrawText3D(text, coords, size, font, color, centre, noRelativeSize)
        size = size or 1.0
        font = font or 0
        color = color or { 255, 255, 255, 255 }
        if centre == nil then
            centre = true
        end

        local camCoords = GetFinalRenderedCamCoord()

        local scale = nil

        if noRelativeSize then
            scale = size
        else
            local distance = #(coords - camCoords)
            scale = (size / distance) * 2
        end

        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov

        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(font)
        SetTextColour(color[1], color[2], color[3], color[4])
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()

        if centre then
            SetTextCentre(true)
        end

        SetDrawOrigin(coords.x, coords.y, coords.z, 0)
        BeginTextCommandDisplayText("CELL_EMAIL_BCON")
        addTextComponentSubstrings(text)
        EndTextCommandDisplayText(0.0, 0.0)
        ClearDrawOrigin()
    end
elseif IS_RDR3 then
    function GAME.DrawText(text, coords, size, font, color, centre, noRelativeSize)
        size = size or 1.0
        font = font or 0
        color = color or { 255, 255, 255, 255 }

        SetTextScale(size, size)
        SetTextFontForCurrentCommand(font)
        SetTextColor(color[1], color[2], color[3], color[4])

        if centre then
            SetTextCentre(true)
        end

        local varStr = CreateVarString(10, 'LITERAL_STRING', text)
        BgDisplayText(varStr, coords.x, coords.y)
    end

    function GAME.DrawText3D(text, coords, size, font, color, centre)
        size = size or 1.0
        font = font or 0
        color = color or { 255, 255, 255, 255 }

        local camCoords = GetFinalRenderedCamCoord()

        local scale = nil

        if noRelativeSize then
            scale = size
        else
            local distance = #(coords - camCoords)
            scale = (size / distance) * 2
        end

        local fov = (1 / GetGameplayCamFov()) * 100
        scale = scale * fov

        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFontForCurrentCommand(font)
        SetTextColor(color[1], color[2], color[3], color[4])

        if centre then
            SetTextCentre(true)
        end

        SetDrawOrigin(coords.x, coords.y, coords.z, 0)
        local varStr = CreateVarString(10, 'LITERAL_STRING', text)
        BgDisplayText(varStr, 0.0, 0.0)
        ClearDrawOrigin()
    end
end

function GAME.DrawSprite3D(coords, txd, txn, texWidth, texHeight, size, color)
    local resolution = GAME.GetScreenResolution()
    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(coords - camCoords)

    size = size or 1.0

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    if not color then
        DrawSprite(txd, txn, 0.0, 0.0, (texWidth / resolution.x) * scale, (texHeight / resolution.y) * scale, 0.0, 255, 255, 255, 255)
    else
        DrawSprite(txd, txn, 0.0, 0.0, (texWidth / resolution.x) * scale, (texHeight / resolution.y) * scale, 0.0, color[1], color[2], color[3], color[4])
    end
    ClearDrawOrigin()
end

function GAME.KeyboardInput(entryTitle, textEntry, inputText, maxLength)
    AddTextEntry(entryTitle, textEntry)
    DisplayOnscreenKeyboard(IS_GTA5 and 1 or 0, entryTitle, '', inputText or '', '', '', '', maxLength or 50)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(100)
        return result, false
    end

    Wait(100)
    return '', true
end

function GAME.IsKeyboardInputVisible()
    return UpdateOnscreenKeyboard() == 0
end

if IS_GTA5 then
    function GAME.FreezePlayer(freeze, withInvincibility)
        local playerId = PlayerId()
        local playerPed = PlayerPedId()

        SetPlayerControl(playerId, not freeze, 1 << 8)

        if IsPedInAnyVehicle(playerPed, false) then
            local pedVehicle = GetVehiclePedIsIn(playerPed, false)
            TaskLeaveVehicle(playerPed, pedVehicle, 16)
        end

        ClearPedTasksImmediately(playerPed)
        FreezeEntityPosition(playerPed, freeze)

        if withInvincibility or not freeze then
            SetPlayerInvincible(playerId, freeze)
        end

        if not freeze then
            SetFocusEntity(playerPed)
        end
    end
elseif IS_RDR3 then
    function GAME.FreezePlayer(freeze, withInvincibility)
        local playerId = PlayerId()
        local playerPed = PlayerPedId()

        SetPlayerControl(playerId, not freeze, 1 << 8, false)

        if IsPedInAnyVehicle(playerPed, false) then
            local pedVehicle = GetVehiclePedIsIn(playerPed, false)
            TaskLeaveVehicle(playerPed, pedVehicle, 16)
        end

        if not IsPedFatallyInjured(playerPed) then
            ClearPedTasksImmediately(playerPed, false, true)
        end

        FreezeEntityPosition(playerPed, freeze)

        if withInvincibility or not freeze then
            SetPlayerInvincible(playerId, freeze)
        end

        if not freeze then
            SetFocusEntity(playerPed)
        end
    end
end

if IS_GTA5 then
    local basegameShopData = nil
    local basegameShopEnums = {}
    local basegameShopByHashNames = { components = {}, props = {} }

    Citizen.CreateThreadNow(function()
        basegameShopData = Utils.LoadJsonFile(CURRENT_RESOURCE, 'shared/data/gta5/basegame_shop_collection.json')

                if componentDrawables then
                    local basegamePedShopComponentEnums = {}
                    basegamePedShopEnums.components[componentId] = basegamePedShopComponentEnums

                    local enumTracker = 0

                    for drawableIdx = 1, #componentDrawables do
                        local drawable = componentDrawables[drawableIdx]

                        for textureIdx = 1, #drawable.Textures do
                            local tex = drawable.Textures[textureIdx]
                            local hashName = GetHashKey(tex.NameHash) & 0xFFFFFFFF

                            basegamePedShopComponentEnums[enumTracker] = hashName
                            enumTracker = enumTracker + 1

                            basegameShopByHashNames.components[hashName] = {
                                drawable = drawable.DrawableId,
                                texture = textureIdx - 1,
                                cost = tex.Price,
                                componentType = componentId,
                                gxt = tex.NameGXT
                            }
                        end
                    end

            for propId = 0, (rageE.PedPropNUM - 1) do
                local propDrawables = basegameShopPedData.Props[tostring(propId)]

                if propDrawables then
                    local basegamePedShopPropEnums = {}
                    basegamePedShopEnums.props[propId] = basegamePedShopPropEnums

                    local enumTracker = 0

                    for drawableIdx = 1, #propDrawables do
                        local drawable = propDrawables[drawableIdx]

                        for textureIdx = 1, #drawable.Textures do
                            local tex = drawable.Textures[textureIdx]
                            local hashName = GetHashKey(tex.NameHash) & 0xFFFFFFFF

                            basegamePedShopPropEnums[enumTracker] = hashName
                            enumTracker = enumTracker + 1

                            basegameShopByHashNames.props[hashName] = {
                                drawable = drawable.DrawableId,
                                texture = textureIdx - 1,
                                cost = tex.Price,
                                componentType = propId,
                                gxt = tex.NameGXT
                            }
                        end
                    end
                end
            end
        end
    end)

    function GAME.GetFakeHashNameForComponent(ped, componentId, drawableId, textureId)
        local pedModelStr = tostring(GetEntityModel(ped) & 0xFFFFFFFF)

        local basegameComponents = basegameShopData[pedModelStr].Components
        if not basegameComponents then
            return 0
        end

        local basegameComponentDrawables = basegameComponents[tostring(componentId)]
        if not basegameComponentDrawables then
            return 0
        end

        local drawable = basegameComponentDrawables[drawableId + 1]
        if not drawable then
            return 0
        end

        local tex = drawable.Textures[textureId + 1]
        if not tex then
            return 0
        end

        return tex.NameHash and GetHashKey(tex.NameHash) or 0
    end

    function GAME.GetFakeHashNameForProp(ped, propId, drawableId, textureId)
        local pedModelStr = tostring(GetEntityModel(ped) & 0xFFFFFFFF)

        local basegameProps = basegameShopData[pedModelStr].Props
        if not basegameProps then
            return 0
        end

        local basegamePropDrawables = basegameProps[tostring(propId)]
        if not basegamePropDrawables then
            return 0
        end

        local drawable = basegamePropDrawables[drawableId + 1]
        if not drawable then
            return 0
        end

        local tex = drawable.Textures[textureId + 1]
        if not tex then
            return 0
        end

        return tex.NameHash and GetHashKey(tex.NameHash) or 0
    end

    function GAME.GetFakeHashNameForComponentEnumValue(ped, componentId, enumValue)
        local pedModelStr = tostring(GetEntityModel(ped) & 0xFFFFFFFF)

        local basegameComponents = basegameShopEnums[pedModelStr].components
        if not basegameComponents then
            return 0
        end

        local basegameComponentEnums = basegameComponents[componentId]
        if not basegameComponentEnums then
            return 0
        end

        return basegameComponentEnums[enumValue] or 0
    end

    function GAME.GetFakeHashNameForPropEnumValue(ped, propId, enumValue)
        local pedModelStr = tostring(GetEntityModel(ped) & 0xFFFFFFFF)

        local basegameProps = basegameShopEnums[pedModelStr].props
        if not basegameProps then
            return 0
        end

        local basegamePropEnums = basegameProps[propId]
        if not basegamePropEnums then
            return 0
        end

        return basegamePropEnums[enumValue] or 0
    end

    function GAME.GetFakeShopPedComponent(hashName)
        return basegameShopByHashNames.components[hashName & 0xFFFFFFFF]
    end

    function GAME.GetFakeShopPedProp(hashName)
        return basegameShopByHashNames.props[hashName & 0xFFFFFFFF]
    end

    function GAME.GetPedHeadBlendData(ped)
        local view = Structs.New("PedHeadBlendData")
        local success = Citizen.InvokeNative(0x2746BD9D88C5C5D0, ped, view:Buffer(), Citizen.ReturnResultAnyway())
        return success, success and view:Parse() or { }
    end

    function GAME.GetDlcWeaponData(dlcWeaponIndex)
        local view = Structs.New("ShopWeaponData")
        local success = Citizen.InvokeNative(0x79923CD21BECE14E, dlcWeaponIndex, view:Buffer(), Citizen.ReturnResultAnyway())
        return success, success and view:Parse() or { }
    end

    function GAME.GetDlcWeaponDataSp(dlcWeaponIndex)
        local view = Structs.New("ShopWeaponData")
        local success = Citizen.InvokeNative(0x4160B65AE085B5A9, dlcWeaponIndex, view:Buffer(), Citizen.ReturnResultAnyway())
        return success, success and view:Parse() or { }
    end

    function GAME.GetDlcWeaponComponentData(dlcWeaponIndex, dlcWeapCompIndex)
        local view = Structs.New("ShopWeaponComponentData")
        local success = Citizen.InvokeNative(0x6CF598A2957C2BF8, dlcWeaponIndex, dlcWeapCompIndex, view:Buffer(), Citizen.ReturnResultAnyway())
        return success, success and view:Parse() or { }
    end

    function GAME.GetDlcWeaponComponentDataSp(dlcWeaponIndex, dlcWeapCompIndex)
        local view = Structs.New("ShopWeaponComponentData")
        local success = Citizen.InvokeNative(0xAD2A7A6DFF55841B, dlcWeaponIndex, dlcWeapCompIndex, view:Buffer(), Citizen.ReturnResultAnyway())
        return success, success and view:Parse() or { }
    end

    function GAME.GetTattooShopDlcItemData(characterType, decorationIndex)
        local view = Structs.New("TattooShopItem")
        local success = Citizen.InvokeNative(0xFF56381874F82086, characterType, decorationIndex, view:Buffer(), Citizen.ReturnResultAnyway())
        return success, success and view:Parse() or { }
    end

    function GAME.GetShopPedComponent(componentHash)
        local view = Structs.New("ShopPedComponent")
        Citizen.InvokeNative(0x74C0E2A57EC66760, componentHash, view:Buffer(), Citizen.ReturnResultAnyway())
        return view:Parse()
    end

    function GAME.GetShopPedProp(componentHash)
        local view = Structs.New("ShopPedComponent")
        Citizen.InvokeNative(0x5D5CAFF661DDF6FC, componentHash, view:Buffer(), Citizen.ReturnResultAnyway())
        return view:Parse()
    end

    function GAME.GetPedsFreemodeParents()
        local maleParents, femaleParents = { }, { }

        local firstMaleIndex, numMale = GetPedHeadBlendFirstIndex(0), GetPedHeadBlendNumHeads(0)
        for i = 0, numMale - 1 do
            maleParents[#maleParents + 1] = { id = firstMaleIndex + i, gxtName = ("Male_%u"):format(i) }
        end

        local firstFemaleIndex, numFemale = GetPedHeadBlendFirstIndex(1), GetPedHeadBlendNumHeads(1)
        for i = 0, numFemale - 1 do
            femaleParents[#femaleParents + 1] = { id = firstFemaleIndex + i, gxtName = ("Female_%u"):format(i) }
        end

        local firstMaleDLCIndex, numMaleDLC = GetPedHeadBlendFirstIndex(2), GetPedHeadBlendNumHeads(2)
        for i = 0, numMaleDLC - 1 do
            maleParents[#maleParents + 1] = { id = firstMaleDLCIndex + i, gxtName = ("Special_Male_%u"):format(i) }
        end

        local firstFemaleDLCIndex, numFemaleDLC = GetPedHeadBlendFirstIndex(3), GetPedHeadBlendNumHeads(3)
        for i = 0, numFemaleDLC - 1 do
            femaleParents[#femaleParents + 1] = { id = firstFemaleDLCIndex + i, gxtName = ("Special_Female_%u"):format(i) }
        end

        return maleParents, femaleParents
    end

    function GAME.GetDlcDrawTag(nameHash)
        if nameHash == 0 then
            return -1
        end

        for i = 0, 15 do
            if DoesShopPedApparelHaveRestrictionTag(nameHash, GetHashKey(('DRAW_%u'):format(i)), rageE.ShopPedApparel.COMPONENT) then
                return i
            end
        end

        return -1
    end

    local BASE_JBIBS_TORSO_IDS_M = {
        [0] = 0,
        [1] = 0,
        [2] = 2,
        [3] = 1,
        [4] = 1,
        [5] = 5,
        [6] = 12,
        [7] = 1,
        [8] = 8,
        [9] = 0,
        [10] = 1,
        [11] = 11,
        [12] = 12,
        [13] = 11,
        [14] = 14,
        [15] = 15
    }

    local BASE_JBIBS_TORSO_IDS_F = {
        [0] = 0,
        [1] = 5,
        [2] = 2,
        [3] = 3,
        [4] = 4,
        [5] = 4,
        [6] = 5,
        [7] = 6,
        [8] = 5,
        [9] = 9,
        [10] = 7,
        [11] = 11,
        [12] = 12,
        [13] = 4,
        [14] = 14,
        [15] = 15
    }

    function GAME.GetProperTorso(ped, drawable, texture) -- TODO: Convert whole ped_component_data.sch GET_TORSO_FOR_SPECIAL_AND_JBIB_COMBO function
        local model = GetEntityModel(ped)

        if model ~= `mp_m_freemode_01` and model ~= `mp_f_freemode_01` then
            return -1, -1
        end

        if drawable <= 15 then
            local baseJbibTorsoId = model == `mp_m_freemode_01` and BASE_JBIBS_TORSO_IDS_M[drawable] or BASE_JBIBS_TORSO_IDS_F[drawable]
            return baseJbibTorsoId, 0
        end

        local topHash = GetHashNameForComponent(ped, rageE.PedComponent.Torso2, drawable, texture)

        if model == `mp_m_freemode_01` then
            if DoesShopPedApparelHaveRestrictionTag(topHash, `TUX_JACKET`, rageE.ShopPedApparel.COMPONENT) then
                return 12, 0
            end
        end

        for i = 0, (GetShopPedApparelForcedComponentCount(topHash) - 1), 1 do
            local fcNameHash, fcEnumValue, fcType = GetForcedComponent(topHash, i)

            if fcType == rageE.PedComponent.Torso then
                if fcNameHash == 0 or fcNameHash == `0` then
                    local hashName = GAME.GetFakeHashNameForComponentEnumValue(ped, fcType, fcEnumValue)
                    if hashName ~= 0 then
                        local gtaFakeShopComponent = GAME.GetFakeShopPedComponent(hashName)
                        return gtaFakeShopComponent.drawable, gtaFakeShopComponent.texture
                    else
                        return fcEnumValue, 0
                    end
                else
                    local gtaShopComponent = GAME.GetShopPedComponent(fcNameHash)
                    return gtaShopComponent.drawable, gtaShopComponent.texture
                end
            end
        end

        return -1, -1
    end

    function GAME.GetComponentVariationName(model, componentId, drawableId)
        if model == `mp_m_freemode_01` then
            if componentId == rageE.PedComponent.Hair then
                if drawableId <= 22 then
                    return GetLabelText(('CC_M_HS_%u'):format(drawableId))
                elseif drawableId == 23 then
                    return 'NULL'
                elseif drawableId <= 27 then
                    return GetLabelText(('CLO_S1M_H_%u_0'):format(drawableId - 24))
                elseif drawableId <= 30 then
                    return GetLabelText(('CLO_S2M_H_%u_0'):format(drawableId - 28))
                elseif drawableId <= 36 then
                    return GetLabelText(('CLO_BIM_H_%u_0'):format(drawableId - 31))
                elseif drawableId <= 58 then
                    return GAME.GetComponentVariationName(model, componentId, drawableId - (58 - 22))
                elseif drawableId <= 71 then
                    return GAME.GetComponentVariationName(model, componentId, drawableId - (71 - 36))
                elseif drawableId <= 73 then
                    return GetLabelText(('CLO_GRM_H_%u_0'):format(drawableId - 72))
                elseif drawableId == 74 then
                    return GetLabelText(('CLO_VWM_H_%u_0'):format(drawableId - 74))
                end
            end
        elseif model == `mp_f_freemode_01` then
        end

        return 'NULL'
    end
end

if IS_RDR3 then
    function GAME.ApplyShopItem(ped, shopItem, skipUpdate)
        -- We need to wait for the ped to be ready before applying a shop item to avoid weird glitches
        while not toboolean(IsPedReadyToRender(ped)) do
            Wait(0)
        end

        ApplyShopItemToPed(ped, shopItem, false, true, false)

        if not skipUpdate then
            N_0xaab86462966168ce(ped, 1) -- Used in R* scripts
            UpdatePedVariation(ped, false, true, true, true, false)
        end
    end

    function GAME.ApplyPlayerShopItem(shopItem, skipUpdate)
        GAME.ApplyShopItem(PlayerPedId(), shopItem, skipUpdate)
    end

    function GAME.RemovePlayerShopItemByCategory(category, skipUpdate)
        local ped = PlayerPedId()

        RemoveShopItemFromPedByCategory(ped, category, 0, false)

        if not skipUpdate then
            UpdatePedVariation(ped, false, true, true, true, false)
        end
    end
end

function GAME.GetEntityProperties(entity)
    local entityType = GetEntityType(entity)

    if entityType == rageE.EntityType['Ped'] then
    elseif entityType == rageE.EntityType['Vehicle'] then
        local extras = {}

        for id = (IS_GTA5 and 0 or 1), (IS_GTA5 and 12 or 16) do
            if DoesExtraExist(entity, id) then
                extras[tostring(id)] = IsVehicleExtraTurnedOn(entity, id)
            end
        end

        if IS_GTA5 then
            local primaryColor, secondaryColor = GetVehicleColours(entity)
            local pearlescentColor, wheelColor = GetVehicleExtraColours(entity)
            local vehiclesColoursNum = GAME.GetVehiclesColoursNum()
            local mods = {}

            for modType = 0, rageE.ModTypeNUM - 1 do
                if GAME.IsVehicleModAToggle(modType) then
                    mods[modType] = IsToggleModOn(entity, modType)
                else
                    mods[modType] = GetVehicleMod(entity, modType)
                end
            end

            return {
                model = GetEntityModel(entity),

                plate = Utils.String.Trim(GetVehicleNumberPlateText(entity)),
                plateIndex = GetVehicleNumberPlateTextIndex(entity),

                bodyHealth = Utils.Math.Round(GetVehicleBodyHealth(entity), 1),
                engineHealth = Utils.Math.Round(GetVehicleEngineHealth(entity), 1),

                fuelLevel = Utils.Math.Round(GetVehicleFuelLevel(entity), 1),
                dirtLevel = Utils.Math.Round(GetVehicleDirtLevel(entity), 1),

                color1 = primaryColor > vehiclesColoursNum and ((primaryColor - vehiclesColoursNum) + 1000) or primaryColor,
                color2 = secondaryColor > vehiclesColoursNum and ((secondaryColor - vehiclesColoursNum) + 1000) or secondaryColor,

                customColor1 = { GetVehicleCustomPrimaryColour(entity) },
                customColor2 = { GetVehicleCustomSecondaryColour(entity) },

                pearlescentColor = pearlescentColor,
                wheelColor = wheelColor,

                dashboardColor = GetVehicleDashboardColor(entity),
                interiorColor = GetVehicleInteriorColor(entity),

                wheels = GetVehicleWheelType(entity),
                windowTint = GetVehicleWindowTint(entity),
                xenonColor = GetVehicleXenonLightsColor(entity),

                neonEnabled = {
                    ['0'] = IsVehicleNeonLightEnabled(entity, 0),
                    ['1'] = IsVehicleNeonLightEnabled(entity, 1),
                    ['2'] = IsVehicleNeonLightEnabled(entity, 2),
                    ['3'] = IsVehicleNeonLightEnabled(entity, 3)
                },

                neonColor = { GetVehicleNeonLightsColour(entity) },
                extras = extras,
                tyreSmokeColor = { GetVehicleTyreSmokeColor(entity) },

                mods = mods,
                modLivery = GetVehicleLivery(entity),

                windowsIntact = {
                    ['0'] = IsVehicleWindowIntact(entity, 0),
                    ['1'] = IsVehicleWindowIntact(entity, 1),
                    ['2'] = IsVehicleWindowIntact(entity, 2),
                    ['3'] = IsVehicleWindowIntact(entity, 3),
                    ['4'] = IsVehicleWindowIntact(entity, 4),
                    ['5'] = IsVehicleWindowIntact(entity, 5),
                    ['6'] = IsVehicleWindowIntact(entity, 6),
                    ['7'] = IsVehicleWindowIntact(entity, 7)
                },

                tyresBurst = {
                    ['0'] = IsVehicleTyreBurst(entity, 0, false),
                    ['1'] = IsVehicleTyreBurst(entity, 1, false),
                    ['2'] = IsVehicleTyreBurst(entity, 2, false),
                    ['3'] = IsVehicleTyreBurst(entity, 3, false),
                    ['4'] = IsVehicleTyreBurst(entity, 4, false),
                    ['5'] = IsVehicleTyreBurst(entity, 5, false)
                }
            }
        else
            return {
                model = GetEntityModel(entity),

                bodyHealth = Utils.Math.Round(GetVehicleBodyHealth(entity), 1),
                engineHealth = Utils.Math.Round(GetVehicleEngineHealth(entity), 1),

                extras = extras,

                modLivery = GetVehicleLivery(entity)
            }
        end
    elseif entityType == rageE.EntityType['Object'] then
    end

    return nil
end

local debugEntity = nil

do
    local entitiesDebugs <const> = {}
    local ENTITY_DEBUGS_TTL <const> = 90 * 1000

    debugEntity = function(_type, netId, ...)
        local entityDebugs = entitiesDebugs[netId]
        local timeNow = GetGameTimer()
        local entityDebug = { type = _type, time = timeNow, args = { ... } }
        if not entityDebugs then
            entityDebugs = { list = { entityDebug }, lastUpdate = timeNow }
            entitiesDebugs[netId] = entityDebugs
        else
            entityDebugs.list[#entityDebugs.list + 1] = entityDebug
            entityDebugs.lastUpdate = timeNow
        end

        if GetConvarInt('debug_entity', 0) == 1 then
            local debugMsg = ('%s: %s'):format(_type, table.concat({ ... }, ', '))
            print('debug_entity:', netId, debugMsg)
        end
    end

    CreateThread(function()
        while true do
            local timeNow = GetGameTimer()

            for netId, entityDebugs in pairs(entitiesDebugs) do
                if entityDebugs.lastUpdate and (timeNow - entityDebugs.lastUpdate) > ENTITY_DEBUGS_TTL then
                    table.wipe(entityDebugs.list)
                    entitiesDebugs[netId] = nil
                end
            end

            Wait(1000)
        end
    end)

    IMPOSTEUR.OnNet('getEntityDebugs', function(netId)
        local entityDebugs = entitiesDebugs[netId]

        if entityDebugs then
            IMPOSTEUR.EmitServer('getEntityDebugs:cb', entityDebugs.list)
        end
    end)
end

do
    local vehicleModTypesToggle = {
        [rageE.ModType.TOGGLE_NITROUS] = true,
        [rageE.ModType.TOGGLE_TURBO] = true,
        [rageE.ModType.TOGGLE_SUBWOOFER] = true,
        [rageE.ModType.TOGGLE_TYRE_SMOKE] = true,
        [rageE.ModType.TOGGLE_HYDRAULICS] = true,
        [rageE.ModType.TOGGLE_XENON_LIGHTS] = true
    }

    function GAME.IsVehicleModAToggle(modType)
        return vehicleModTypesToggle[modType] ~= nil
    end
end

local function setEntityProperties(entity, props)
    local entityType = GetEntityType(entity)
    local metaProps = props.meta

    if entityType == rageE.EntityType['Ped'] then
        if IS_RDR3 then
            if metaProps then
                if metaProps.randomOutfitVariation then
                    SetRandomOutfitVariation(entity, true)
                end
            end

            if props.faceFeatures then
                for index, scale in pairs(props.faceFeatures) do
                    SetPedFaceFeature(entity, index, type(scale) == 'float' and scale or (scale + .0))
                end
            end

            if props.shopItemsToRemoveByCategories then
                for i = 1, #props.shopItemsToRemoveByCategories do
                    RemoveShopItemFromPedByCategory(entity, props.shopItemsToRemoveByCategories[i], 0, false)
                end
            end

            if props.shopItems then
                for i = 1, #props.shopItems do
                    GAME.ApplyShopItem(entity, props.shopItems[i])
                end
            end

            UpdatePedVariation(entity, false, true, true, true, false)
        elseif IS_GTA5 then
            if metaProps then
                if metaProps.taskFollowToOffsetOfEntity then
                    local args = metaProps.taskFollowToOffsetOfEntity

                    local entity2 = args[1]
                    local offsetX, offsetY, offsetZ = args[2], nil, nil
                    local moveBlendRatioOffset = 3

                    if type(offsetX) == 'vector3' then
                        offsetX, offsetY, offsetZ = offsetX.x, offsetX.y, offsetX.z
                    else
                        offsetY, offsetZ = args[3], args[4]
                        moveBlendRatioOffset = moveBlendRatioOffset + 2
                    end

                    TaskFollowToOffsetOfEntity(
                        entity,
                        entity2,
                        offsetX, offsetY, offsetZ,
                        args[moveBlendRatioOffset] + 0.0,
                        args[moveBlendRatioOffset + 1],
                        args[moveBlendRatioOffset + 2] + 0.0,
                        args[moveBlendRatioOffset + 3]
                    )
                end

                if metaProps.defaultComponentVariation then
                    SetPedDefaultComponentVariation(entity)
                end

                if metaProps.taskEnterVehicle then
                    -- Fix float for speed value
                    local speedOffset = 4
                    metaProps.taskEnterVehicle[speedOffset] = metaProps.taskEnterVehicle[speedOffset] + .0

                    TaskEnterVehicle(entity, table.unpack(metaProps.taskEnterVehicle))
                end
            end
        end

        if metaProps then
            if metaProps.relationshipGroupHash then
                SetPedRelationshipGroupHash(entity, metaProps.relationshipGroupHash)
            end

            if metaProps.setBlockingOfNonTemporaryEvents ~= nil then
                SetBlockingOfNonTemporaryEvents(entity, metaProps.setBlockingOfNonTemporaryEvents)
            end

            if metaProps.canBeDraggedOut ~= nil then
                SetPedCanBeDraggedOut(entity, metaProps.canBeDraggedOut)
            end

            if metaProps.canBeKnockedOffVehicle ~= nil then
                SetPedCanBeKnockedOffVehicle(entity, metaProps.canBeKnockedOffVehicle)
            end

            if metaProps.configFlags then
                for flagId, value in pairs(metaProps.configFlags) do
                    SetPedConfigFlag(entity, flagId, value)
                end
            end
        end
    elseif entityType == rageE.EntityType['Vehicle'] then
        if IS_GTA5 then
            local primaryColor, secondaryColor = (props.color1 or props.color2) and GetVehicleColours(entity)
            local pearlescentColor, wheelColor = (props.pearlescentColor or props.wheelColor) and GetVehicleExtraColours(entity)

            if GetVehicleModKit(entity) ~= 0 then
                SetVehicleModKit(entity, 0)
            end

            if props.removeAllMods then
                for i = 0, 49 do
                    RemoveVehicleMod(entity, i)
                end
            end

            if props.plate then
                SetVehicleNumberPlateText(entity, props.plate)
            end
            if props.plateIndex then
                SetVehicleNumberPlateTextIndex(entity, props.plateIndex)
            end
            if props.fuelLevel then
                SetVehicleFuelLevel(entity, props.fuelLevel + 0.0)
                IMPOSTEUR.Emit('game:props:setFuelLevel', entity, props.fuelLevel + 0.0)
            end

            if props.clearCustomColor1 then
                ClearVehicleCustomPrimaryColour(entity)
            end

            if props.clearCustomColor2 then
                ClearVehicleCustomSecondaryColour(entity)
            end

            if props.color1 or props.color2 then
                local vehiclesColoursNum = GAME.GetVehiclesColoursNum()
                local color1 = props.color1 and (props.color1 > 1000 and ((props.color1 - 1000) + vehiclesColoursNum) or props.color1) or primaryColor
                local color2 = props.color2 and (props.color2 > 1000 and ((props.color2 - 1000) + vehiclesColoursNum) or props.color2) or secondaryColor
                SetVehicleColours(entity, color1, color2)
            end

            if props.customColor1 then
                SetVehicleCustomPrimaryColour(entity, props.customColor1[1], props.customColor1[2], props.customColor1[3])
            end

            if props.customColor2 then
                SetVehicleCustomSecondaryColour(entity, props.customColor2[1], props.customColor2[2], props.customColor2[3])
            end

            if props.pearlescentColor or props.wheelColor then
                SetVehicleExtraColours(entity, props.pearlescentColor or pearlescentColor, props.wheelColor or wheelColor)
            end

            if props.dashboardColor then
                SetVehicleDashboardColor(entity, props.dashboardColor)
            end

            if props.interiorColor then
                SetVehicleInteriorColor(entity, props.interiorColor)
            end

            if props.wheels then
                SetVehicleWheelType(entity, props.wheels)
            end
            if props.windowTint then
                SetVehicleWindowTint(entity, props.windowTint)
            end
            if props.xenonColor then
                SetVehicleXenonLightsColor(entity, props.xenonColor)
            end

            if props.neonEnabled then
                SetVehicleNeonLightEnabled(entity, 0, props.neonEnabled['0'])
                SetVehicleNeonLightEnabled(entity, 1, props.neonEnabled['1'])
                SetVehicleNeonLightEnabled(entity, 2, props.neonEnabled['2'])
                SetVehicleNeonLightEnabled(entity, 3, props.neonEnabled['3'])
            end

            if props.neonColor then
                SetVehicleNeonLightsColour(entity, props.neonColor[1], props.neonColor[2], props.neonColor[3])
            end

            if props.tyreSmokeColor then
                SetVehicleTyreSmokeColor(entity, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
            end

            if props.mods then
                -- First toggle needed vehicle mods
                for modType = 0, rageE.ModTypeNUM - 1 do
                    local mod = props.mods[tostring(modType)]

                    if mod ~= nil then
                        if GAME.IsVehicleModAToggle(modType) then
                            if type(mod) == 'boolean' then
                                ToggleVehicleMod(entity, modType, mod)
                            else
                                IO.Debug('Invalid toggle mod value:', modType, mod, type(mod))
                                ToggleVehicleMod(entity, modType, mod == 1)
                            end
                        end
                    end
                end

                -- Apply them
                for modType = 0, rageE.ModTypeNUM - 1 do
                    local mod = props.mods[tostring(modType)]

                    if mod ~= nil then
                        if not GAME.IsVehicleModAToggle(modType) then
                            SetVehicleMod(entity, modType, mod, false)
                        end
                    end
                end
            end
        end

        if props.bodyHealth then
            SetVehicleBodyHealth(entity, props.bodyHealth + 0.0)
        end
        if props.engineHealth then
            SetVehicleEngineHealth(entity, props.engineHealth + 0.0)
        end
        if props.dirtLevel then
            SetVehicleDirtLevel(entity, props.dirtLevel + 0.0)
        end

        if props.windowsIntact then
            for windowIndex, isIntact in pairs(props.windowsIntact) do
                if not isIntact then
                    SmashVehicleWindow(entity, tonumber(windowIndex))
                end
            end
        end

        if props.tyresBurst then
            for tyreIndex, isBurst in pairs(props.tyresBurst) do
                if isBurst then
                    SetVehicleTyreBurst(entity, tonumber(tyreIndex), true, 1000)
                end
            end
        end

        if props.deformation then
            GAME.SetVehicleDeformation(entity, props.deformation)
        end

        local EXTRA_ID_START, MAX_EXTRA_ID = IS_GTA5 and 0 or 1, IS_GTA5 and 12 or 16

        if props.allExtras then
            for id = EXTRA_ID_START, MAX_EXTRA_ID do
                SetVehicleExtra(entity, id, false)
            end
        elseif props.extras then
            local missingExtras = {}

            for id = EXTRA_ID_START, MAX_EXTRA_ID do
                if DoesExtraExist(entity, id) then
                    local enabled = props.extras[tostring(id)]

                    if type(enabled) == 'boolean' then
                        SetVehicleExtra(entity, id, not enabled)
                    else
                        missingExtras[id] = true
                    end
                end
            end

            if props.defaultExtras then
                -- Disable all extras by default (except for helicopters because it would disable propellers too)
                if not IsThisModelAHeli(GetEntityModel(entity)) then
                    for id = EXTRA_ID_START, MAX_EXTRA_ID do
                        if missingExtras[id] then
                            SetVehicleExtra(entity, id, true)
                        end
                    end
                end
            end
        else
            if props.defaultExtras then
                -- Disable all extras by default (except for helicopters because it would disable propellers too)
                if not IsThisModelAHeli(GetEntityModel(entity)) then
                    for id = EXTRA_ID_START, MAX_EXTRA_ID do
                        if DoesExtraExist(entity, id) then
                            SetVehicleExtra(entity, id, true)
                        end
                    end
                end
            end
        end

        if IS_RDR3 then
            if props.tintIndex then
                SetVehicleTint(entity, props.tintIndex)
            end
        end

        -- Livery needs to be applied AFTER tint in RDR3
        if props.modLivery then
            SetVehicleLivery(entity, props.modLivery)
        end

        if metaProps then
            if metaProps.setOnGroundProperly then
                SetVehicleOnGroundProperly(entity)
            end

            if IS_GTA5 then
                if metaProps.radioStation then
                    SetVehRadioStation(entity, metaProps.radioStation)
                end
            end

            if metaProps.doorsLocked then
                SetVehicleDoorsLocked(entity, metaProps.doorsLocked)
            end
            if type(metaProps.doorsLockedForAllPlayers) == 'boolean' then
                SetVehicleDoorsLockedForAllPlayers(entity, metaProps.doorsLockedForAllPlayers)
            end

            if metaProps.doorsOpen then
                for i = 1, #metaProps.doorsOpen do
                    local doorData = metaProps.doorsOpen[i]

                    SetVehicleDoorOpen(entity, doorData[1], doorData[2], doorData[3])
                end
            end

            if metaProps.doorsShut then
                for i = 1, #metaProps.doorsShut do
                    local doorData = metaProps.doorsShut[i]

                    SetVehicleDoorShut(entity, doorData[1], doorData[2])
                end
            end

            if metaProps.setDeformationFixed then
                SetVehicleDeformationFixed(entity)
            end

            if metaProps.removeDecalsFromVehicle then
                RemoveDecalsFromVehicle(entity)
            end

            if metaProps.setFixed then
                SetVehicleFixed(entity)
            elseif metaProps.setFixedOnlyDecoratives then
                local vehicleEngineHealth = GetVehicleEngineHealth(entity)
                local tyresBurst = {}

                for tyreIndex = 0, 8 - 1 do
                    if IsVehicleTyreBurst(entity, tyreIndex, false) then
                        tyresBurst[tyreIndex] = true
                    end
                end

                SetVehicleFixed(entity)

                SetVehicleEngineHealth(entity, vehicleEngineHealth)

                for tyreIndex = 0, 8 - 1 do
                    if tyresBurst[tyreIndex] then
                        SetVehicleTyreBurst(entity, tyreIndex, true, 1000.0)
                    end
                end
            end

            if metaProps.fixWindow then
                for i = 1, #metaProps.fixWindow do
                    local windowIndex = metaProps.fixWindow[i]
                    FixVehicleWindow(entity, windowIndex)
                end
            end

            if metaProps.setTyreFixed then
                for i = 1, #metaProps.setTyreFixed do
                    local tyreIndex = metaProps.setTyreFixed[i]
                    SetVehicleTyreFixed(entity, tyreIndex)
                end
            end
        end
    elseif entityType == rageE.EntityType['Object'] then
        if metaProps then
            if metaProps.placeOnGroundProperly then
                PlaceObjectOnGroundProperly(entity)
            end
        end
    end

    if metaProps then
        if metaProps.coords then
            SetEntityCoordsNoOffset(entity, metaProps.coords.x, metaProps.coords.y, metaProps.coords.z, true --[[KeepTasks]], true --[[KeepIK]], true --[[DoWarp]])
        elseif metaProps.coordsNoOffset then
            SetEntityCoords(entity, metaProps.coordsNoOffset.x, metaProps.coordsNoOffset.y, metaProps.coordsNoOffset.z, false --[[DoDeadCheck]], true --[[KeepTasks]], true --[[KeepIK]], true --[[DoWarp]])
        end

        if metaProps.heading then
            SetEntityHeading(entity, metaProps.heading + 0.0)
        end

        if metaProps.collision then
            SetEntityCollision(entity, table.unpack(metaProps.collision))
        end

        if metaProps.netIdCanMigrate ~= nil then
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), metaProps.netIdCanMigrate)
        end

        if metaProps.attachToEntity then
            local entity2 = metaProps.attachToEntity[1]
            local boneIdx = metaProps.attachToEntity[2]

            if type(boneIdx) == 'number' then
                boneIdx = boneIdx <= 0 and boneIdx or
                    (GetEntityType(entity2) == rageE.EntityType['Ped'] and GetPedBoneIndex(entity2, boneIdx))
            elseif type(boneIdx) == 'string' then
                boneIdx = GetEntityBoneIndexByName(entity2, boneIdx)
            end

            local offset = metaProps.attachToEntity[3]
            local rotation = metaProps.attachToEntity[4]

            AttachEntityToEntity(
                entity,
                entity2,
                boneIdx,
                offset.x, offset.y, offset.z,
                rotation.x, rotation.y, rotation.z,
                metaProps.attachToEntity[5],
                metaProps.attachToEntity[6],
                metaProps.attachToEntity[7],
                metaProps.attachToEntity[8],
                metaProps.attachToEntity[9],
                metaProps.attachToEntity[10]
            )
        end

        if metaProps.detachEntity then
            DetachEntity(entity, table.unpack(metaProps.detachEntity))
        end

        if metaProps.freezeEntityPosition ~= nil then
            FreezeEntityPosition(entity, metaProps.freezeEntityPosition)
        end

        if metaProps.placeOnGroundProperly then
            if IS_GTA5 then
                if entityType == rageE.EntityType['Object'] then
                    PlaceObjectOnGroundProperly(entity)
                end
            elseif IS_RDR3 then
                if entityType ~= rageE.EntityType['Object'] then
                    PlaceEntityOnGroundProperly(entity, false)
                else
                    PlaceObjectOnGroundProperly(entity, false)
                end
            end
        end

        if metaProps.proofs then
            SetEntityProofs(entity, table.unpack(metaProps.proofs))
        end

        if metaProps.invincible ~= nil then
            SetEntityInvincible(entity, metaProps.invincible)
        end
    end
end

local function prepareNetEntityProperties(entity, props, toNet)
    local idConverter = toNet and NetworkGetNetworkIdFromEntity or NetworkGetEntityFromNetworkId
    local entityType = GetEntityType(entity)

    if props.meta then
        local metaProps = props.meta

        if entityType == rageE.EntityType['Ped'] then
            if IS_GTA5 then
                if metaProps.taskFollowToOffsetOfEntity then
                    local entity2 = idConverter(metaProps.taskFollowToOffsetOfEntity[1])
                    if entity == entity2 then
                        table.wipe(metaProps.taskFollowToOffsetOfEntity)
                        metaProps.taskFollowToOffsetOfEntity = nil
                        goto continue
                    end

                    metaProps.taskFollowToOffsetOfEntity[1] = entity2
                    :: continue ::
                end

                if metaProps.taskEnterVehicle then
                    local entity2 = idConverter(metaProps.taskEnterVehicle[1])
                    if entity == entity2 then
                        table.wipe(metaProps.taskEnterVehicle)
                        metaProps.taskEnterVehicle = nil
                        goto continue
                    end

                    metaProps.taskEnterVehicle[1] = entity2
                    :: continue ::
                end
            end
        end

        if metaProps.attachToEntity then
            local entity2 = idConverter(metaProps.attachToEntity[1])
            if entity == entity2 then
                table.wipe(metaProps.attachToEntity)
                metaProps.attachToEntity = nil
                goto continue
            end

            metaProps.attachToEntity[1] = entity2
            :: continue ::
        end
    end
end

---@param ped number @A ped entity id
---@return boolean
function GAME.IsPedAttachedToAnyPlayerPed(ped)
    local attachedEntity = GetEntityAttachedTo(ped)
    if attachedEntity == 0 then
        return false
    end

    if GetEntityType(attachedEntity) ~= rageE.EntityType.Ped then
        return false
    end

    if not IsPedAPlayer(attachedEntity) then
        return false
    end

    return true
end

--[[Purpose: Check if the closest player ped is attached to the ped in param --]]
---@param ped number @A ped entity id
---@return boolean
function GAME.IsClosestPlayerPedAttachedToPed(ped)
    local pedCoords = GetEntityCoords(ped)
    local closestPlayer, closestDistance = GAME.GetClosestPlayer(pedCoords)

    if closestDistance == -1 or closestDistance > 1 then
        return false
    end

    local closestPed = GetPlayerPed(closestPlayer)

    local attachedEntity = GetEntityAttachedTo(closestPed)
    if attachedEntity ~= ped then
        return false
    end

    return true
end

do
    local trackedEntities = {}

    function GAME.TrackEntityDeletion(entity, onDeletion)
        trackedEntities[#trackedEntities + 1] = { entity, onDeletion }
    end

    CreateThread(function()
        while true do
            Wait(0)

            for i = #trackedEntities, 1, -1 do
                if not DoesEntityExist(trackedEntities[i][1]) then
                    trackedEntities[i][2]()
                    table.remove(trackedEntities, i)
                end
            end
        end
    end)
end

do
    local scaledEntities = Collection.New()

    -- WIP but usable, has somme issues with collisions, movement speed and camera placement on player ped
    function GAME.SetEntityScale(entity, scale)
        if scale == 1.0 then
            scale = nil
        end

        if not scale then
            scaledEntities:delete(entity)
            return
        end

        if not DoesEntityExist(entity) then
            return
        end

        local scaledEntity = scaledEntities:get(entity)
        if scaledEntity then
            scaledEntity.scale = scale
        else
            scaledEntities:set(entity, {
                handle = entity,
                scale = scale,
                lastFrameMatrix = {}
            })
        end
    end

    CreateThread(function()
        while true do
            Wait(0)

            for i = scaledEntities.size, 1, -1 do
                local scaledEntity = scaledEntities:at(i)
                local entity = scaledEntity.handle

                if not DoesEntityExist(entity) then
                    scaledEntities:delete(entity)
                    goto continue
                end

                local forward, right, up, at = GetEntityMatrix(entity)
                local lastFrameMatrix = scaledEntity.lastFrameMatrix
                -- TODO: Fix this condition causing ped to grow in size infinitely, entity matrix from some peds is not ticked by the game, which means scaled matrix moves but is not rescaled as it should
                if lastFrameMatrix[1] == forward and lastFrameMatrix[2] == right and lastFrameMatrix[3] == up and lastFrameMatrix[4] == at then
                    goto continue
                end

                local scale = scaledEntity.scale
                forward, right, up = forward * scale, right * scale, up * scale
                local minDims, maxDims = GetModelDimensions(GetEntityModel(entity))
                local dim = maxDims - minDims
                local defaultHeightAbove = dim.z / 2
                at = at + vec3(0.0, 0.0, defaultHeightAbove * (scale - 1.0))

                SetEntityMatrix(entity, forward, right, up, at)

                lastFrameMatrix[1] = forward
                lastFrameMatrix[2] = right
                lastFrameMatrix[3] = up
                lastFrameMatrix[4] = at

                ::continue::
            end
        end
    end)
end

function GAME.SetEntityProperties(entity, props)
    if NetworkGetEntityIsNetworked(entity) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        prepareNetEntityProperties(entity, props, true)
        IMPOSTEUR.EmitServer('setEntityProperties', netId, props)
    else
        setEntityProperties(entity, props)
    end
end

do
    local function isOwnerOfEntity(entity)
        return NetworkHasControlOfEntity(entity) and NetworkGetEntityOwner(entity) == PlayerId()
    end

    local function getEntityFromNetworkId(netId)
        return toboolean(NetworkDoesNetworkIdExist(netId)) and NetworkGetEntityFromNetworkId(netId) or 0
    end

    local entityPropsApplying <const> = {}

    local function hasEntityPropsApplyingExpired(netId, entity, extraLog)
        if not entityPropsApplying[entity] then
            debugEntity('props_returned', netId, ('entity %d applying has been cancelled - <%s>'):format(entity, extraLog))
            return true
        end

        return false
    end

    local function hasEntityApplyingExpired(netId, entity, extraLog)
        if not DoesEntityExist(entity) then
            entityPropsApplying[entity] = nil
            debugEntity('props_returned', netId, ('entity %d does not exist - <%s>'):format(entity, extraLog))
            return true
        end

        return hasEntityPropsApplyingExpired(netId, entity, extraLog)
    end

    local function handleNetEntityProps(netId, entity, props)
        while not isOwnerOfEntity(entity) do
            Wait(0)
            if hasEntityApplyingExpired(netId, entity, 'owner check') then return end
        end

        entityPropsApplying[entity] = nil

        prepareNetEntityProperties(entity, props, false)

        local entityState = Entity(entity).state

        setEntityProperties(entity, props)
        entityState:set('props', nil, true)
        debugEntity('props_success', netId, ('entity %d'):format(entity))
    end

    do
        -- Handle properties set before client spawn
        local function testEntityForProps(entity)
            if not NetworkGetEntityIsNetworked(entity) then return end
            local netId = NetworkGetNetworkIdFromEntity(entity)

            local props = Entity(entity).state.props
            if not props then return end

            Citizen.CreateThreadNow(function()
                entityPropsApplying[entity] = true
                handleNetEntityProps(netId, entity, props)
            end)
        end

        local objects = GAME.GetObjects()
        for i = 1, #objects do testEntityForProps(objects[i]) end

        local peds = GAME.GetPeds()
        for i = 1, #peds do testEntityForProps(peds[i]) end

        local vehicles = GAME.GetVehicles()
        for i = 1, #vehicles do testEntityForProps(vehicles[i]) end
    end

    -- Handle future properties
    AddStateBagChangeHandler('props', '', function(bagName, key, value, reserved, replicated)
        if replicated then return end

        local netId = GAME.GetEntityNetIdFromStateBagName(bagName)
        if netId == 0 then return end
        debugEntity('props', netId, bagName, ('data: %s'):format(json.encode(value)))

        local entity = getEntityFromNetworkId(netId)
        local hasWaitedOneTick = false

        if entity == 0 then
            local failTimer = GetGameTimer() + 5000

            while true do
                Wait(0)
                entity = getEntityFromNetworkId(entity)
                if entity ~= 0 then break end

                if failTimer < GetGameTimer() then
                    debugEntity('props_returned', netId, ('entity %d not found after waiting until fail timer'):format(entity))
                    return
                end

                if hasEntityPropsApplyingExpired(netId, entity, 'retry get entity from net id') then return end
            end

            hasWaitedOneTick = true
        end

        debugEntity('props_info', netId, ('entity %d'):format(entity))

        if not value then
            if entityPropsApplying[entity] then
                entityPropsApplying[entity] = nil
            end
            return
        end

        entityPropsApplying[entity] = true

        if not hasWaitedOneTick then
            Wait(0)
            if hasEntityApplyingExpired(netId, entity, 'wait one tick') then return end
        end

        handleNetEntityProps(netId, entity, value)
    end)
end

function GAME.RevivePlayer(coords, heading)
    local playerPed = PlayerPedId()
    IMPOSTEUR.EmitSync('playerReviving')
    GAME.SpawnPlayer(nil, coords or GetEntityCoords(playerPed), heading or GetEntityHeading(playerPed))
    IMPOSTEUR.Emit('playerRevived')
end

--- @param ped number
--- @param addTasks function
--- @param neededProgressToContinue number
--- Starts a sequence task (multiple anims will smoothly follow each other once the previous one is done) on a ped
function GAME.StartPedSequenceTask(ped, addTasks, neededProgressToContinue)
    local sequence = OpenSequenceTask(0)
    addTasks(0)
    CloseSequenceTask(sequence)
    TaskPerformSequence(ped, sequence)
    ClearSequenceTask(sequence)

    -- Waits for neededProgressToContinue if specified
    if neededProgressToContinue ~= nil then
        -- Apparently player could somehow be stuck in this loop so we use a timeout just in case
        local DEFAULT_TIMEOUT <const> = 15000
        local timeoutTimer = GetGameTimer() + DEFAULT_TIMEOUT
        while GetSequenceProgress(ped) ~= neededProgressToContinue do
            if GetGameTimer() > timeoutTimer then
                IO.Debug('Sequence task timed out')
                return
            end

            Wait(100)
        end
    end
end

if IS_GTA5 then
    local function isCharacterSelectorActive()
        local characters = Modules.Get('characters')
        return characters and characters.characterSelectorActive
    end

    local function checkControlFlags(flags)
        -- Disable control if the player is dead and ALLOW_DEATH flag is not used
        if ((flags & E.ControlFlags.ALLOW_DEATH) == 0) then
            if CPlayer().Dead then
                return false
            end
        end

        return true
    end

    function GAME.RegisterControl(id, name, input, secondaryInput, keyDown, keyUp, flags)
        flags = flags or E.ControlFlags.DEFAULT

        -- Register keyDown even if there is none otherwise keyUp will not be triggered
        do
            local commandStr = ('+seed_%s'):format(id)
            RegisterCommand(commandStr, function()
                if not keyDown or isCharacterSelectorActive() or not checkControlFlags(flags) then
                    return
                end

                keyDown()
            end, false)
            TriggerEvent('chat:removeSuggestion', ('/%s'):format(commandStr))
        end

        if keyUp then
            local commandStr = ('-seed_%s'):format(id)
            RegisterCommand(commandStr, function()
                if isCharacterSelectorActive() or not checkControlFlags(flags) then
                    return
                end

                keyUp()
            end, false)
            TriggerEvent('chat:removeSuggestion', ('/%s'):format(commandStr))
        end

        RegisterKeyMapping(('+seed_%s'):format(id), name, input[1], input[2])

        if secondaryInput then
            RegisterKeyMapping(('~!+seed_%s'):format(id), name, secondaryInput[1], secondaryInput[2])
        end
    end

    function GAME.GetControlHashCode(id)
        local hash = ujoaat(GetHashKey(('+seed_%s'):format(id)))
        return string.format('%08X', hash)
    end

    function GAME.GetControlHashBinding(id)
        local hash = ujoaat(GetHashKey(('+seed_%s'):format(id)))
        return hash | 0x80000000
    end

    local specialkeyCodes = {
        ['b_116'] = 'WheelMouseMove.Up',
        ['b_115'] = 'WheelMouseMove.Up',
        ['b_100'] = 'MouseClick.LeftClick',
        ['b_101'] = 'MouseClick.RightClick',
        ['b_102'] = 'MouseClick.MiddleClick',
        ['b_103'] = 'MouseClick.ExtraBtn1',
        ['b_104'] = 'MouseClick.ExtraBtn2',
        ['b_105'] = 'MouseClick.ExtraBtn3',
        ['b_106'] = 'MouseClick.ExtraBtn4',
        ['b_107'] = 'MouseClick.ExtraBtn5',
        ['b_108'] = 'MouseClick.ExtraBtn6',
        ['b_109'] = 'MouseClick.ExtraBtn7',
        ['b_110'] = 'MouseClick.ExtraBtn8',
        ['b_1015'] = 'AltLeft',
        ['b_1000'] = 'ShiftLeft',
        ['b_2000'] = 'Space',
        ['b_1013'] = 'ControlLeft',
        ['b_1002'] = 'Tab',
        ['b_1014'] = 'ControlRight',
        ['b_137'] = 'Numpad1',
        ['b_138'] = 'Numpad2',
        ['b_139'] = 'Numpad3',
        ['b_140'] = 'Numpad4',
        ['b_142'] = 'Numpad6',
        ['b_144'] = 'Numpad8',
        ['b_141'] = 'Numpad5',
        ['b_143'] = 'Numpad7',
        ['b_145'] = 'Numpad9',
        ['b_200'] = 'Insert',
        ['b_1012'] = 'CapsLock',
        ['b_170'] = 'F1',
        ['b_171'] = 'F2',
        ['b_172'] = 'F3',
        ['b_173'] = 'F4',
        ['b_174'] = 'F5',
        ['b_175'] = 'F6',
        ['b_176'] = 'F7',
        ['b_177'] = 'F8',
        ['b_178'] = 'F9',
        ['b_179'] = 'F10',
        ['b_180'] = 'F11',
        ['b_181'] = 'F12',
        ['b_194'] = 'ArrowUp',
        ['b_195'] = 'ArrowDown',
        ['b_196'] = 'ArrowLeft',
        ['b_197'] = 'ArrowRight',
        ['b_1003'] = 'Enter',
        ['b_1004'] = 'Backspace',
        ['b_198'] = 'Delete',
        ['b_199'] = 'Escape',
        ['b_1009'] = 'PageUp',
        ['b_1010'] = 'PageDown',
        ['b_1008'] = 'Home',
        ['b_131'] = 'NumpadAdd',
        ['b_130'] = 'NumpadSubstract',
        ['b_1002'] = 'CapsLock',
        ['b_211'] = 'Insert',
        ['b_210'] = 'Delete',
        ['b_212'] = 'End',
        ['b_1055'] = 'Home',
        ['b_1056'] = 'PageUp',
    }

    function GAME.TranslateControlInstructionalButton(bind)
        if string.sub(bind, 1, 2) == "t_" then
            return string.sub(bind, 3)
        end
        
        return specialkeyCodes[bind]
    end

    function GAME.TriggerMusicEvent(musicEvent)
        PrepareMusicEvent(musicEvent)
        TriggerMusicEvent(musicEvent)
    end

    function GAME.FreemodeMessage(bigText, smallText, duration)
        Citizen.CreateThreadNow(function()
            local scaleformHandle = RequestScaleformMovie('mp_big_message_freemode')
            while not HasScaleformMovieLoaded(scaleformHandle) do
                Wait(0)
            end

            BeginScaleformMovieMethod(scaleformHandle, 'SHOW_SHARD_WASTED_MP_MESSAGE')
            PushScaleformMovieMethodParameterString(bigText)
            PushScaleformMovieMethodParameterString(smallText)
            PushScaleformMovieMethodParameterInt(5)
            EndScaleformMovieMethod()

            local started = GetGameTimer()

            while (GetGameTimer() - started) < duration do
                Wait(0)
                DrawScaleformMovieFullscreen(scaleformHandle, 255, 255, 255, 255)
            end

            SetScaleformMovieAsNoLongerNeeded(scaleformHandle)
        end)
    end

    do
        local INSTRUCTIONAL_BUTTON_KEY_SPACE <const> = 203
        local INSTRUCTIONAL_BUTTON_LABEL <const> = "Maintenir pour masquer"

        local function setupButtonPopupWarning()
            local instructionalButtonsMgr <const> = BiteUI.InstructionalButton.New()

            instructionalButtonsMgr:Add(INSTRUCTIONAL_BUTTON_LABEL, INSTRUCTIONAL_BUTTON_KEY_SPACE)

            instructionalButtonsMgr:Refresh()
            instructionalButtonsMgr:Visible(true)

            return instructionalButtonsMgr
        end

        local popupWarningIBMgr = nil

        ---@param message string
        ---@param reason string
        function GAME.ShowPopupWarning(message, reason)
            popupWarningIBMgr = setupButtonPopupWarning()

            ---@type Scaleform
            local scaleform = IMPOSTEUR.Classes.Scaleform("POPUP_WARNING")

            scaleform:Init()
            scaleform:Call("SHOW_POPUP_WARNING", 0, "Avertissement", message, reason, false, 0, "")

            local timeBlinkStarted = nil

            local BG_ALPHA = 190

            local BLINK_DURATION = 10000 -- 10 seconds
            local BLINKS_COUNT = 15

            local BLINK_PHASE_DURATION = BLINK_DURATION / BLINKS_COUNT

            Citizen.CreateThreadNow(function()
                while true do
                    local timeNow = GetGameTimer()

                    if IsDisabledControlPressed(0, 22) or IsControlPressed(0, 22) then
                        if timeBlinkStarted == nil then
                            timeBlinkStarted = timeNow
                        elseif timeNow - timeBlinkStarted > BLINK_DURATION then
                            break
                        end
                    else
                        timeBlinkStarted = nil
                    end

                    if timeBlinkStarted then
                        local timeLeft = timeNow - timeBlinkStarted
                        local blinkPhaseTime = timeLeft % BLINK_PHASE_DURATION

                        local blinkPhaseIdx = math.floor(timeLeft / BLINK_PHASE_DURATION)
                        local isInverted = (blinkPhaseIdx % 2) == 0

                        local blinkPhaseAlpha = math.floor((blinkPhaseTime / BLINK_PHASE_DURATION) * BG_ALPHA)

                        if isInverted then
                            blinkPhaseAlpha = BG_ALPHA - blinkPhaseAlpha
                        end

                        DrawRect(0.5, 0.5, 1.0, 1.0, 210, 30, 30, blinkPhaseAlpha)
                    else
                        DrawRect(0.5, 0.5, 1.0, 1.0, 210, 30, 30, BG_ALPHA)
                    end

                    scaleform:Draw(255, 255, 255, 255)

                    popupWarningIBMgr:Draw()

                    Wait(0)
                end

                scaleform:Destroy()

                popupWarningIBMgr:Destroy()
                popupWarningIBMgr = nil
            end)
        end
    end

    -- Credits to https://github.com/Kiminaze/VehicleDeformation
    local MAX_DEFORM_ITERATIONS <const> = 50 -- iterations for damage application
    local DEFORMATION_DAMAGE_THRESHOLD <const> = 0.05 -- the minimum damage value at a deformation point before being registered as actual damage

    local function getVehicleOffsetsForDeformation(vehicle)
        -- check vehicle size and pre-calc values for offsets
        local min, max = GetModelDimensions(GetEntityModel(vehicle))
        local X = Utils.Math.Round((max.x - min.x) * 0.5, 2)
        local Y = Utils.Math.Round((max.y - min.y) * 0.5, 2)
        local Z = Utils.Math.Round((max.z - min.z) * 0.5, 2)
        local halfY = Utils.Math.Round(Y * 0.5, 2)

        return {
            vector3(-X, Y, 0.0),
            vector3(-X, Y, Z),

            vector3(0.0, Y, 0.0),
            vector3(0.0, Y, Z),

            vector3(X, Y, 0.0),
            vector3(X, Y, Z),


            vector3(-X, halfY, 0.0),
            vector3(-X, halfY, Z),

            vector3(0.0, halfY, 0.0),
            vector3(0.0, halfY, Z),

            vector3(X, halfY, 0.0),
            vector3(X, halfY, Z),


            vector3(-X, 0.0, 0.0),
            vector3(-X, 0.0, Z),

            vector3(0.0, 0.0, 0.0),
            vector3(0.0, 0.0, Z),

            vector3(X, 0.0, 0.0),
            vector3(X, 0.0, Z),


            vector3(-X, -halfY, 0.0),
            vector3(-X, -halfY, Z),

            vector3(0.0, -halfY, 0.0),
            vector3(0.0, -halfY, Z),

            vector3(X, -halfY, 0.0),
            vector3(X, -halfY, Z),


            vector3(-X, -Y, 0.0),
            vector3(-X, -Y, Z),

            vector3(0.0, -Y, 0.0),
            vector3(0.0, -Y, Z),

            vector3(X, -Y, 0.0),
            vector3(X, -Y, Z),
        }
    end

    function GAME.GetVehicleDeformation(vehicle)
        local offsets = getVehicleOffsetsForDeformation(vehicle)
        local deformationPoints = {}

        for i = 1, #offsets do
            local offset = offsets[i]
            -- translate damage from vector3 to a float
            local dmg = math.floor(#(GetVehicleDeformationAtPos(vehicle, offset)) * 1000.0) / 1000.0
            if dmg > DEFORMATION_DAMAGE_THRESHOLD then
                deformationPoints[#deformationPoints + 1] = { offset, dmg }
            end
        end

        return deformationPoints
    end

    function GAME.SetVehicleDeformation(vehicle, deformationPoints)
        Citizen.CreateThreadNow(function()
            -- set damage multiplier from vehicle handling data
            local fDeformationDamageMult = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDeformationDamageMult')

            local damageMult = 20.0
            if fDeformationDamageMult <= 0.55 then
                damageMult = 1000.0
            elseif fDeformationDamageMult <= 0.65 then
                damageMult = 400.0
            elseif fDeformationDamageMult <= 0.75 then
                damageMult = 200.0
            end

            for i = 1, #deformationPoints do
                local def = deformationPoints[i]
                local firstDef = def[1]
                def[1] = vector3(firstDef.x, firstDef.y, firstDef.z)
            end

            -- iterate over all deformation points and check if more than one application is necessary
            -- looping is necessary for most vehicles that have a really bad damage model or take a lot of damage (e.g. neon, phantom3)
            local deform = true
            local iteration = 0

            while deform and iteration < MAX_DEFORM_ITERATIONS do
                deform = false

                -- apply deformation if necessary
                for i = 1, #deformationPoints do
                    local def = deformationPoints[i]

                    if (#(GetVehicleDeformationAtPos(vehicle, def[1])) < def[2]) then
                        SetVehicleDamage(vehicle, def[1] * 2.0, def[2] * damageMult, 1000.0, true)
                        deform = true
                    end
                end

                iteration = iteration + 1
                Wait(100)
            end
        end)
    end
end

function GAME.GetLabelText(label, removeFormattingChars)
    local labelText = GetLabelText(label)
    return removeFormattingChars and labelText:gsub('µ', ' ') or labelText
end

if IS_GTA5 then
    local gameBuild = GetGameBuildNumber()

    local StackData = {}
    local __instance = {
        __index = StackData,
        __call = function()
            return "StackData"
        end
    } -- Metatable for instances

    function StackData.New(stack)
        return setmetatable({
            position = 1,
            stack = stack
        }, __instance)
    end

    function StackData:Read(c, raw)
        c = c or 1

        if c == 1 then
            local v = self.stack[self.position]
            self.position += 1
            return v
        elseif c > 1 then
            local v = {}

            for i = 1, c do
                v[#v + 1] = self.stack[self.position]
                self.position += 1
            end

            if raw then
                return v
            else
                return table.unpack(v)
            end
        end
    end

    function StackData:ReadFloat(c)
        c = c or 1
        local v = self:Read(c, true)

        if c == 1 then
            return string.unpack('f', string.pack('j', v))
        elseif c > 1 then
            for i = 1, c do
                v[i] = string.unpack('f', string.pack('j', v[i]))
            end

            return table.unpack(v)
        end
    end

    function StackData:ReadBool()
        return self:Read(1) == 1
    end

    function StackData:Skip(c)
        self.position += c or 1
        return self
    end

    -- helper events
    AddEventHandler("gameEventTriggered", function(name, args)
        if name == "CEventNetworkEntityDamage" then
            local stackData = StackData.New(args)

            local victimId, damagerId = stackData:Read(2)
            local damage = stackData:ReadFloat()

            if gameBuild >= 2060 then stackData:Skip() end -- skip unknown 2060 boolean, enduranceDamage?
            if gameBuild >= 2189 then stackData:Skip() end -- skip unknown 2189 boolean

            local victimDestroyed = stackData:ReadBool()
            local weaponUsed = stackData:Read()
            local victimSpeed = stackData:ReadFloat()
            local damagerSpeed = stackData:ReadFloat()
            local isResponsibleForCollision = stackData:ReadBool()
            local isHeadshot = stackData:ReadBool()
            local isWithMeleeWeapon = stackData:ReadBool()
            local hitMaterial = stackData:Read()

            if PlayerPedId() ~= victimId then return end
            if damagerId == victimId then damagerId = -1 end

            IMPOSTEUR.Emit('playerTookDamage', {
                damagerId = damagerId,
                damage = damage,
                victimDestroyed = victimDestroyed,
                weaponUsed = weaponUsed,
                victimSpeed = victimSpeed,
                damagerSpeed = damagerSpeed,
                isResponsibleForCollision = isResponsibleForCollision,
                isHeadshot = isHeadshot,
                isWithMeleeWeapon = isWithMeleeWeapon,
                hitMaterial = hitMaterial
            })

            if victimDestroyed then
                IMPOSTEUR.EmitServer("playerDeath", damagerId > 0 and NetworkGetNetworkIdFromEntity(damagerId) or damagerId, weaponUsed)
            end
        end
    end)
elseif IS_RDR3 then
    -- Events
    local EVENTS_GROUPS = 4 -- 5 but the last will never be used
    local gameEventsHooks = {}

    function GAME.AddGameEventHook(eventHash, cb)
        local structName = ('GameEvent_%i'):format(eventHash)
        if not Structs[structName] then
            IO.Error(('GAME.AddGameEventHook: struct %s does not exist, please specify event data in structs file.'):format(structName))
            return
        end

        if not gameEventsHooks[eventHash] then
            gameEventsHooks[eventHash] = { structName = structName, cbs = {} }
        end

        local gameEventHooks = gameEventsHooks[eventHash]
        gameEventHooks.cbs[#gameEventHooks.cbs + 1] = cb
    end

    CreateThread(function()
        while true do
            Wait(0)

            for groupIdx = 0, EVENTS_GROUPS - 1 do
                local size = GetNumberOfEvents(groupIdx)

                if size > 0 then
                    for eventIdx = 0, size - 1 do
                        local eventHash = GetEventAtIndex(groupIdx, eventIdx)
                        local hook = gameEventsHooks[eventHash]

                        if hook then
                            local structInfo = Structs[hook.structName]
                            local struct = Structs.New(hook.structName)

                            local eventDataSize = math.floor(structInfo.size / 8)
                            for offsetIdx = 0, eventDataSize - 1 do
                                struct.view:SetInt32(offsetIdx * 8, 0)
                            end

                            local isDataValid = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, groupIdx, eventIdx, struct:Buffer(), eventDataSize)

                            if isDataValid then
                                local data = struct:Parse()

                                for i = 1, #hook.cbs do
                                    hook.cbs[i](data)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- Controls
    local controlsHandlers = {}
    local lastHandlerId = 0

    function GAME.RegisterControlHandler(control, controlHash, ignoreDisabled, cb)
        assert(type(control) == 'number', 'GAME.RegisterControlHandler expects control to be a number')
        assert(type(controlHash) == 'number', 'GAME.RegisterControlHandler expects controlHash to be a number')
        assert(type(ignoreDisabled) == 'boolean', 'GAME.RegisterControlHandler expects ignoreDisabled to be a boolean')
        assert(type(cb) == 'function', 'GAME.RegisterControlHandler expects cb to be a function')

        local handlerId = lastHandlerId + 1
        controlsHandlers[handlerId] = {
            control = control,
            controlHash = controlHash,
            ignoreDisabled = ignoreDisabled,
            cb = cb
        }

        lastHandlerId = handlerId
        return handlerId
    end

    function GAME.UnregisterControlHandler(handlerId)
        assert(type(handlerId) == 'number', 'GAME.UnregisterControlHandler expects handlerId to be a number')

        if not controlsHandlers[handlerId] then return end
        controlsHandlers[handlerId] = nil
    end

    CreateThread(function()
        while true do
            Wait(0)

            for handlerId, handler in pairs(controlsHandlers) do
                local controlPressed = handler.ignoreDisabled and IsDisabledControlJustPressed(handler.control, handler.controlHash) or IsControlJustPressed(handler.control, handler.controlHash)
                if controlPressed then
                    Citizen.CreateThreadNow(handler.cb) -- Use a separated thread to make sure that handlers won't break all others
                end
            end
        end
    end)
end

RegisterNetEvent("libs:game:rpc", function(funcName, argsPayload)
    IO.Debug('libs:game:rpc :', funcName)
    if argsPayload then
        local args <const> = Utils.UnpackArgs(argsPayload, true)
        IO.Debug('libs:game:rpc rpc args :', json.encode(args))
        GAME[funcName](table.unpack(args))
    else
        GAME[funcName]()
    end
end)

IMPOSTEUR.OnNet('requestEntityCreation', function(promiseId, _type, model, coords, ...)
    IO.Debug('requestEntityCreation', promiseId, model, coords, ...)

    local entityId

    if _type == 'ped' then
        local heading = ...
        entityId = GAME.SpawnPed(model, coords, heading, true)
    elseif _type == 'vehicle' then
        local heading = ...
        entityId = GAME.SpawnVehicle(model, coords, heading, true)
    elseif _type == 'object' then
        local dynamic = ...
        entityId = GAME.SpawnObject(model, coords, true, dynamic, true)
    end

    if not entityId then
        return
    end

    while not NetworkGetEntityIsNetworked(entityId) do
        Wait(100)
    end

    local netId = NetworkGetNetworkIdFromEntity(entityId)
    IMPOSTEUR.EmitServer('entityCreationExecuted', promiseId, netId)
end)

TriggerEvent("libs:loaded", "game")

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= CURRENT_RESOURCE then
        return
    end

    for pedId in pairs(GAME.CreatedPeds) do
        GAME.DeleteEntity(pedId)
    end

    for objectId in pairs(GAME.CreatedObjects) do
        GAME.DeleteEntity(objectId)
    end

    for vehicleId in pairs(GAME.CreatedVehicles) do
        GAME.DeleteEntity(vehicleId)
    end

    for netAttachedEntityId, netAttachedEntity in pairs(netAttachedEntities) do
        if netAttachedEntity.handle then
            DeleteEntity(netAttachedEntity.handle)
        end
    end
end)
