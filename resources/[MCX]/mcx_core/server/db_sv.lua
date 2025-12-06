-- mcx_core/db_sv.lua

MCX = MCX or {}
MCX.DB = MCX.DB or {}

---------------------------------------------------------------------
-- EnsureAccount
---------------------------------------------------------------------

function MCX.DB.EnsureAccount(identifier, name, cb)
    MySQL.query('SELECT * FROM mcx_players WHERE identifier = ?', { identifier }, function(result)
        if not result then
            print("[MCX][DB] EnsureAccount: query returned nil result")
            if cb then cb(nil) end
            return
        end

        local row = result[1]

        if row then
            MySQL.update(
                'UPDATE mcx_players SET last_seen_name = ?, last_login = CURRENT_TIMESTAMP WHERE identifier = ?',
                { name, identifier }
            )

            if cb then
                cb(row)
            end
        else
            MySQL.insert(
                'INSERT INTO mcx_players (identifier, last_seen_name, last_login) VALUES (?, ?, CURRENT_TIMESTAMP)',
                { identifier, name },
                function(insertId)
                    if not insertId then
                        print("[MCX][DB] Failed to insert mcx_players row")
                        if cb then cb(nil) end
                        return
                    end

                    if cb then
                        cb({
                            id = insertId,
                            identifier = identifier,
                            last_seen_name = name
                        })
                    end
                end
            )
        end
    end)
end

---------------------------------------------------------------------
-- GetCharacterByIdentifier
---------------------------------------------------------------------

function MCX.DB.GetCharacterByIdentifier(identifier, cb)
    MySQL.query('SELECT * FROM mcx_characters WHERE identifier = ?', { identifier }, function(result)
        if not result then
            print("[MCX][DB] GetCharacterByIdentifier: query returned nil result")
            if cb then cb(nil) end
            return
        end

        if cb then
            cb(result[1])
        end
    end)
end

---------------------------------------------------------------------
-- CreateCharacter
---------------------------------------------------------------------

function MCX.DB.CreateCharacter(identifier, data, cb)
    MySQL.insert(
        [[
        INSERT INTO mcx_characters
        (identifier, first_name, last_name, ped_model, skin, cash, bank, xp, level, hunger, thirst)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]],
        {
            identifier,
            data.first_name,
            data.last_name,
            data.ped_model or 'mp_m_freemode_01',
            json.encode(data.skin or {}),
            data.cash or 500,
            data.bank or 2000,
            data.xp or 0,
            data.level or 1,
            data.hunger or 100,
            data.thirst or 100
        },
        function(insertId)
            if not insertId then
                print("[MCX][DB] Failed to insert mcx_characters row")
            end

            if cb then
                cb(insertId)
            end
        end
    )
end

---------------------------------------------------------------------
-- SaveCharacter
---------------------------------------------------------------------

function MCX.DB.SaveCharacter(charId, data)
    if not charId then
        print("[MCX][DB] SaveCharacter called without charId")
        return
    end

    MySQL.update(
        [[
        UPDATE mcx_characters
        SET cash = ?, bank = ?, xp = ?, level = ?, hunger = ?, thirst = ?, skin = ?, last_location = ?
        WHERE char_id = ?
        ]],
        {
            data.cash or 0,
            data.bank or 0,
            data.xp or 0,
            data.level or 1,
            data.hunger or 0,
            data.thirst or 0,
            json.encode(data.skin or {}),
            json.encode(data.last_location or nil),
            charId
        }
    )
end

---------------------------------------------------------------------
-- UpdateCharacterLocation (lightweight, used for periodic last_location)
---------------------------------------------------------------------

function MCX.DB.UpdateCharacterLocation(charId, last_location)
    if not charId then
        print("[MCX][DB] UpdateCharacterLocation called without charId")
        return
    end

    MySQL.update(
        'UPDATE mcx_characters SET last_location = ? WHERE char_id = ?',
        {
            json.encode(last_location or nil),
            charId
        }
    )
end
