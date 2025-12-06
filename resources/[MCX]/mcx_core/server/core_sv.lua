-- mcx_core/core_sv.lua

MCX = MCX or {}
MCX.Core = MCX.Core or {}
MCX.DB = MCX.DB or {}

local Core = MCX.Core
Core.Players = Core.Players or {}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function getIdentifier(src)
    -- Adjust this if you want to use license: or something else
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == "license:" then
            return id
        end
    end
    return GetPlayerIdentifier(src, 0)
end

local function decodeCharacterRow(row)
    if not row then return nil end

    if row.skin and type(row.skin) == "string" and row.skin ~= "" then
        local ok, decoded = pcall(json.decode, row.skin)
        if ok and type(decoded) == "table" then
            row.skin = decoded
        else
            row.skin = {}
        end
    elseif type(row.skin) ~= "table" then
        row.skin = {}
    end

    if row.last_location and type(row.last_location) == "string" and row.last_location ~= "" then
        local ok, decoded = pcall(json.decode, row.last_location)
        if ok and type(decoded) == "table" then
            row.last_location = decoded
        else
            row.last_location = nil
        end
    else
        row.last_location = nil
    end

    return row
end

local function sendCharacterAndSpawnMenu(src, charRow)
    charRow = decodeCharacterRow(charRow)

    Core.Players[src] = {
        src = src,
        identifier = Core.Players[src] and Core.Players[src].identifier or nil,
        account_id = Core.Players[src] and Core.Players[src].account_id or nil,
        char_id = charRow.char_id,
        character = charRow
    }

    -- Send character data to client (sets ped, etc.)
    TriggerClientEvent("mcx_core:characterLoaded", src, charRow)

    -- Open spawn selector with last_location (if any)
    TriggerClientEvent("mcx_core:openSpawnSelector", src, {
        last_location = charRow.last_location
    })
end

---------------------------------------------------------------------
-- Player state management
---------------------------------------------------------------------

AddEventHandler("playerDropped", function(reason)
    local src = source
    Core.Players[src] = nil
end)

---------------------------------------------------------------------
-- Entry point from client (core_cl)
--  - ensure account
--  - load/create character (mcx_charcreator handles UI)
--  - send character data + spawn selector
---------------------------------------------------------------------

RegisterNetEvent("mcx_core:playerReady", function()
    local src = source
    local name = GetPlayerName(src) or "Unknown"
    local identifier = getIdentifier(src)

    if not identifier then
        print(("[MCX][Core] No identifier for player %d"):format(src))
        DropPlayer(src, "No valid identifier found.")
        return
    end

    Core.Players[src] = Core.Players[src] or {}
    Core.Players[src].identifier = identifier

    MCX.DB.EnsureAccount(identifier, name, function(accountRow)
        if not accountRow then
            print(("[MCX][Core] Failed to ensure account for %s (%d)"):format(identifier, src))
            return
        end

        Core.Players[src].account_id = accountRow.id

        MCX.DB.GetCharacterByIdentifier(identifier, function(charRow)
            if not charRow then
                -- No character yet -> open MCX character creator UI
                TriggerClientEvent("mcx_core:openCharacterCreator", src)
                return
            end

            sendCharacterAndSpawnMenu(src, charRow)
        end)
    end)
end)

---------------------------------------------------------------------
-- Character creation from mcx_charcreator NUI
-- data = { first_name, last_name, ped_model, skin = {} }
---------------------------------------------------------------------

RegisterNetEvent("mcx_core:createCharacter", function(data)
    local src = source
    local player = Core.Players[src]

    if not player or not player.identifier or not player.account_id then
        print(("[MCX][Core] createCharacter: missing player state for %d"):format(src))
        return
    end

    if type(data) ~= "table" then
        print(("[MCX][Core] createCharacter: invalid data from %d"):format(src))
        return
    end

    if not data.first_name or not data.last_name then
        print(("[MCX][Core] createCharacter: missing names from %d"):format(src))
        return
    end

    -- Basic sanitize
    data.first_name = tostring(data.first_name):sub(1, 32)
    data.last_name = tostring(data.last_name):sub(1, 32)
    data.ped_model = data.ped_model or "mp_m_freemode_01"
    data.skin = data.skin or {}

    MCX.DB.CreateCharacter(player.identifier, data, function(insertId)
        if not insertId then
            print(("[MCX][Core] Failed to create character for %d"):format(src))
            return
        end

        -- Reload character row so we have DB defaults
        MCX.DB.GetCharacterByIdentifier(player.identifier, function(charRow)
            if not charRow then
                print(("[MCX][Core] Failed to load character after create for %d"):format(src))
                return
            end

            sendCharacterAndSpawnMenu(src, charRow)
        end)
    end)
end)

---------------------------------------------------------------------
-- Spawn selection from NUI (mcx_charcreator)
-- data = { x, y, z, heading? }
---------------------------------------------------------------------

RegisterNetEvent("mcx_core:spawnAt", function(data)
    local src = source
    local player = Core.Players[src]
    if not player or not player.char_id then
        print(("[MCX][Core] spawnAt: missing character for %d"):format(src))
        return
    end

    if type(data) ~= "table" or not data.x or not data.y or not data.z then
        print(("[MCX][Core] spawnAt: invalid data from %d"):format(src))
        return
    end

    local location = {
        x = tonumber(data.x) or 0.0,
        y = tonumber(data.y) or 0.0,
        z = tonumber(data.z) or 0.0,
        heading = tonumber(data.heading) or 0.0
    }

    -- Store as last_location immediately so reconnects/respawns have it
    player.character = player.character or {}
    player.character.last_location = location
    MCX.DB.UpdateCharacterLocation(player.char_id, location)

    -- Spawn the player
    TriggerClientEvent("mcx_core:doSpawn", src, location)

    -- Tell client to close NUI
    TriggerClientEvent("mcx_core:closeUI", src)
end)

---------------------------------------------------------------------
-- Last location updates from client (periodic)
---------------------------------------------------------------------

RegisterNetEvent("mcx_core:updateLastLocation", function(lastLoc)
    local src = source
    local player = Core.Players[src]
    if not player or not player.char_id then return end
    if type(lastLoc) ~= "table" then return end

    player.character = player.character or {}
    player.character.last_location = lastLoc

    MCX.DB.UpdateCharacterLocation(player.char_id, lastLoc)
end)

---------------------------------------------------------------------
-- Respawn handling entry point (called by mcx_spawnmanager)
---------------------------------------------------------------------

AddEventHandler("mcx_core:handleRespawnRequest", function(src, mode)
    mode = mode or "hospital"
    local player = Core.Players[src]

    local location

    if mode == "last_location" and player and player.character and player.character.last_location then
        location = player.character.last_location
    end

    if not location then
        -- Hospital fallback
        location = {
            x = 298.0,
            y = -584.0,
            z = 43.3,
            heading = 70.0
        }
    end

    TriggerClientEvent("mcx_core:doSpawn", src, location)
end)
