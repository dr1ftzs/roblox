local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "EscapeHud"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 760, 0, 36)
label.Position = UDim2.new(0.5, -380, 0, 20)
label.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
label.BackgroundTransparency = 0.2
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBold
label.TextSize = 16
label.TextColor3 = Color3.fromRGB(245, 245, 245)
label.Text = "Escape loading..."
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = label

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0, 260, 0, 24)
hint.Position = UDim2.new(0.5, -130, 0, 60)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 14
hint.TextColor3 = Color3.fromRGB(200, 220, 255)
hint.Text = "Press M to switch Timed/Endless"
hint.Parent = gui

local statusValue = ReplicatedStorage:WaitForChild("EscapeStatus")
statusValue:GetPropertyChangedSignal("Value"):Connect(function()
    label.Text = statusValue.Value
end)
label.Text = statusValue.Value

local modeSwitchEvent = ReplicatedStorage:WaitForChild("EscapeModeSwitch")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.M then
        modeSwitchEvent:FireServer()
    end
end)
