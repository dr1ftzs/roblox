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
    else
        self:CreateSequencePuzzle(roomInfo, stage, onSolved)
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

    local function flash(button)
        local original = button.Color
        button.Color = Color3.fromRGB(255, 255, 255)
        task.delay(0.2, function()
            if button and button.Parent then
                button.Color = original
            end
        end)
    end

    for i = 1, buttonCount do
        local offset = (i - (buttonCount + 1) / 2) * spacing
        local button, pressTween, releaseTween = createButton(roomInfo.Folder, basePosition + Vector3.new(offset, 0, 0), Color3.fromRGB(120, 170, 255))
        local prompt = createPrompt(button, "Press")

        table.insert(self.ActiveParts, button)

        local connection = prompt.Triggered:Connect(function()
            flash(button)
            pressTween:Play()
            task.delay(0.2, function()
                releaseTween:Play()
            end)

            if sequence[currentIndex] == i then
                currentIndex += 1

                if currentIndex > #sequence then
                    for _, b in ipairs(buttons) do
                        b.Color = Color3.fromRGB(40, 220, 40)
                    end
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

        table.insert(buttons, button)
        table.insert(self.Connections, connection)
    end

    local hint = Instance.new("Hint")
    hint.Text = "Sequence length: " .. tostring(#sequence) .. " (hidden). Memorize from trial and error!"
    hint.Parent = roomInfo.Folder
    table.insert(self.ActiveParts, hint)
end

return PuzzleService
