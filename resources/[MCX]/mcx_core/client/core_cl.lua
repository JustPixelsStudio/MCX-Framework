-- Disable spawnmanager auto-spawn if present, and handle our own ready event
CreateThread(function()
    -- Try to disable spawnmanager autos spawn if resource is running
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

    TriggerServerEvent("mcx_core:playerReady")
end)

RegisterNetEvent("mcx_core:characterLoaded", function(data)
    print(("[MCX] Character loaded: %s %s (Level %d, XP %d)"):format(
        data.first_name,
        data.last_name,
        data.level or 1,
        data.xp or 0
    ))

    if data.ped_model then
        local model = GetHashKey(data.ped_model)
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 5000 do
            Wait(0)
            timeout = timeout + 1
        end
        if HasModelLoaded(model) then
            SetPlayerModel(PlayerId(), model)
            SetModelAsNoLongerNeeded(model)
        else
            print("[MCX] Failed to load ped model: " .. tostring(data.ped_model))
        end
    end
end)

RegisterNetEvent("mcx_core:levelUp", function(level)
    print("[MCX] Level up! New level: " .. tostring(level))
end)

RegisterNetEvent("mcx_core:doSpawn", function(location)
    if not location or not location.x then
        print("[MCX] Invalid spawn location, using default coords.")
        location = { x = -1037.0, y = -2737.0, z = 20.0 }
    end

    local ped = PlayerPedId()
    local x = location.x + 0.0
    local y = location.y + 0.0
    local z = location.z + 0.0

    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCoords(ped, x, y, z)
end)
