MCX = MCX or {}
MCX.DeathConfig = MCX.DeathConfig or {
    BleedoutTime = 180,
    RespawnFee   = 500,
    ReviveItem   = "medkit"
}

local cfg = MCX.DeathConfig
local DownedPlayers = {}

RegisterNetEvent("mcx_death:onPlayerDowned", function()
    local src = source
    DownedPlayers[src] = true
end)

AddEventHandler("playerDropped", function()
    local src = source
    DownedPlayers[src] = nil
end)

RegisterNetEvent("mcx_death:requestHospitalRespawn", function()
    local src = source
    local fee = cfg.RespawnFee or 0

    local player = MCX.GetPlayer and MCX.GetPlayer(src) or nil

    if player and fee > 0 then
        local cash = player.cash or 0
        local bank = player.bank or 0
        local total = cash + bank

        if total >= fee then
            local remaining = fee

            if cash >= remaining then
                player.cash = cash - remaining
                remaining = 0
            else
                player.cash = 0
                remaining = remaining - cash
            end

            if remaining > 0 then
                player.bank = bank - remaining
            end

            if player.Save then
                player:Save()
            end
        else
            print(("[MCX][Death] Player %d could not afford respawn fee (%d), allowing free respawn."):format(src, fee))
        end
    end

    TriggerEvent("mcx_core:handleRespawnRequest", src, "hospital")

    DownedPlayers[src] = nil
    TriggerClientEvent("mcx_death:clearDownedState", src)
end)

RegisterNetEvent("mcx_death:attemptRevive", function(targetSrc)
    local src = source
    targetSrc = tonumber(targetSrc)

    if not targetSrc or not DownedPlayers[targetSrc] then
        return
    end

    -- TODO: inventory check for cfg.ReviveItem

    DownedPlayers[targetSrc] = nil
    TriggerClientEvent("mcx_death:doRevive", targetSrc)

    TriggerClientEvent("chat:addMessage", src, {
        args = { "^2SYSTEM", "You revived the player." }
    })
end)

RegisterNetEvent("mcx_death:toggleDrag", function(targetSrc)
    local src = source
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not DownedPlayers[targetSrc] then return end

    TriggerClientEvent("mcx_death:startDrag", src, targetSrc)
end)
