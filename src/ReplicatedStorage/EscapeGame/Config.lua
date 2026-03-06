local Config = {
    SpawnPosition = Vector3.new(0, 5, 0),
    RoomBaseSize = Vector3.new(32, 18, 32),
    RoomGrowthPerStage = Vector3.new(6, 1, 6),
    CorridorGap = 16,

    Modes = {
        Timed = "Timed",
        Endless = "Endless",
    },

    Timed = {
        StartSeconds = 45,
        BonusPerClear = 8,
        MaxSeconds = 75,
    },

    PuzzleScale = {
        ButtonHoldSeconds = 1.5,
        SequenceLengthStart = 3,
        SequenceLengthGrowth = 1,
        SequenceButtonCount = 4,
        SequenceResetDelay = 2,
        MazeGridBase = 5,
        TimedDoorWindow = 5,
        FakeButtonCount = 5,
    },

    Layout = {
        MinObstacleCount = 2,
        ObstacleGrowthPerStage = 1,
        ObstacleMax = 14,
    },

    DoorAnimation = {
        OpenSeconds = 0.5,
        CloseSeconds = 0.35,
    },

    Monetization = {
        Enabled = true,

        Products = {
            SkipRoom = {
                ProductId = 0,
                BonusTimeOnSkip = 0,
            },
            TimeBoost = {
                ProductId = 0,
                SecondsGranted = 30,
            },
        },
    },
}

return Config
