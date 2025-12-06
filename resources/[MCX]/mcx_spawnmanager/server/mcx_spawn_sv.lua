-- mcx_spawnmanager/server/mcx_spawn_sv.lua

---------------------------------------------------------------------
-- RESPawn request from client
-- mode: "last_location" | "hospital" | future modes
-- We forward this to mcx_core, which has DB access and character state.
---------------------------------------------------------------------
RegisterNetEvent("mcx_spawn:requestRespawn", function(mode)
    local src = source
    mode = mode or "hospital"

    -- Let MCX core handle figuring out last_location vs hospital
    TriggerEvent("mcx_core:handleRespawnRequest", src, mode)
end)
