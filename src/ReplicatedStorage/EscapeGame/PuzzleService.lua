local TweenService = game:GetService("TweenService")

local PuzzleService = {}
PuzzleService.__index = PuzzleService

local BUTTON_SIZE = Vector3.new(4, 1, 4)

local function createPrompt(parent, actionText)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = actionText
    prompt.ObjectText = "Puzzle"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent
    return prompt
end

local function createButton(parent, position, color)
    local button = Instance.new("Part")
    button.Name = "PuzzleButton"
    button.Size = BUTTON_SIZE
    button.Anchored = true
    button.Material = Enum.Material.Neon
    button.Color = color
    button.CFrame = CFrame.new(position)
    button.Parent = parent

    local pressTween = TweenService:Create(button, TweenInfo.new(0.15), {Size = Vector3.new(4, 0.45, 4)})
    local releaseTween = TweenService:Create(button, TweenInfo.new(0.2), {Size = BUTTON_SIZE})

    return button, pressTween, releaseTween
end

function PuzzleService.new(config)
    local self = setmetatable({}, PuzzleService)
    self.Config = config
    self.Connections = {}
    self.ActiveParts = {}
    return self
end

function PuzzleService:Clear()
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}

    for _, part in ipairs(self.ActiveParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    self.ActiveParts = {}
end

function PuzzleService:CreatePuzzleForRoom(roomInfo, stage, onSolved)
    self:Clear()

    if stage == 1 then
        onSolved()
        return
    end

    if stage == 2 then
        self:CreateHoldButtonPuzzle(roomInfo, onSolved)
        return
    end

    local puzzleIndex = ((stage - 3) % 4) + 1
    if puzzleIndex == 1 then
        self:CreateSequencePuzzle(roomInfo, stage, onSolved)
    elseif puzzleIndex == 2 then
        self:CreateFakeButtonsPuzzle(roomInfo, stage, onSolved)
    elseif puzzleIndex == 3 then
        self:CreateTimedDoorPuzzle(roomInfo, stage, onSolved)
    else
        self:CreateMazePuzzle(roomInfo, stage, onSolved)
    end
end

function PuzzleService:CreateHoldButtonPuzzle(roomInfo, onSolved)
    local holdSeconds = self.Config.PuzzleScale.ButtonHoldSeconds
    local buttonPosition = roomInfo.Center + Vector3.new(0, -roomInfo.Size.Y / 2 + 1, -roomInfo.Size.Z / 2 + 10)

    local button, pressTween, releaseTween = createButton(roomInfo.Folder, buttonPosition, Color3.fromRGB(255, 192, 58))
    local prompt = createPrompt(button, string.format("Hold %.1fs", holdSeconds))

    table.insert(self.ActiveParts, button)

    local elapsed = 0
    local connection = prompt.Triggered:Connect(function(player)
        if not player then
            return
        end

        elapsed += 0.5
        pressTween:Play()
        task.delay(0.2, function()
            releaseTween:Play()
        end)

        if elapsed >= holdSeconds then
            prompt.Enabled = false
            button.Color = Color3.fromRGB(40, 220, 40)
            onSolved()
        end
    end)

    table.insert(self.Connections, connection)
end

function PuzzleService:CreateSequencePuzzle(roomInfo, stage, onSolved)
    local length = self.Config.PuzzleScale.SequenceLengthStart + (stage - 3) * self.Config.PuzzleScale.SequenceLengthGrowth
    local buttonCount = self.Config.PuzzleScale.SequenceButtonCount

    local sequence = {}
    for i = 1, length do
        sequence[i] = math.random(1, buttonCount)
    end

    local buttons = {}
    local currentIndex = 1
    local basePosition = roomInfo.Center + Vector3.new(0, -roomInfo.Size.Y / 2 + 1, -roomInfo.Size.Z / 2 + 10)
    local spacing = 6

    for i = 1, buttonCount do
        local offset = (i - (buttonCount + 1) / 2) * spacing
        local button, pressTween, releaseTween = createButton(roomInfo.Folder, basePosition + Vector3.new(offset, 0, 0), Color3.fromRGB(120, 170, 255))
        local prompt = createPrompt(button, "Press")
        table.insert(self.ActiveParts, button)
        table.insert(buttons, button)

        local connection = prompt.Triggered:Connect(function()
            pressTween:Play()
            task.delay(0.2, function()
                releaseTween:Play()
            end)

            if sequence[currentIndex] == i then
                currentIndex += 1
                if currentIndex > #sequence then
                    onSolved()
                end
            else
                currentIndex = 1
                for _, b in ipairs(buttons) do
                    b.Color = Color3.fromRGB(255, 60, 60)
                end
                task.delay(self.Config.PuzzleScale.SequenceResetDelay, function()
                    for _, b in ipairs(buttons) do
                        if b and b.Parent then
                            b.Color = Color3.fromRGB(120, 170, 255)
                        end
                    end
                end)
            end
        end)

        table.insert(self.Connections, connection)
    end
end

function PuzzleService:CreateFakeButtonsPuzzle(roomInfo, _stage, onSolved)
    local totalButtons = self.Config.PuzzleScale.FakeButtonCount
    local correctIndex = math.random(1, totalButtons)
    local basePosition = roomInfo.Center + Vector3.new(0, -roomInfo.Size.Y / 2 + 1, -roomInfo.Size.Z / 2 + 10)

    for i = 1, totalButtons do
        local x = (i - (totalButtons + 1) / 2) * 5
        local button = Instance.new("Part")
        button.Name = "FakePuzzleButton"
        button.Size = BUTTON_SIZE
        button.Anchored = true
        button.Material = Enum.Material.Neon
        button.Color = Color3.fromRGB(100, 180, 255)
        button.CFrame = CFrame.new(basePosition + Vector3.new(x, 0, 0))
        button.Parent = roomInfo.Folder
        table.insert(self.ActiveParts, button)

        local prompt = createPrompt(button, "Choose")
        local connection = prompt.Triggered:Connect(function()
            if i == correctIndex then
                button.Color = Color3.fromRGB(40, 220, 40)
                onSolved()
            else
                button.Color = Color3.fromRGB(255, 60, 60)
                task.delay(0.5, function()
                    if button and button.Parent then
                        button.Color = Color3.fromRGB(100, 180, 255)
                    end
                end)
            end
        end)
        table.insert(self.Connections, connection)
    end
end

function PuzzleService:CreateTimedDoorPuzzle(roomInfo, stage, onSolved)
    local windowSeconds = math.max(2, self.Config.PuzzleScale.TimedDoorWindow - math.floor(stage / 8))
    local buttonPosition = roomInfo.Center + Vector3.new(0, -roomInfo.Size.Y / 2 + 1, -roomInfo.Size.Z / 2 + 10)
    local button, _, _ = createButton(roomInfo.Folder, buttonPosition, Color3.fromRGB(255, 170, 60))
    table.insert(self.ActiveParts, button)

    local timedSwitch = Instance.new("BoolValue")
    timedSwitch.Name = "TimedDoorUnlocked"
    timedSwitch.Value = false
    timedSwitch.Parent = roomInfo.Folder
    table.insert(self.ActiveParts, timedSwitch)

    local prompt = createPrompt(button, string.format("Open %.1fs window", windowSeconds))
    local expireAt = 0

    local connection = prompt.Triggered:Connect(function()
        expireAt = os.clock() + windowSeconds
        timedSwitch.Value = true
        button.Color = Color3.fromRGB(40, 220, 40)
        task.delay(windowSeconds, function()
            if os.clock() >= expireAt and timedSwitch.Parent then
                timedSwitch.Value = false
                button.Color = Color3.fromRGB(255, 170, 60)
            end
        end)
    end)
    table.insert(self.Connections, connection)

    local gate = Instance.new("Part")
    gate.Name = "TimedGate"
    gate.Anchored = true
    gate.Size = Vector3.new(8, 8, 2)
    gate.Material = Enum.Material.Metal
    gate.Color = Color3.fromRGB(180, 60, 60)
    gate.CFrame = CFrame.new(roomInfo.Center.X, roomInfo.FloorY + 4, roomInfo.Center.Z + roomInfo.Size.Z * 0.25)
    gate.Parent = roomInfo.Folder
    table.insert(self.ActiveParts, gate)

    local touchConnection = gate.Touched:Connect(function(hit)
        local character = hit.Parent
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and timedSwitch.Value then
            onSolved()
        end
    end)
    table.insert(self.Connections, touchConnection)
end

function PuzzleService:CreateMazePuzzle(roomInfo, stage, onSolved)
    local gridSize = math.min(9, self.Config.PuzzleScale.MazeGridBase + math.floor(stage / 5))
    if gridSize % 2 == 0 then
        gridSize += 1
    end

    local cellSize = math.max(4, math.floor(math.min(roomInfo.Size.X, roomInfo.Size.Z) / (gridSize + 1)))
    local origin = roomInfo.Center + Vector3.new(-(gridSize // 2) * cellSize, -roomInfo.Size.Y / 2 + 1, -roomInfo.Size.Z / 2 + 10)

    for x = 1, gridSize do
        for z = 1, gridSize do
            local border = x == 1 or z == 1 or x == gridSize or z == gridSize
            local randomWall = (x % 2 == 0 and z % 2 == 0 and math.random() < 0.4)
            if border or randomWall then
                local wall = Instance.new("Part")
                wall.Name = "MazeWall"
                wall.Anchored = true
                wall.Material = Enum.Material.Basalt
                wall.Color = Color3.fromRGB(70, 70, 75)
                wall.Size = Vector3.new(cellSize, 8, cellSize)
                wall.CFrame = CFrame.new(origin + Vector3.new((x - 1) * cellSize, 4, (z - 1) * cellSize))
                wall.Parent = roomInfo.Folder
                table.insert(self.ActiveParts, wall)
            end
        end
    end

    local goal = Instance.new("Part")
    goal.Name = "MazeGoal"
    goal.Anchored = true
    goal.Size = Vector3.new(4, 1, 4)
    goal.Material = Enum.Material.Neon
    goal.Color = Color3.fromRGB(50, 255, 120)
    goal.CFrame = CFrame.new(origin + Vector3.new((gridSize - 2) * cellSize, 0.5, (gridSize - 2) * cellSize))
    goal.Parent = roomInfo.Folder
    table.insert(self.ActiveParts, goal)

    local connection = goal.Touched:Connect(function(hit)
        local character = hit.Parent
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            onSolved()
        end
    end)
    table.insert(self.Connections, connection)
end

return PuzzleService
