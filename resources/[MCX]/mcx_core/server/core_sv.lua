AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    deferrals.update("Loading Midnight City account...")

    local identifier = MCX.Utils.GetIdentifier(src)
    if not identifier then
        deferrals.done("No valid identifier found. Please restart FiveM / check your Rockstar/Steam.")
        return
    end

    MCX.DB.EnsureAccount(identifier, name, function()
        deferrals.done()
    end)
end)

RegisterNetEvent("mcx_core:playerReady", function()
    local src = source
    local identifier = MCX.Utils.GetIdentifier(src)
    if not identifier then
        DropPlayer(src, "MCX: No identifier found.")
        return
    end

    MCX.DB.GetCharacterByIdentifier(identifier, function(charRow)
        if not charRow then
            TriggerClientEvent("mcx_core:openCharacterCreator", src)
            return
        end

        local player = MCX.CreatePlayer(src, charRow)

        print(("[MCX] Loaded character %s (ID %d) for %s"):format(
            player:GetFullName(),
            player.char_id,
            identifier
        ))

        TriggerClientEvent("mcx_core:characterLoaded", src, {
            char_id = player.char_id,
            identifier = player.identifier,
            first_name = player.first_name,
            last_name = player.last_name,
            ped_model = player.ped_model,
            level = player.level,
            xp = player.xp,
            cash = player.cash,
            bank = player.bank,
            last_location = player.last_location
        })

        TriggerClientEvent("mcx_core:openSpawnSelector", src, {
            last_location = player.last_location
        })
    end)
end)

RegisterNetEvent("mcx_core:createCharacter", function(data)
    local src = source
    local identifier = MCX.Utils.GetIdentifier(src)
    if not identifier then
        DropPlayer(src, "MCX: No identifier found on character create.")
        return
    end

    if not data or not data.first_name or not data.last_name then
        print("[MCX] Invalid character data from source " .. tostring(src))
        return
    end

    MCX.DB.CreateCharacter(identifier, data, function(charId)
        print(("[MCX] Created character %s %s (ID %d) for %s"):format(
            data.first_name, data.last_name, charId, identifier
        ))

        MCX.DB.GetCharacterByIdentifier(identifier, function(charRow)
            if not charRow then return end

            local player = MCX.CreatePlayer(src, charRow)

            TriggerClientEvent("mcx_core:characterLoaded", src, {
                char_id = player.char_id,
                identifier = player.identifier,
                first_name = player.first_name,
                last_name = player.last_name,
                ped_model = player.ped_model,
                level = player.level,
                xp = player.xp,
                cash = player.cash,
                bank = player.bank,
                last_location = player.last_location
            })

            TriggerClientEvent("mcx_core:openSpawnSelector", src, {
                last_location = player.last_location
            })
        end)
    end)
end)

RegisterNetEvent("mcx_core:spawnAt", function(location)
    local src = source
    local player = MCX.GetPlayer(src)
    if not player then
        print("[MCX] spawnAt called but player not loaded: " .. tostring(src))
        return
    end

    if not location then
        location = {}
    end

    local lx = tonumber(location.x)
    local ly = tonumber(location.y)
    local lz = tonumber(location.z)

    local loc
    if lx and ly and lz then
        loc = { x = lx, y = ly, z = lz }
    else
        print("[MCX] Invalid spawn coords from client, using default.")
        loc = { x = -1037.0, y = -2737.0, z = 20.0 }
    end

    player:SetLastLocation(loc)
    player:Save()
    TriggerClientEvent("mcx_core:doSpawn", src, loc)
    TriggerClientEvent("mcx_core:closeUI", src)
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    local player = MCX.GetPlayer(src)

    if player then
        player:Save()
        MCX.Players[src] = nil
        print(("[MCX] Saved character %s (ID %d) on drop. Reason: %s"):format(
            player:GetFullName(),
            player.char_id,
            reason or "unknown"
        ))
    end
end)
