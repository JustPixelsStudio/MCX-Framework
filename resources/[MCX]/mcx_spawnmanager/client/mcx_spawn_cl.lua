

local isDead = false
local isDowned = false
local canRespawn = false
local respawnTimer = 0

local RESPAWN_DELAY = 5000 -- 15 seconds before the player can respawn

---------------------------------------------------------------------
-- Utility: simple on-screen text at bottom center
---------------------------------------------------------------------
local function drawBottomText(text)
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextOutline()
    SetTextCentre(true)

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.9)
end

---------------------------------------------------------------------
-- Death / downed state detection
-- Hybrid-friendly: you can later add bleedout & EMS logic here.
---------------------------------------------------------------------
CreateThread(function()
    local wasDead = false

    while true do
        local ped = PlayerPedId()
        local pedDead = IsEntityDead(ped)

        if pedDead and not wasDead then
            -- Just died
            isDead = true
            isDowned = true
            respawnTimer = GetGameTimer() + RESPAWN_DELAY
            canRespawn = false
        elseif not pedDead and wasDead then
            -- Just revived (after respawn)
            isDead = false
            isDowned = false
            canRespawn = false
        end

        wasDead = pedDead
        Wait(250)
    end
end)

---------------------------------------------------------------------
-- Simple "press E to respawn at last location" for now
-- Uses last_location via mcx_core + DB, falls back to hospital.
---------------------------------------------------------------------
CreateThread(function()
    while true do
        if isDowned then
            local now = GetGameTimer()
            if not canRespawn and now >= respawnTimer then
                canRespawn = true
            end

            if canRespawn then
                drawBottomText("~r~You are downed~s~ - Press ~g~[E]~s~ to respawn at ~y~last location")

                if IsControlJustPressed(0, 38) then -- E
                    -- Ask server to respawn us at last_location (with fallback)
                    TriggerServerEvent("mcx_spawn:requestRespawn", "last_location")
                    canRespawn = false
                end
            else
                local secondsLeft = math.floor((respawnTimer - now) / 1000)
                if secondsLeft < 0 then secondsLeft = 0 end
                drawBottomText(("~r~You are downed~s~ - You can respawn in ~y~%d~s~ seconds"):format(secondsLeft))
            end
        end

        Wait(0)
    end
end)

---------------------------------------------------------------------
-- Optional hook: if you later want mcx_spawnmanager to own initial spawn
---------------------------------------------------------------------
RegisterNetEvent("mcx_spawn:doLocalSpawn", function(location)
    -- For now, mcx_core:doSpawn handles spawning.
    -- This exists as a future hook if you want to move logic here.
end)

