CreateThread(function()
    while not NetworkIsSessionActive() do
        Wait(0)
    end
    ShutdownLoadingScreenNui()
end)