local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage:WaitForChild("EscapeGame"):WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "EscapeHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 520, 0, 40)
title.Position = UDim2.new(0.5, -260, 0, 16)
title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
title.BackgroundTransparency = 0.2
title.BorderSizePixel = 0
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(245, 245, 245)
title.Text = "Escape loading..."
title.Parent = gui

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0, 240, 0, 32)
timerLabel.Position = UDim2.new(0.5, -260, 0, 64)
timerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
timerLabel.BackgroundTransparency = 0.3
timerLabel.BorderSizePixel = 0
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 16
timerLabel.TextColor3 = Color3.fromRGB(255, 226, 120)
timerLabel.Text = "Time: --"
timerLabel.Parent = gui

local roomLabel = timerLabel:Clone()
roomLabel.Position = UDim2.new(0.5, 20, 0, 64)
roomLabel.TextColor3 = Color3.fromRGB(150, 220, 255)
roomLabel.Text = "Room: --"
roomLabel.Parent = gui

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 600, 0, 24)
hint.Position = UDim2.new(0.5, -300, 0, 102)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
hint.TextColor3 = Color3.fromRGB(200, 220, 255)
hint.Text = "Press M to switch Timed/Endless"
hint.Parent = gui

local function createMonetizationButton(text, xOffset)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 190, 0, 34)
    button.Position = UDim2.new(0.5, xOffset, 0, 130)
    button.BackgroundColor3 = Color3.fromRGB(26, 48, 70)
    button.BorderSizePixel = 0
    button.AutoButtonColor = true
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(245, 245, 245)
    button.Text = text
    button.Parent = gui

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button
    return button
end

if Config.Monetization.Enabled then
    local products = Config.Monetization.Products
    local skipButton = createMonetizationButton("Skip Room", -200)
    local timeButton = createMonetizationButton(string.format("+%ds Time", products.TimeBoost.SecondsGranted), 10)

    skipButton.Activated:Connect(function()
        if products.SkipRoom.ProductId > 0 then
            MarketplaceService:PromptProductPurchase(player, products.SkipRoom.ProductId)
        end
    end)

    timeButton.Activated:Connect(function()
        if products.TimeBoost.ProductId > 0 then
            MarketplaceService:PromptProductPurchase(player, products.TimeBoost.ProductId)
        end
    end)

    hint.Text = "M: switch mode | Buy Skip Room / Time Boost"
end

local statusValue = ReplicatedStorage:WaitForChild("EscapeStatus")
local stageValue = ReplicatedStorage:WaitForChild("EscapeStage")
local timerValue = ReplicatedStorage:WaitForChild("EscapeTimer")
local modeValue = ReplicatedStorage:WaitForChild("EscapeModeValue")

statusValue:GetPropertyChangedSignal("Value"):Connect(function()
    title.Text = statusValue.Value
end)

stageValue:GetPropertyChangedSignal("Value"):Connect(function()
    roomLabel.Text = string.format("Room: %d", stageValue.Value)
end)

timerValue:GetPropertyChangedSignal("Value"):Connect(function()
    if modeValue.Value == Config.Modes.Timed then
        timerLabel.Text = string.format("Time: %.1fs", timerValue.Value)
    else
        timerLabel.Text = "Time: Endless"
    end
end)

modeValue:GetPropertyChangedSignal("Value"):Connect(function()
    if modeValue.Value ~= Config.Modes.Timed then
        timerLabel.Text = "Time: Endless"
    else
        timerLabel.Text = string.format("Time: %.1fs", timerValue.Value)
    end
end)

title.Text = statusValue.Value
roomLabel.Text = string.format("Room: %d", stageValue.Value)
if modeValue.Value == Config.Modes.Timed then
    timerLabel.Text = string.format("Time: %.1fs", timerValue.Value)
else
    timerLabel.Text = "Time: Endless"
end

local modeSwitchEvent = ReplicatedStorage:WaitForChild("EscapeModeSwitch")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.M then
        modeSwitchEvent:FireServer()
    end
end)
