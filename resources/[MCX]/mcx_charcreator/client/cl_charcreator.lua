
local creatorOpen = false

local function closeCreatorUI()
    creatorOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeAll" })
end

-- Opened from mcx_core when the player needs to create a character
RegisterNetEvent("mcx_core:openCharacterCreator", function()
    creatorOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openCharacterCreator" })
end)

-- Optional: allow core or other resources to force-close this UI
RegisterNetEvent("mcx_core:closeUI", function()
    if creatorOpen then
        closeCreatorUI()
    end
end)

-- NUI: character creation payload from app.js
-- data = { first_name, last_name, ped_model, skin = {} }
RegisterNUICallback("createCharacter", function(data, cb)
    if type(data) ~= "table" then data = {} end

    TriggerServerEvent("mcx_core:createCharacter", {
        first_name = data.first_name,
        last_name  = data.last_name,
        ped_model  = data.ped_model,
        skin       = data.skin or {}
    })

    -- Immediately close the creator; mcx_core will then open the spawn menu
    closeCreatorUI()
    cb({})
end)

-- NUI: close button / ESC route
RegisterNUICallback("closeUI", function(_, cb)
    closeCreatorUI()
    cb({})
end)
