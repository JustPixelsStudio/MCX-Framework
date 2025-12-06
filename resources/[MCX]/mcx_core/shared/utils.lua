MCX = MCX or {}
MCX.Utils = MCX.Utils or {}

function MCX.Utils.GetIdentifier(src)
    local idType = MCX.Config.IdentifierType
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, #idType + 1) == idType .. ":" then
            return id
        end
    end
    return nil
end

function MCX.Utils.GetXPForLevel(level)
    local base = MCX.Config.Leveling.BaseXP
    local mult = MCX.Config.Leveling.Multiplier
    return math.floor(base * (mult ^ (level - 1)))
end
