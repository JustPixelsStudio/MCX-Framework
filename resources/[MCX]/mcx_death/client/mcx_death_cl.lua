MCX = MCX or {}
MCX.DeathConfig = MCX.DeathConfig or {
    BleedoutTime = 180,
    RespawnFee   = 500,
    ReviveItem   = "medkit",
    ReviveKey    = 38,
    DragKey      = 47,
    RespawnKey   = 38
}

local cfg = MCX.DeathConfig

local isDowned = false
local canRespawn = false
local bleedoutRemaining = 0
local carryingTarget = nil

local injuredDict = "combat@damage@writhe"
local injuredAnim = "writhe_loop"

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
end

local function playInjuredLoop(ped)
    loadAnimDict(injuredDict)
    if not IsEntityPlayingAnim(ped, injuredDict, injuredAnim, 3) then
        TaskPlayAnim(ped, injuredDict, injuredAnim, 4.0, -4.0, -1, 1, 0.0, false, false, false)
    end
end

local function clearInjuredAnim(ped)
    ClearPedTasksImmediately(ped)
end

local function setDownedState(state)
    local ped = PlayerPedId()
    isDowned = state

    if state then
        if LocalPlayer and LocalPlayer.state then
            LocalPlayer.state:set("isDowned", true, true)
        end

        -- Make sure ped is "alive" but critically injured
        local coords = GetEntityCoords(ped)
        if IsEntityDead(ped) then
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false, false)
            Wait(50)
        end

        SetEntityHealth(ped, 101)            -- keep just above "real" death
        SetEntityInvincible(ped, true)
        SetEntityCanBeDamaged(ped, false)
        SetPedDiesWhenInjured(ped, false)

        -- Start injured pose loop
        CreateThread(function()
            while isDowned do
                ped = PlayerPedId()
                if not IsEntityPlayingAnim(ped, injuredDict, injuredAnim, 3) then
                    playInjuredLoop(ped)
                end
                Wait(1000)
            end
            -- On exit, clean up anim
            clearInjuredAnim(PlayerPedId())
        end)

        bleedoutRemaining = cfg.BleedoutTime
        canRespawn = false

        SendNUIMessage({
            action = "OPEN",
            time = bleedoutRemaining,
            respawnFee = cfg.RespawnFee
        })
        SetNuiFocus(false, false)

        TriggerServerEvent("mcx_death:onPlayerDowned")

        -- Timer thread
        CreateThread(function()
            while isDowned and bleedoutRemaining > 0 do
                Wait(1000)
                bleedoutRemaining = bleedoutRemaining - 1
                SendNUIMessage({
                    action = "UPDATE_TIMER",
                    time = bleedoutRemaining
                })
            end

            if isDowned then
                canRespawn = true
                SendNUIMessage({
                    action = "ENABLE_RESPAWN",
                    respawnFee = cfg.RespawnFee
                })
            end
        end)
    else
        if LocalPlayer and LocalPlayer.state then
            LocalPlayer.state:set("isDowned", false, true)
        end

        SetEntityInvincible(ped, false)
        SetEntityCanBeDamaged(ped, true)
        SetPedDiesWhenInjured(ped, true)

        SendNUIMessage({ action = "CLOSE" })
        canRespawn = false
        bleedoutRemaining = 0
    end
end

-- Watch for death / low HP to enter downed state
local function handleLocalDeathCheck()
    CreateThread(function()
        while true do
            Wait(200)
            local ped = PlayerPedId()

            if not isDowned then
                local health = GetEntityHealth(ped)
                if IsEntityDead(ped) or health <= 101 then
                    -- Prevent regular death loop
                    local coords = GetEntityCoords(ped)
                    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false, false)
                    Wait(50)
                    setDownedState(true)
                end
            end
        end
    end)
end

-- Disable key actions while downed but keep E working
local function handleDownedControls()
    CreateThread(function()
        while true do
            if isDowned then
                Wait(0)

                -- Movement
                DisableControlAction(0, 30, true) -- move left/right
                DisableControlAction(0, 31, true) -- move forward/back
                DisableControlAction(0, 21, true) -- sprint
                DisableControlAction(0, 22, true) -- jump
                DisableControlAction(0, 24, true) -- attack
                DisableControlAction(0, 25, true) -- aim
                DisableControlAction(0, 44, true) -- cover
                DisableControlAction(0, 37, true) -- weapon wheel
                DisableControlAction(0, 23, true) -- enter vehicle
                DisableControlAction(0, 75, true) -- exit vehicle
                DisableControlAction(0, 140, true)
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)

                -- Allow looking and chat, E will still be active
                EnableControlAction(0, 1, true)
                EnableControlAction(0, 2, true)
                EnableControlAction(0, 245, true) -- chat

                if canRespawn and IsControlJustReleased(0, cfg.RespawnKey) then
                    TriggerServerEvent("mcx_death:requestHospitalRespawn")
                    canRespawn = false
                end
            else
                Wait(300)
            end
        end
    end)
end

-- Utility: get closest downed player
local function getClosestDownedPlayer(maxDistance)
    maxDistance = maxDistance or 3.0
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local closestPlayer, closestDist

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local target = GetPlayerPed(playerId)
            if DoesEntityExist(target) then
                local dist = #(GetEntityCoords(target) - pCoords)
                if dist <= maxDistance then
                    local state = Player(playerId).state
                    if state and state.isDowned then
                        if not closestDist or dist < closestDist then
                            closestDist = dist
                            closestPlayer = playerId
                        end
                    end
                end
            end
        end
    end

    if closestPlayer then
        return closestPlayer, closestDist
    end
    return nil, nil
end

local function showHelpNotification(msg)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

-- Revive / drag logic for other players
local function handleHelperInteractions()
    CreateThread(function()
        while true do
            Wait(0)
            if isDowned then
                goto continue
            end

            local closestPlayer, dist = getClosestDownedPlayer(3.0)
            if closestPlayer and dist and dist <= 3.0 then
                local targetSrc = GetPlayerServerId(closestPlayer)

                showHelpNotification("Press ~INPUT_CONTEXT~ to revive | Press ~INPUT_DETONATE~ to drag")

                if IsControlJustReleased(0, cfg.ReviveKey) then
                    TriggerServerEvent("mcx_death:attemptRevive", targetSrc)
                    Wait(500)
                end

                if IsControlJustReleased(0, cfg.DragKey) then
                    TriggerServerEvent("mcx_death:toggleDrag", targetSrc)
                    Wait(500)
                end
            end

            ::continue::
        end
    end)
end

-- Carry / drag sync (very simple attach/detach)
RegisterNetEvent("mcx_death:startDrag", function(targetSrc)
    local ped = PlayerPedId()
    local targetPlayer = GetPlayerFromServerId(targetSrc)
    local targetPed = GetPlayerPed(targetPlayer)

    if carryingTarget or not DoesEntityExist(targetPed) then return end

    carryingTarget = targetSrc

    AttachEntityToEntity(targetPed, ped, 11816, 0.27, 0.15, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, true)
end)

RegisterNetEvent("mcx_death:stopDrag", function(targetSrc)
    local targetPlayer = GetPlayerFromServerId(targetSrc)
    local targetPed = GetPlayerPed(targetPlayer)
    if DoesEntityExist(targetPed) then
        DetachEntity(targetPed, true, true)
    end
    carryingTarget = nil
end)

-- Revive target client-side
RegisterNetEvent("mcx_death:doRevive", function()
    if not isDowned then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z + 0.1, GetEntityHeading(ped), true, false, false)
    SetEntityHealth(ped, 200)
    clearInjuredAnim(ped)

    setDownedState(false)
end)

-- Clear downed state when server respawns us at hospital (via mcx_core)
RegisterNetEvent("mcx_death:clearDownedState", function()
    if isDowned then
        setDownedState(false)
    end
end)

-- Also listen to core spawn event as a safety net
RegisterNetEvent("mcx_core:doSpawn", function()
    if isDowned then
        setDownedState(false)
    end
end)

RegisterNUICallback("noop", function(_, cb)
    cb({})
end)

handleLocalDeathCheck()
handleDownedControls()
handleHelperInteractions()
