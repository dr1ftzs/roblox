local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local escapeFolder = ReplicatedStorage:WaitForChild("EscapeGame")
local Config = require(escapeFolder:WaitForChild("Config"))
local RoomBuilder = require(escapeFolder:WaitForChild("RoomBuilder"))

local runtime = Workspace:FindFirstChild("EscapeRuntime")
if runtime then
	runtime:Destroy()
end

runtime = Instance.new("Folder")
runtime.Name = "EscapeRuntime"
runtime.Parent = Workspace

local builder = RoomBuilder.new(runtime, Config)
builder:BuildRun(Config.Defaults.InitialStageCount)
