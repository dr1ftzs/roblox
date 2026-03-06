local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local RoomBuilder = {}
RoomBuilder.__index = RoomBuilder

local WALL_THICKNESS = 2
local FLOOR_THICKNESS = 1
local DOOR_WIDTH = 8
local DOOR_HEIGHT = 12

local function makePart(parent, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function RoomBuilder.new(container, config)
    local self = setmetatable({}, RoomBuilder)
    self.Container = container or Workspace
    self.Config = config
    return self
end

function RoomBuilder:CreateRoom(index, center, size)
    local folder = Instance.new("Folder")
    folder.Name = string.format("Room_%d", index)
    folder.Parent = self.Container

    local half = size / 2
    local floorY = center.Y - half.Y
    local roofY = center.Y + half.Y

    makePart(folder, Vector3.new(size.X, FLOOR_THICKNESS, size.Z), CFrame.new(center.X, floorY, center.Z), Color3.fromRGB(65, 65, 70), Enum.Material.Concrete)
    makePart(folder, Vector3.new(size.X, FLOOR_THICKNESS, size.Z), CFrame.new(center.X, roofY, center.Z), Color3.fromRGB(55, 55, 60), Enum.Material.Concrete)

    makePart(folder, Vector3.new(WALL_THICKNESS, size.Y, size.Z), CFrame.new(center.X - half.X, center.Y, center.Z), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
    makePart(folder, Vector3.new(WALL_THICKNESS, size.Y, size.Z), CFrame.new(center.X + half.X, center.Y, center.Z), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)

    makePart(folder, Vector3.new(size.X, size.Y, WALL_THICKNESS), CFrame.new(center.X, center.Y, center.Z - half.Z), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)

    local wallLeftWidth = (size.X - DOOR_WIDTH) / 2
    makePart(folder, Vector3.new(wallLeftWidth, size.Y, WALL_THICKNESS), CFrame.new(center.X - (DOOR_WIDTH / 2 + wallLeftWidth / 2), center.Y, center.Z + half.Z), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
    makePart(folder, Vector3.new(wallLeftWidth, size.Y, WALL_THICKNESS), CFrame.new(center.X + (DOOR_WIDTH / 2 + wallLeftWidth / 2), center.Y, center.Z + half.Z), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
    makePart(folder, Vector3.new(DOOR_WIDTH, size.Y - DOOR_HEIGHT, WALL_THICKNESS), CFrame.new(center.X, center.Y + (DOOR_HEIGHT / 2), center.Z + half.Z), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)

    local door = makePart(folder, Vector3.new(DOOR_WIDTH, DOOR_HEIGHT, WALL_THICKNESS), CFrame.new(center.X, center.Y - (size.Y - DOOR_HEIGHT) / 2, center.Z + half.Z), Color3.fromRGB(200, 50, 50), Enum.Material.Neon)
    door.Name = "ExitDoor"

    local obstacleCount = math.min(self.Config.Layout.MinObstacleCount + (index - 1) * self.Config.Layout.ObstacleGrowthPerStage, self.Config.Layout.ObstacleMax)

    for _ = 1, obstacleCount do
        local obstacleSize = Vector3.new(math.random(4, 8), math.random(3, 8), math.random(4, 8))
        local x = center.X + math.random(-math.floor(size.X * 0.35), math.floor(size.X * 0.35))
        local z = center.Z + math.random(-math.floor(size.Z * 0.30), math.floor(size.Z * 0.30))
        if z < center.Z + half.Z - 8 and z > center.Z - half.Z + 8 then
            local obstacle = makePart(folder, obstacleSize, CFrame.new(x, floorY + obstacleSize.Y / 2, z), Color3.fromRGB(68, 87, 102), Enum.Material.Slate)
            obstacle.Name = "LayoutObstacle"
        end
    end

    local spawn = Instance.new("SpawnLocation")
    spawn.Neutral = true
    spawn.Transparency = 1
    spawn.CanCollide = false
    spawn.Size = Vector3.new(6, 1, 6)
    spawn.CFrame = CFrame.new(center.X, floorY + 1, center.Z - half.Z + 6)
    spawn.Parent = folder

    return {
        Folder = folder,
        Door = door,
        DoorClosedCFrame = door.CFrame,
        DoorOpenCFrame = door.CFrame * CFrame.new(0, DOOR_HEIGHT + 2, 0),
        Center = center,
        Size = size,
        FloorY = floorY,
    }
end

function RoomBuilder:SetDoorOpen(doorInfo, isOpen)
    if not doorInfo or not doorInfo.Door then
        return
    end

    doorInfo.Door.CanCollide = not isOpen
    doorInfo.Door.Color = isOpen and Color3.fromRGB(40, 200, 80) or Color3.fromRGB(200, 50, 50)

    local targetCFrame = isOpen and doorInfo.DoorOpenCFrame or doorInfo.DoorClosedCFrame
    local tweenInfo = TweenInfo.new(isOpen and self.Config.DoorAnimation.OpenSeconds or self.Config.DoorAnimation.CloseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(doorInfo.Door, tweenInfo, {
        CFrame = targetCFrame,
        Transparency = isOpen and 0.2 or 0,
    })
    tween:Play()
end

return RoomBuilder
