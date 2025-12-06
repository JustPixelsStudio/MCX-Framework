local creatorOpen = false
local spawnOpen = false

RegisterNetEvent("mcx_core:openCharacterCreator", function()
    creatorOpen = true
    spawnOpen = false
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openCharacterCreator" })
end)

RegisterNetEvent("mcx_core:openSpawnSelector", function(data)
    if creatorOpen then
        return
    end
    spawnOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openSpawnSelector",
        last_location = data and data.last_location or nil
    })
end)

RegisterNetEvent("mcx_core:closeUI", function()
    creatorOpen = false
    spawnOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeAll" })
end)

RegisterNUICallback("createCharacter", function(data, cb)
    creatorOpen = false
    spawnOpen = true
    TriggerServerEvent("mcx_core:createCharacter", data)
    cb({})
end)

RegisterNUICallback("chooseSpawn", function(data, cb)
    TriggerServerEvent("mcx_core:spawnAt", data)
    cb({})
end)

RegisterNUICallback("closeUI", function(_, cb)
    creatorOpen = false
    spawnOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeAll" })
    cb({})
end)
