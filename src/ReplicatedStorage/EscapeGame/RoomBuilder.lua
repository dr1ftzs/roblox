local Config = require(script.Parent.Config)

local RoomBuilder = {}
RoomBuilder.__index = RoomBuilder

local function randomFromRange(rangeObj)
	if typeof(rangeObj) == "NumberRange" then
		return rangeObj.Min + math.random() * (rangeObj.Max - rangeObj.Min)
	end
	return rangeObj
end

local function chooseColor(palette)
	return palette[math.random(1, #palette)]
end

local function chooseCount(config)
	return math.random(config.Min, config.Max)
end

local function makePart(name, parent, size, cframe, material, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = material
	part.Color = color
	part.Parent = parent
	return part
end

local function applyTexture(part, textureAssetId, face)
	if textureAssetId == nil or textureAssetId == "" then
		return
	end

	local texture = Instance.new("Texture")
	texture.Texture = textureAssetId
	texture.StudsPerTileU = 4
	texture.StudsPerTileV = 4
	texture.Face = face or Enum.NormalId.Top
	texture.Parent = part
end

local function pointInsideRect(point, rect)
	return point.X >= rect.MinX and point.X <= rect.MaxX and point.Z >= rect.MinZ and point.Z <= rect.MaxZ
end

local function makeWardrobe(parent, position, size, color)
	local model = Instance.new("Model")
	model.Name = "Wardrobe"
	model.Parent = parent

	local body = makePart(
		"Body",
		model,
		size,
		CFrame.new(position.X, size.Y * 0.5, position.Z),
		Enum.Material.WoodPlanks,
		color
	)

	local doorThickness = 0.2
	local leftDoor = makePart(
		"DoorLeft",
		model,
		Vector3.new((size.X * 0.5) - 0.05, size.Y - 0.2, doorThickness),
		body.CFrame * CFrame.new(-size.X * 0.25, 0, (size.Z * 0.5) + (doorThickness * 0.5)),
		Enum.Material.Wood,
		color:lerp(Color3.new(0, 0, 0), 0.1)
	)
	leftDoor.CanCollide = false

	local rightDoor = leftDoor:Clone()
	rightDoor.Name = "DoorRight"
	rightDoor.CFrame = body.CFrame * CFrame.new(size.X * 0.25, 0, (size.Z * 0.5) + (doorThickness * 0.5))
	rightDoor.Parent = model

	return model
end

local function makeTable(parent, position, size, color)
	local model = Instance.new("Model")
	model.Name = "SideTable"
	model.Parent = parent

	local top = makePart(
		"Top",
		model,
		Vector3.new(size.X, 0.35, size.Z),
		CFrame.new(position.X, size.Y - 0.2, position.Z),
		Enum.Material.Wood,
		color
	)

	for _, offset in ipairs({
		Vector3.new(size.X * 0.4, size.Y * 0.5, size.Z * 0.4),
		Vector3.new(-size.X * 0.4, size.Y * 0.5, size.Z * 0.4),
		Vector3.new(size.X * 0.4, size.Y * 0.5, -size.Z * 0.4),
		Vector3.new(-size.X * 0.4, size.Y * 0.5, -size.Z * 0.4),
	}) do
		makePart(
			"Leg",
			model,
			Vector3.new(0.3, size.Y - 0.4, 0.3),
			CFrame.new(position + Vector3.new(offset.X, (size.Y - 0.4) * 0.5, offset.Z)),
			Enum.Material.Wood,
			color:lerp(Color3.new(0, 0, 0), 0.2)
		)
	end

	top.CanCollide = true
	return model
end

local function makePillar(parent, position, size, color)
	local pillar = makePart(
		"Pillar",
		parent,
		size,
		CFrame.new(position.X, size.Y * 0.5, position.Z),
		Enum.Material.Wood,
		color:lerp(Color3.new(0, 0, 0), 0.15)
	)
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Orientation = Vector3.new(0, 0, 90)
	return pillar
end

local function canPlace(position, halfSize, laneRect, exitRect)
	local corners = {
		Vector3.new(position.X - halfSize.X, 0, position.Z - halfSize.Z),
		Vector3.new(position.X + halfSize.X, 0, position.Z + halfSize.Z),
		Vector3.new(position.X - halfSize.X, 0, position.Z + halfSize.Z),
		Vector3.new(position.X + halfSize.X, 0, position.Z - halfSize.Z),
	}

	for _, c in ipairs(corners) do
		if pointInsideRect(c, laneRect) or pointInsideRect(c, exitRect) then
			return false
		end
	end
	return true
end

local function resolveConfig(configOverride)
	if typeof(configOverride) == "table" then
		return configOverride
	end
	return Config
end

local function addDoorFrame(room, doorHalfGap, doorHeight, halfL, trimColor, atBack)
	local zSign = atBack and -1 or 1
	local frameDepth = 0.4
	local zPos = (halfL - frameDepth * 0.5) * zSign

	makePart("DoorFrameLeft" .. (atBack and "Back" or "Front"), room, Vector3.new(0.7, doorHeight + 0.6, frameDepth), CFrame.new(-(doorHalfGap + 0.35), (doorHeight + 0.6) * 0.5, zPos), Enum.Material.Wood, trimColor)
	makePart("DoorFrameRight" .. (atBack and "Back" or "Front"), room, Vector3.new(0.7, doorHeight + 0.6, frameDepth), CFrame.new((doorHalfGap + 0.35), (doorHeight + 0.6) * 0.5, zPos), Enum.Material.Wood, trimColor)
	makePart("DoorFrameTop" .. (atBack and "Back" or "Front"), room, Vector3.new((doorHalfGap * 2) + 1.4, 0.7, frameDepth), CFrame.new(0, doorHeight + 0.3, zPos), Enum.Material.Wood, trimColor)
end

local function createRoomModel(stageNumber, configOverride)
	stageNumber = stageNumber or 1

	local room = Instance.new("Model")
	room.Name = string.format("StageRoom_%d", stageNumber)

	local activeConfig = resolveConfig(configOverride)
	local roomCfg = activeConfig.Room
	local style = activeConfig.VisualStyle

	local halfW = roomCfg.Width * 0.5
	local halfL = roomCfg.Length * 0.5
	local h = roomCfg.Height
	local t = roomCfg.WallThickness
	local doorHalfGap = roomCfg.DoorWidth * 0.5

	local wallColor = chooseColor(style.WoodPalette.Wall)
	local floorColor = chooseColor(style.WoodPalette.Floor)
	local trimColor = chooseColor(style.WoodPalette.Trim)

	local floor = makePart("Floor", room, Vector3.new(roomCfg.Width, 1, roomCfg.Length), CFrame.new(0, 0, 0), Enum.Material.WoodPlanks, floorColor)
	applyTexture(floor, style.Textures.Floor, Enum.NormalId.Top)

	local ceiling = makePart("Ceiling", room, Vector3.new(roomCfg.Width, 1, roomCfg.Length), CFrame.new(0, h, 0), Enum.Material.Wood, wallColor:lerp(Color3.new(1, 1, 1), 0.08))
	applyTexture(ceiling, style.Textures.Ceiling, Enum.NormalId.Bottom)

	makePart("WallLeft", room, Vector3.new(t, h, roomCfg.Length), CFrame.new(-halfW, h * 0.5, 0), Enum.Material.Wood, wallColor)
	makePart("WallRight", room, Vector3.new(t, h, roomCfg.Length), CFrame.new(halfW, h * 0.5, 0), Enum.Material.Wood, wallColor)

	-- Both front and back have a doorway, so halls can connect rooms seamlessly.
	local sideWidth = (roomCfg.Width - roomCfg.DoorWidth) * 0.5
	local sideOffset = doorHalfGap + (sideWidth * 0.5)

	makePart("WallFrontLeft", room, Vector3.new(sideWidth, h, t), CFrame.new(-sideOffset, h * 0.5, halfL), Enum.Material.Wood, wallColor)
	makePart("WallFrontRight", room, Vector3.new(sideWidth, h, t), CFrame.new(sideOffset, h * 0.5, halfL), Enum.Material.Wood, wallColor)
	makePart("WallFrontHeader", room, Vector3.new(roomCfg.DoorWidth, h - roomCfg.DoorHeight, t), CFrame.new(0, roomCfg.DoorHeight + ((h - roomCfg.DoorHeight) * 0.5), halfL), Enum.Material.Wood, wallColor)

	makePart("WallBackLeft", room, Vector3.new(sideWidth, h, t), CFrame.new(-sideOffset, h * 0.5, -halfL), Enum.Material.Wood, wallColor)
	makePart("WallBackRight", room, Vector3.new(sideWidth, h, t), CFrame.new(sideOffset, h * 0.5, -halfL), Enum.Material.Wood, wallColor)
	makePart("WallBackHeader", room, Vector3.new(roomCfg.DoorWidth, h - roomCfg.DoorHeight, t), CFrame.new(0, roomCfg.DoorHeight + ((h - roomCfg.DoorHeight) * 0.5), -halfL), Enum.Material.Wood, wallColor)

	local exitTrigger = makePart("ExitTrigger", room, Vector3.new(roomCfg.DoorWidth - 0.2, roomCfg.DoorHeight, 1.5), CFrame.new(0, roomCfg.DoorHeight * 0.5, halfL - 0.3), Enum.Material.ForceField, Color3.fromRGB(100, 180, 255))
	exitTrigger.Transparency = 1
	exitTrigger.CanCollide = false

	for _, wallName in ipairs({ "WallLeft", "WallRight", "WallFrontLeft", "WallFrontRight", "WallBackLeft", "WallBackRight" }) do
		local wall = room:FindFirstChild(wallName)
		if wall then
			applyTexture(wall, style.Textures.Walls, Enum.NormalId.Front)
		end
	end

	local baseboardHeight = 0.7
	makePart("TrimLeft", room, Vector3.new(0.5, baseboardHeight, roomCfg.Length - 0.6), CFrame.new(-(halfW - 0.25), baseboardHeight * 0.5, 0), Enum.Material.Wood, trimColor)
	makePart("TrimRight", room, Vector3.new(0.5, baseboardHeight, roomCfg.Length - 0.6), CFrame.new((halfW - 0.25), baseboardHeight * 0.5, 0), Enum.Material.Wood, trimColor)
	makePart("TrimFrontLeft", room, Vector3.new(sideWidth - 0.3, baseboardHeight, 0.5), CFrame.new(-sideOffset, baseboardHeight * 0.5, halfL - 0.25), Enum.Material.Wood, trimColor)
	makePart("TrimFrontRight", room, Vector3.new(sideWidth - 0.3, baseboardHeight, 0.5), CFrame.new(sideOffset, baseboardHeight * 0.5, halfL - 0.25), Enum.Material.Wood, trimColor)
	makePart("TrimBackLeft", room, Vector3.new(sideWidth - 0.3, baseboardHeight, 0.5), CFrame.new(-sideOffset, baseboardHeight * 0.5, -halfL + 0.25), Enum.Material.Wood, trimColor)
	makePart("TrimBackRight", room, Vector3.new(sideWidth - 0.3, baseboardHeight, 0.5), CFrame.new(sideOffset, baseboardHeight * 0.5, -halfL + 0.25), Enum.Material.Wood, trimColor)

	for _, xSign in ipairs({ -1, 1 }) do
		for _, zSign in ipairs({ -1, 1 }) do
			makePart("CornerTrim", room, Vector3.new(0.5, h, 0.5), CFrame.new((halfW - 0.25) * xSign, h * 0.5, (halfL - 0.25) * zSign), Enum.Material.Wood, trimColor)
		end
	end

	local chandelier = makePart("Chandelier", room, Vector3.new(2.2, 0.6, 2.2), CFrame.new(0, h - 1.5, 0), Enum.Material.Metal, Color3.fromRGB(88, 73, 55))
	chandelier.Shape = Enum.PartType.Cylinder
	local chain = makePart("ChandelierChain", room, Vector3.new(0.2, 1.8, 0.2), CFrame.new(0, h - 0.6, 0), Enum.Material.Metal, Color3.fromRGB(60, 56, 52))
	chain.CanCollide = false

	local primaryLight = Instance.new("PointLight")
	primaryLight.Color = style.Lighting.Color
	primaryLight.Brightness = randomFromRange(style.Lighting.BrightnessRange)
	primaryLight.Range = randomFromRange(style.Lighting.ChandelierRange)
	primaryLight.Shadows = true
	primaryLight.Parent = chandelier

	for _, xSign in ipairs({ -1, 1 }) do
		for _, zSign in ipairs({ -1, 1 }) do
			local sconce = makePart("WallSconce", room, Vector3.new(0.7, 1.2, 0.7), CFrame.new((halfW - 0.35) * xSign, h * 0.55, (halfL - 5) * zSign), Enum.Material.Metal, Color3.fromRGB(95, 80, 58))
			sconce.CanCollide = false

			local sconceLight = Instance.new("PointLight")
			sconceLight.Color = style.Lighting.Color
			sconceLight.Brightness = randomFromRange(style.Lighting.BrightnessRange) * 0.65
			sconceLight.Range = randomFromRange(style.Lighting.SconceRange)
			sconceLight.Parent = sconce
		end
	end

	addDoorFrame(room, doorHalfGap, roomCfg.DoorHeight, halfL, trimColor, false)
	addDoorFrame(room, doorHalfGap, roomCfg.DoorHeight, halfL, trimColor, true)

	local plaque = makePart("DoorNumberPlaque", room, Vector3.new(2.4, 1.2, 0.2), CFrame.new(0, roomCfg.DoorHeight + 1.4, halfL - 0.35), Enum.Material.Wood, trimColor:lerp(Color3.new(1, 1, 1), 0.08))
	plaque.CanCollide = false

	local plaqueGui = Instance.new("SurfaceGui")
	plaqueGui.Face = Enum.NormalId.Front
	plaqueGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	plaqueGui.PixelsPerStud = 64
	plaqueGui.LightInfluence = 0
	plaqueGui.Parent = plaque

	local stageText = Instance.new("TextLabel")
	stageText.Size = UDim2.fromScale(1, 1)
	stageText.BackgroundTransparency = 1
	stageText.Text = string.format("%02d", stageNumber)
	stageText.TextColor3 = Color3.fromRGB(255, 232, 186)
	stageText.TextScaled = true
	stageText.Font = Enum.Font.Garamond
	stageText.Parent = plaqueGui

	local propsFolder = Instance.new("Folder")
	propsFolder.Name = "Props"
	propsFolder.Parent = room

	local laneRect = {
		MinX = -roomCfg.CorridorHalfWidth,
		MaxX = roomCfg.CorridorHalfWidth,
		MinZ = -halfL,
		MaxZ = halfL,
	}
	local exitRect = {
		MinX = -(roomCfg.DoorWidth * 0.5) - 1,
		MaxX = (roomCfg.DoorWidth * 0.5) + 1,
		MinZ = halfL - 4,
		MaxZ = halfL + 1,
	}
	local spawnSafeRect = {
		MinX = -halfW,
		MaxX = halfW,
		MinZ = -halfL,
		MaxZ = -halfL + roomCfg.SpawnSafeDepth,
	}

	local function randomSidePosition(wallInset)
		local side = (math.random() > 0.5) and 1 or -1
		local x = side * (halfW - wallInset)
		local z = math.random(-halfL + 5, halfL - 8)
		return Vector3.new(x, 0, z)
	end

	local function tryPlace(setup, constructor, propName)
		local targetCount = chooseCount(setup)
		local placed = 0
		local attempts = 0
		while placed < targetCount and attempts < targetCount * 12 do
			attempts += 1
			local pos = randomSidePosition(setup.WallInset)
			local halfSize = setup.Size * 0.5
			local point = Vector3.new(pos.X, 0, pos.Z)

			if not pointInsideRect(point, spawnSafeRect) and canPlace(pos, halfSize, laneRect, exitRect) then
				constructor(propsFolder, pos, setup.Size, trimColor)
				placed += 1
			end
		end

		if placed < targetCount then
			warn(string.format("Placed %d/%d %s props in stage %d", placed, targetCount, propName, stageNumber))
		end
	end

	tryPlace(style.PropSpawns.Wardrobes, makeWardrobe, "wardrobe")
	tryPlace(style.PropSpawns.Tables, makeTable, "table")
	tryPlace(style.PropSpawns.Pillars, makePillar, "pillar")

	return room
end

local function createHallModel(index, configOverride)
	local activeConfig = resolveConfig(configOverride)
	local hallCfg = activeConfig.Hallway
	local style = activeConfig.VisualStyle

	local hall = Instance.new("Model")
	hall.Name = string.format("StageHall_%d", index)

	local halfW = hallCfg.Width * 0.5
	local halfL = hallCfg.Length * 0.5
	local h = hallCfg.Height
	local t = hallCfg.WallThickness

	local wallColor = chooseColor(style.WoodPalette.Wall)
	local floorColor = chooseColor(style.WoodPalette.Floor)
	local trimColor = chooseColor(style.WoodPalette.Trim)

	makePart("Floor", hall, Vector3.new(hallCfg.Width, 1, hallCfg.Length), CFrame.new(0, 0, 0), Enum.Material.WoodPlanks, floorColor)
	makePart("Ceiling", hall, Vector3.new(hallCfg.Width, 1, hallCfg.Length), CFrame.new(0, h, 0), Enum.Material.Wood, wallColor)
	makePart("WallLeft", hall, Vector3.new(t, h, hallCfg.Length), CFrame.new(-halfW, h * 0.5, 0), Enum.Material.Wood, wallColor)
	makePart("WallRight", hall, Vector3.new(t, h, hallCfg.Length), CFrame.new(halfW, h * 0.5, 0), Enum.Material.Wood, wallColor)
	makePart("TrimLeft", hall, Vector3.new(0.5, 0.7, hallCfg.Length), CFrame.new(-(halfW - 0.25), 0.35, 0), Enum.Material.Wood, trimColor)
	makePart("TrimRight", hall, Vector3.new(0.5, 0.7, hallCfg.Length), CFrame.new((halfW - 0.25), 0.35, 0), Enum.Material.Wood, trimColor)

	local lamp = makePart("HallLamp", hall, Vector3.new(1.2, 0.4, 1.2), CFrame.new(0, h - 1, 0), Enum.Material.Metal, Color3.fromRGB(88, 73, 55))
	local light = Instance.new("PointLight")
	light.Color = style.Lighting.Color
	light.Brightness = randomFromRange(style.Lighting.BrightnessRange) * 0.55
	light.Range = math.max(8, hallCfg.Length * 0.8)
	light.Parent = lamp

	return hall
end

function RoomBuilder.CreateRoom(stageOrSelf, configOrStage, maybeConfig)
	local runtimeFolder
	local stageNumber
	local configOverride

	if type(stageOrSelf) == "table" and getmetatable(stageOrSelf) == RoomBuilder then
		runtimeFolder = stageOrSelf.RuntimeFolder
		stageNumber = configOrStage
		configOverride = stageOrSelf.Config
	else
		stageNumber = stageOrSelf
		configOverride = configOrStage
	end

	if maybeConfig ~= nil then
		configOverride = maybeConfig
	end

	local room = createRoomModel(stageNumber, configOverride)
	if runtimeFolder then
		room.Parent = runtimeFolder
	end
	return room
end

function RoomBuilder.CreateHall(index, configOverride)
	return createHallModel(index, configOverride)
end

function RoomBuilder.new(runtimeFolder, configOverride)
	local self = setmetatable({}, RoomBuilder)
	self.RuntimeFolder = runtimeFolder
	self.Config = resolveConfig(configOverride)
	return self
end

function RoomBuilder.BuildRoom(self, stageNumber)
	return RoomBuilder.CreateRoom(self, stageNumber)
end

function RoomBuilder.Build(self, stageNumber)
	return RoomBuilder.CreateRoom(self, stageNumber)
end

function RoomBuilder:BuildRun(stageCount)
	local targetParent = self.RuntimeFolder or workspace
	local activeConfig = self.Config
	local roomCfg = activeConfig.Room
	local hallCfg = activeConfig.Hallway

	stageCount = stageCount or activeConfig.Defaults.InitialStageCount
	local spacing = roomCfg.Length + hallCfg.Length
	local path = Instance.new("Model")
	path.Name = "EscapePath"
	path.Parent = targetParent

	for stage = 1, stageCount do
		local room = createRoomModel(stage, activeConfig)
		room:PivotTo(CFrame.new(0, 0, (stage - 1) * spacing))
		room.Parent = path

		if stage < stageCount then
			local hall = createHallModel(stage, activeConfig)
			hall:PivotTo(CFrame.new(0, 0, ((stage - 1) * spacing) + (roomCfg.Length * 0.5) + (hallCfg.Length * 0.5)))
			hall.Parent = path
		end
	end

	local spawn = targetParent:FindFirstChild("EscapeSpawn")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "EscapeSpawn"
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Parent = targetParent
	end
	spawn.CFrame = CFrame.new(0, 0.5, -(roomCfg.Length * 0.5) + 6)

	return path
end

return RoomBuilder
