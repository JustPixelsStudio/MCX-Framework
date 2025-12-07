MCX = MCX or {}
MCX.DeathConfig = MCX.DeathConfig or {}

MCX.DeathConfig.BleedoutTime = 180          -- seconds before respawn is allowed
MCX.DeathConfig.RespawnFee   = 500          -- dollars to respawn at hospital
MCX.DeathConfig.ReviveItem   = "medkit"     -- placeholder until inventory exists

-- Control indices (see https://docs.fivem.net/docs/game-references/controls/)
MCX.DeathConfig.ReviveKey    = 38           -- E
MCX.DeathConfig.DragKey      = 47           -- G
MCX.DeathConfig.RespawnKey   = 38           -- E
