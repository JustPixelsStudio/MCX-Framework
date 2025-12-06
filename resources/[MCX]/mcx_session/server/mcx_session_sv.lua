-- mcx_session/server/mcx_session_sv.lua

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    print(("[MCX][Session] %s is connecting..."):format(name))
    -- Future: deferrals for whitelist, queue, checks, etc.
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    print(("[MCX][Session] Player %d dropped (%s)"):format(src, reason or "unknown"))
    -- Future: you can trigger a save or cleanup here if needed.
end)
