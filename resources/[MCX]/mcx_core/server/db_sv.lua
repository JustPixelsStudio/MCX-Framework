MCX = MCX or {}
MCX.DB = MCX.DB or {}

function MCX.DB.EnsureAccount(identifier, name, cb)
    MySQL.query('SELECT * FROM mcx_players WHERE identifier = ?', { identifier }, function(result)
        local row = result[1]
        if row then
            MySQL.update(
                'UPDATE mcx_players SET last_seen_name = ?, last_login = CURRENT_TIMESTAMP WHERE identifier = ?',
                { name, identifier }
            )
            cb(row)
        else
            MySQL.insert(
                'INSERT INTO mcx_players (identifier, last_seen_name, last_login) VALUES (?, ?, CURRENT_TIMESTAMP)',
                { identifier, name },
                function(insertId)
                    cb({
                        id = insertId,
                        identifier = identifier,
                        last_seen_name = name
                    })
                end
            )
        end
    end)
end

function MCX.DB.GetCharacterByIdentifier(identifier, cb)
    MySQL.query('SELECT * FROM mcx_characters WHERE identifier = ?', { identifier }, function(result)
        cb(result[1])
    end)
end

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
            cb(insertId)
        end
    )
end

function MCX.DB.SaveCharacter(charId, data)
    MySQL.update(
        [[
        UPDATE mcx_characters
        SET cash = ?, bank = ?, xp = ?, level = ?, hunger = ?, thirst = ?, skin = ?, last_location = ?
        WHERE char_id = ?
        ]],
        {
            data.cash,
            data.bank,
            data.xp,
            data.level,
            data.hunger,
            data.thirst,
            json.encode(data.skin or {}),
            json.encode(data.last_location or nil),
            charId
        }
    )
end
