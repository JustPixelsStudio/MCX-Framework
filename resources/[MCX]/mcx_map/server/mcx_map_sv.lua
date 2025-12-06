-- mcx_map/server/mcx_map_sv.lua

local defaultSpawns = {
    {
        id = "airport",
        label = "LSIA",
        x = -1037.0, y = -2737.0, z = 20.0, heading = 330.0
    },
    {
        id = "city_center",
        label = "City Center",
        x = 215.76, y = -810.12, z = 30.73, heading = 160.0
    },
    {
        id = "sandy",
        label = "Sandy Shores",
        x = 1953.54, y = 3856.17, z = 32.0, heading = 120.0
    }
}

-- Export so other resources (spawn selectors, etc.) can use them
exports("GetDefaultSpawns", function()
    return defaultSpawns
end)

AddEventHandler("onResourceStart", function(res)
    if res == GetCurrentResourceName() then
        print("[MCX][Map] mcx_map started. Default spawn points loaded.")
    end
end)
