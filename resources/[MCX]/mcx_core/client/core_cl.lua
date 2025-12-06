-- mcx_core/core_cl.lua

MCX = MCX or {}
MCX.Core = MCX.Core or {}

local Core = MCX.Core

Core.Player = Core.Player or {
    loaded = false,
    character = nil,   -- full character row from server
}

---------------------------------------------------------------------
-- Utility: safe model loading & applying
---------------------------------------------------------------------

local function loadModel(modelNameOrHash)
    local model = modelNameOrHash

    if type(modelNameOrHash) == "string" then
        model = GetHashKey(modelNameOrHash)
    end

    if not IsModelInCdimage(model) or not IsModelValid(model) then
        print(("[MCX] Invalid ped model requested: %s"):format(tostring(modelNameOrHash)))
        return nil
    end

    RequestModel(model)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        if GetGameTimer() > timeout then
            print(("[MCX] Timed out loading model: %s"):format(tostring(modelNameOrHash)))
            return nil
        end
        Wait(0)
    end

    return model
end

--- Apply a player model safely and fix invisibility / collision issues
---@param modelName string|number
local function applyPlayerModel(modelName)
    local model = loadModel(modelName)
    if not model then
        return nil
    end

    -- Apply the model
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    -- VERY IMPORTANT: refresh ped handle after changing model
    local ped = PlayerPedId()

    -- Basic reset to avoid invisible / stuck states
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)

    -- Optional: basic health/armor reset for fresh character load
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)

    return ped
end

---------------------------------------------------------------------
-- Utility: basic skin application stub
-- (Expand later when you add full face/clothing customization)
---------------------------------------------------------------------

local function applyBasicSkin(ped, skinData)
    if not ped or not DoesEntityExist(ped) then return end
    if not skinData or type(skinData) ~= "table" then return end

    -- Placeholder for future full customization hooks
end

---------------------------------------------------------------------
-- Client bootstrap: disable default spawnmanager if present, notify core
---------------------------------------------------------------------

CreateThread(function()
    -- Try to disable spawnmanager auto spawn if resource is running
    if GetResourceState("spawnmanager") == "started" then
        pcall(function()
            exports.spawnmanager:setAutoSpawn(false)
        end)
    end

    -- Wait for network session, then notify core
    while not NetworkIsSessionActive() do
        Wait(0)
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()

    -- Tell server we are ready so it can:
    --  - Ensure account
    --  - Load/create character
    --  - Send mcx_core:characterLoaded + spawn/menu events
    TriggerServerEvent("mcx_core:playerReady")
end)

---------------------------------------------------------------------
-- Character loaded from server
-- data = full character row + any extra fields server attaches
---------------------------------------------------------------------

RegisterNetEvent("mcx_core:characterLoaded", function(data)
    if not data then
        print("[MCX] characterLoaded received with no data")
        return
    end

    Core.Player.loaded = true
    Core.Player.character = data

    print(("[MCX] Character loaded: %s %s (Level %d, XP %d)"):format(
        data.first_name or "Unknown",
        data.last_name or "Unknown",
        data.level or 1,
        data.xp or 0
    ))

    local ped

    -- 1) Apply ped model (fallback to freemode if missing/invalid)
    local modelName = data.ped_model or "mp_m_freemode_01"

    ped = applyPlayerModel(modelName)
    if not ped then
        -- Hard fallback if model was invalid / failed to load
        ped = applyPlayerModel("mp_m_freemode_01")
    end

    -- 2) Apply skin (if server provided decoded skin table)
    if data.skin and type(data.skin) == "table" then
        applyBasicSkin(ped, data.skin)
    end

    -- Spawning/location is handled separately (spawn menu / mcx_spawnmanager)
end)

---------------------------------------------------------------------
-- Level up notification (can be replaced by UI later)
---------------------------------------------------------------------

RegisterNetEvent("mcx_core:levelUp", function(level)
    print("[MCX] Level up! New level: " .. tostring(level))
end)

---------------------------------------------------------------------
-- Spawn handler
-- Called by server (or spawn menu resource) to put player into world
-- location = { x = number, y = number, z = number, heading = number? }
---------------------------------------------------------------------

RegisterNetEvent("mcx_core:doSpawn", function(location)
    if not location or not location.x or not location.y or not location.z then
        print("[MCX] Invalid spawn location, using default coords.")
        location = { x = -1037.0, y = -2737.0, z = 20.0, heading = 330.0 }
    end

    local ped = PlayerPedId()
    local x = location.x + 0.0
    local y = location.y + 0.0
    local z = location.z + 0.0
    local heading = (location.heading or 0.0) + 0.0

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    if not DoesEntityExist(ped) then
        ped = PlayerPedId()
    end

    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    ClearPedTasksImmediately(ped)

    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)

    RequestCollisionAtCoord(x, y, z)
    local timeout = GetGameTimer() + 3000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

    DoScreenFadeIn(500)
end)

---------------------------------------------------------------------
-- Periodic last_location update -> server (for respawns & reconnects)
---------------------------------------------------------------------

CreateThread(function()
    while true do
        if Core.Player.loaded then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)

                TriggerServerEvent("mcx_core:updateLastLocation", {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = heading
                })
            end
        end

        Wait(30000) -- every 30 seconds
    end
end)
