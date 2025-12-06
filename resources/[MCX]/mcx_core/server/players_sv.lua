MCX = MCX or {}
MCX.Players = MCX.Players or {}

function MCX.CreatePlayer(source, charRow)
    local self = {}

    self.source = source
    self.char_id = charRow.char_id
    self.identifier = charRow.identifier

    self.first_name = charRow.first_name
    self.last_name = charRow.last_name
    self.ped_model = charRow.ped_model or 'mp_m_freemode_01'
    self.gender = charRow.gender or nil
    self.skin = charRow.skin and json.decode(charRow.skin) or {}

    self.cash = charRow.cash or 0
    self.bank = charRow.bank or 0
    self.xp = charRow.xp or 0
    self.level = charRow.level or 1

    self.hunger = charRow.hunger or 100
    self.thirst = charRow.thirst or 100

    self.last_location = charRow.last_location and json.decode(charRow.last_location) or nil

    function self:GetFullName()
        return (self.first_name or "") .. " " .. (self.last_name or "")
    end

    function self:AddXP(amount)
        self.xp = self.xp + amount
        local leveled = false
        while self.xp >= MCX.Utils.GetXPForLevel(self.level + 1) do
            self.level = self.level + 1
            leveled = true
        end
        if leveled then
            TriggerClientEvent("mcx_core:levelUp", self.source, self.level)
        end
    end

    function self:SetLastLocation(coords)
        self.last_location = coords
    end

    function self:Save()
        MCX.DB.SaveCharacter(self.char_id, self)
    end

    MCX.Players[source] = self
    return self
end

function MCX.GetPlayer(src)
    return MCX.Players[src]
end
