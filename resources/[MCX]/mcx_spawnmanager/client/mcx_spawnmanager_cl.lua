local spawnOpen = false

local function closeSpawnUI()
    spawnOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeAll" })
end

-- Open from mcx_core, pass available spawn locations + last location flag
-- Expected data format (you can adjust in mcx_core if needed):
-- {
--   spawns = {
--      { label = "Hospital", x = 0.0, y = 0.0, z = 0.0, heading = 0.0 },
--      ...
--   },
--   last_location_available = true/false
-- }
RegisterNetEvent("mcx_core:openSpawnSelector", function(data)
    if spawnOpen then return end

    spawnOpen = true
    SetNuiFocus(true, true)

    local payload = {
        action = "openSpawnSelector",
        spawns = {},
        last_location_available = false
    }

    if type(data) == "table" then
        if type(data.spawns) == "table" then
            payload.spawns = data.spawns
        end

        if data.last_location_available ~= nil then
            payload.last_location_available = data.last_location_available and true or false
        end
    end

    SendNUIMessage(payload)
end)

-- NUI: chosen spawn (either coords or { type = "last_location" })
RegisterNUICallback("chooseSpawn", function(data, cb)
    TriggerServerEvent("mcx_core:spawnAt", data)
    cb({})
end)

RegisterNUICallback("closeUI", function(_, cb)
    closeSpawnUI()
    cb({})
end)

RegisterNetEvent("mcx_spawnmanager:closeUI", function()
    if not spawnOpen then return end
    closeSpawnUI()
end)
