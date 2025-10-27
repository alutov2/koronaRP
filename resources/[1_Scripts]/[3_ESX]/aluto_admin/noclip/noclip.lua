ESX = nil

while ESX == nil do
	ESX = exports["es_extended"]:getSharedObject()
end


NoClipSpeed = 0.5
NoclipType = 1
local firstopen = true
configNoClip = {
    Locale = 'en',

    Controls = {
        -- FiveM Controls: https://docs.fivem.net/game-references/controls/
        --openKey = 170, 
        goUp = 22, 
        goDown = 61, 
        turnLeft = 34, 
        turnRight = 35, 
        goForward = 32,  
        goBackward = 33, 
        changeSpeed = 335, 
        changeSpeedDown = 336 , 
        camMode = 74, 
    },

    Speeds = {
        
        { label = 'Very Slow', speed = 0},
        { label = 'Slow', speed = 0.5},
        { label = 'Normal', speed = 2},
        { label = 'Fast', speed = 5},
        { label = 'Very Fast', speed = 10},
        { label = 'Max', speed = 15},
    },

    Offsets = {
        y = 0.5, 
        z = 0.2, 
        h = 3, 
    },

    EnableHUD = true,

    FrozenPosition = false, 

    DisableWeaponWheel = true, 
}




local acces = false
local playerGroup = nil
local firstTime = true

Citizen.CreateThread(function() 
    while true do 
        Wait(10)
        if staffMode then 
            acces = true
        else 
            acces = false
        end 
    end
end)

RegisterCommand('ElNoclip', function()
    if acces then 
        toggleNoClip()
    end
end)

local index = 1
local currentSpeed = configNoClip.Speeds[index].speed
local followCamMode = true
local showHelpCommands = true
local scaleform = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")

local closestPlayer = nil
local closestDistance = -1

local removeInvisibility = nil

Citizen.CreateThread(function()
    while true do
        --if NoclipType == 1 then
            function toggleNoClip(args)
                removeInvisibility = args
                noclipActive = not noclipActive
            
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    noclipEntity = GetVehiclePedIsIn(PlayerPedId(), false)
                else
                    noclipEntity = PlayerPedId()
                end
                
                if noclipActive then
                    SetEntityVisible(noclipEntity, false, false);
                    SetEntityAlpha(PlayerPedId(), 150, false)
                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                        SetEntityAlpha(noclipEntity, 150, false)
                    else
                        --GiveWeaponToPed(PlayerPedId(), YveltConfig.StaffGunName, 255, false, true)
                    end
                else
                    SetEntityVisible(noclipEntity, true, false);
                    ResetEntityAlpha(PlayerPedId())
                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                        ResetEntityAlpha(noclipEntity)
                    else
                        --GiveWeaponToPed(PlayerPedId(), YveltConfig.StaffGunName, 255, false, true)
                    end
                end
        
                if configNoClip.DisableWeaponWheel and noclipActive then
                    DisableControlAction(0, 37, true)
        
                end
        
                if configNoClip.FrozenPosition then SetEntityHeading(noclipEntity, GetEntityHeading(noclipEntity)+180) end
                SetEntityCollision(noclipEntity, not noclipActive, not noclipActive)
                FreezeEntityPosition(noclipEntity, noclipActive)
                SetEntityInvincible(noclipEntity, noclipActive)
                SetVehicleRadioEnabled(noclipEntity, not noclipActive)
                SetEveryoneIgnorePlayer(noclipEntity, noclipActive);
                SetPoliceIgnorePlayer(noclipEntity, noclipActive);
        
                if not IsPedSittingInAnyVehicle(PlayerPedId()) then
                    ClearPedTasksImmediately(PlayerPedId())
                end
        
        
                if noclipActive then
                    while noclipActive do
        
                        if showHelpCommands then
                            BeginScaleformMovieMethod(scaleform, "CLEAR_ALL")
                            EndScaleformMovieMethod()
                                    BeginScaleformMovieMethod(scaleform, "SET_DATA_SLOT")
                                    ScaleformMovieMethodAddParamInt(5)
                                    PushScaleformMovieMethodParameterString(GetControlInstructionalButton(2, 23, true))
                                    PushScaleformMovieMethodParameterString("Cacher les pseudos")
                                    EndScaleformMovieMethod()
                                
                                    BeginScaleformMovieMethod(scaleform, "SET_DATA_SLOT")
                                    ScaleformMovieMethodAddParamInt(5)
                                    PushScaleformMovieMethodParameterString(GetControlInstructionalButton(2, 23, true))
                                    PushScaleformMovieMethodParameterString("Afficher les pseudos")
                                    EndScaleformMovieMethod()

        
                            DrawScaleformMovieFullscreen(scaleform)            
                        end
        
                        local yoff = 0.0
                        local zoff = 0.0
        
                        if IsDisabledControlJustPressed(0, configNoClip.Controls.camMode) then
                            followCamMode = not followCamMode
                        end
        
        
        
        
                        HideHudComponentThisFrame(19)
                        HideHudComponentThisFrame(20)
                        HideHudComponentThisFrame(21)
                        HideHudComponentThisFrame(22)
        
                        if IsControlJustPressed(0, configNoClip.Controls.changeSpeed) then
                            if currentSpeed > 19 then
                                currentSpeed = 20
                            else
                                currentSpeed = currentSpeed + 1
                            end
                        end
        
                        if IsControlJustPressed(0, configNoClip.Controls.changeSpeedDown) then
                            if currentSpeed < 1 then
                                currentSpeed = 0
                            else
                                currentSpeed = currentSpeed - 1
                            end
                        end
                            
                        DisableControlAction(0, 30, true)
                        DisableControlAction(0, 31, true)
                        DisableControlAction(0, 32, true)
                        DisableControlAction(0, 33, true)
                        DisableControlAction(0, 34, true)
                        DisableControlAction(0, 35, true)
                        DisableControlAction(0, 266, true)
                        DisableControlAction(0, 267, true)
                        DisableControlAction(0, 268, true)
                        DisableControlAction(0, 269, true)
                        DisableControlAction(0, 44, true)
                        DisableControlAction(0, 20, true)
                        DisableControlAction(0, 75, true)
                        DisableControlAction(0, 74, true)
        
                        if IsDisabledControlPressed(0, configNoClip.Controls.goForward) then
                            if configNoClip.FrozenPosition then
                                yoff = -configNoClip.Offsets.y
                            else 
                                yoff = configNoClip.Offsets.y
                            end
                        end
                        
                        if IsDisabledControlPressed(0, configNoClip.Controls.goBackward) then
                            if configNoClip.FrozenPosition then
                                yoff = configNoClip.Offsets.y
                            else
                                yoff = -configNoClip.Offsets.y
                            end
                        end
        
                        if not followCamMode and IsDisabledControlPressed(0, configNoClip.Controls.turnLeft) then
                            SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId())+configNoClip.Offsets.h)
                        end
                        
                        if not followCamMode and IsDisabledControlPressed(0, configNoClip.Controls.turnRight) then
                            SetEntityHeading(PlayerPedId(), GetEntityHeading(PlayerPedId())-configNoClip.Offsets.h)
                        end
                        
                        if IsDisabledControlPressed(0, configNoClip.Controls.goUp) then
                            zoff = configNoClip.Offsets.z
                        end
                        
                        if IsDisabledControlPressed(0, configNoClip.Controls.goDown) then
                            zoff = -configNoClip.Offsets.z
                        end
                        
                        local newPos = GetOffsetFromEntityInWorldCoords(noclipEntity, 0.0, yoff * (currentSpeed + 0.3), zoff * (currentSpeed + 0.3))
                        local heading = GetEntityHeading(noclipEntity)
                        SetEntityVelocity(noclipEntity, 0.0, 0.0, 0.0)
                        if configNoClip.FrozenPosition then
                            SetEntityRotation(noclipEntity, 0.0, 0.0, 180.0, 0, false)
                        else 
                            SetEntityRotation(noclipEntity, 0.0, 0.0, 0.0, 0, false)
                        end
                        if(followCamMode) then
                            SetEntityHeading(noclipEntity, GetGameplayCamRelativeHeading());
                        else
                            SetEntityHeading(noclipEntity, heading);
                        end
                        if configNoClip.FrozenPosition then
                            SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, not noclipActive, not noclipActive, not noclipActive)
                        else 
                            SetEntityCoordsNoOffset(noclipEntity, newPos.x, newPos.y, newPos.z, noclipActive, noclipActive, noclipActive)
                        end
                        SetLocalPlayerVisibleLocally(true);
                        Wait(0)
                    end
                end
                if not removeInvisibility then
                    SetEntityVisible(PlayerPedId(), true)
                    Wait(10)
                    if not IsPedSittingInAnyVehicle(PlayerPedId()) then
                        ClearPedTasksImmediately(PlayerPedId())
                    end
                end
            end
        --end
        Wait(10)
    end
end)

function getCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch = GetGameplayCamRelativePitch()
    local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
    local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))

    if len ~= 0 then
        coords = coords / len
    end

    return coords
end

function GetPlayersInCameraView()
    local playersInCamera = {}
    local cameraCoords = GetGameplayCamCoord()
    local cameraRotation = GetGameplayCamRot(2)

    for _, playerId in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)

        
        if HasEntityClearLosToEntity(playerPed, PlayerPedId(), 17) and
            IsEntityOnScreen(playerPed) then
            table.insert(playersInCamera, playerId)
        end
    end

    return playersInCamera
end

function IsPlayerInCameraView(playerCoords, cameraCoords, cameraRotation)
    local vector = vector3(playerCoords.x - cameraCoords.x, playerCoords.y - cameraCoords.y, playerCoords.z - cameraCoords.z)
    local camForward = vector3(math.cos(cameraRotation.z * math.pi / 180.0), math.sin(cameraRotation.z * math.pi / 180.0), 0.0)
    local dotProduct = camForward.x * vector.x + camForward.y * vector.y + camForward.z * vector.z
    local cosAngle = dotProduct / #(camForward * vector)

    return cosAngle > 0.5
end


local noclip = false
local noclip_speed = 1.0 


--[[function toggleNoclip()
    noclip = not noclip
    local ped = PlayerPedId()

    if noclip then
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false, false)
        TriggerEvent('chat:addMessage', {args = {"^2Noclip activé"}})
    else
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        TriggerEvent('chat:addMessage', {args = {"^1Noclip désactivé"}})
    end
end]]


--[[Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if noclip then
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            local dx, dy, dz = GetGameplayCamRelativeHeading(), GetGameplayCamRelativePitch(), GetEntityHeading(ped)
            local forwardVector = GetEntityForwardVector(ped)
            
            
            if IsControlPressed(0, 21) then 
                noclip_speed = 2.5
            else
                noclip_speed = 1.0
            end

            
            if IsControlPressed(0, 32) then 
                x = x + forwardVector.x * noclip_speed
                y = y + forwardVector.y * noclip_speed
                z = z + forwardVector.z * noclip_speed
            end

            if IsControlPressed(0, 33) then 
                x = x - forwardVector.x * noclip_speed
                y = y - forwardVector.y * noclip_speed
                z = z - forwardVector.z * noclip_speed
            end

            if IsControlPressed(0, 34) then 
                SetEntityHeading(ped, GetEntityHeading(ped) + 1.5)
            end

            if IsControlPressed(0, 35) then 
                SetEntityHeading(ped, GetEntityHeading(ped) - 1.5)
            end

            SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
        end
    end
end)]]