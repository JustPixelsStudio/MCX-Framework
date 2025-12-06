-- mcx_gamemode/server/mcx_gamemode_sv.lua

AddEventHandler("onResourceStart", function(res)
    if res == GetCurrentResourceName() then
        SetGameType("Midnight City RP (MCX)")
        SetMapName("Midnight City")
        print("[MCX][Gamemode] Gamemode set to Midnight City RP (MCX)")
    end
end)
