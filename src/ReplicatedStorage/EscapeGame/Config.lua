local Config = {}

Config.Modes = {
	Timed = "Timed",
	Endless = "Endless",
}

Config.Defaults = {
	EscapeMode = Config.Modes.Timed,
	InitialStageCount = 5,
}

Config.Room = {
	Width = 44,
	Length = 52,
	Height = 18,
	WallThickness = 1,
	DoorWidth = 8,
	DoorHeight = 12,
	CorridorHalfWidth = 4,
	SpawnSafeDepth = 16,
}

Config.Hallway = {
	Length = 16,
	Width = 10,
	Height = 14,
	WallThickness = 1,
}

Config.VisualStyle = {
	-- "Inspired by" style knobs for warm, moody wood interiors.
	WoodPalette = {
		Wall = {
			Color3.fromRGB(112, 79, 58),
			Color3.fromRGB(126, 89, 66),
			Color3.fromRGB(101, 70, 51),
		},
		Floor = {
			Color3.fromRGB(86, 61, 45),
			Color3.fromRGB(94, 66, 49),
			Color3.fromRGB(77, 54, 40),
		},
		Trim = {
			Color3.fromRGB(65, 45, 34),
			Color3.fromRGB(73, 50, 36),
			Color3.fromRGB(59, 41, 31),
		},
	},

	Lighting = {
		Color = Color3.fromRGB(255, 222, 175),
		BrightnessRange = NumberRange.new(1.8, 2.7),
		ChandelierRange = NumberRange.new(14, 20),
		SconceRange = NumberRange.new(8, 12),
	},

	PropSpawns = {
		Wardrobes = {
			Min = 1,
			Max = 2,
			Size = Vector3.new(5, 11, 2.5),
			WallInset = 1.2,
		},
		Tables = {
			Min = 1,
			Max = 3,
			Size = Vector3.new(3.8, 2.7, 2.4),
			WallInset = 2,
		},
		Pillars = {
			Min = 0,
			Max = 2,
			Size = Vector3.new(2.2, 8, 2.2),
			WallInset = 2.5,
		},
	},

	Textures = {
		Floor = "",
		Walls = "",
		Ceiling = "",
	},
}

return Config
