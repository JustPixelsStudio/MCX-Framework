-- mcx_map/client/mcx_map_cl.lua

CreateThread(function()
    -- Basic population tuning – tweak for performance / RP feel
    while true do
        SetVehicleDensityMultiplierThisFrame(0.8)
        SetPedDensityMultiplierThisFrame(0.8)
        SetRandomVehicleDensityMultiplierThisFrame(0.8)
        SetScenarioPedDensityMultiplierThisFrame(0.8, 0.8)
        Wait(0)
    end
end)
