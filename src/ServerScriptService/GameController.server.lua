local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("EscapeGame"):WaitForChild("Config"))
local RoomBuilder = require(ReplicatedStorage:WaitForChild("EscapeGame"):WaitForChild("RoomBuilder"))
local PuzzleService = require(ReplicatedStorage:WaitForChild("EscapeGame"):WaitForChild("PuzzleService"))

local gameFolder = Workspace:FindFirstChild("EscapeRuntime")
if gameFolder then
    gameFolder:Destroy()
end

gameFolder = Instance.new("Folder")
gameFolder.Name = "EscapeRuntime"
gameFolder.Parent = Workspace

local builder = RoomBuilder.new(gameFolder)
local puzzleService = PuzzleService.new(Config)

local mode = Workspace:GetAttribute("EscapeMode")
if mode ~= Config.Modes.Endless then
    mode = Config.Modes.Timed
end

local stage = 0
local activeRoom = nil
local timerEndsAt = 0
local runStart = os.clock()
local bestTime = math.huge

local function setHudState(message)
    local statusValue = ReplicatedStorage:FindFirstChild("EscapeStatus")
    if not statusValue then
        statusValue = Instance.new("StringValue")
        statusValue.Name = "EscapeStatus"
        statusValue.Parent = ReplicatedStorage
    end

    statusValue.Value = message
end

local function sendPlayersToSpawn(room)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character.PrimaryPart then
            player.Character:PivotTo(CFrame.new(room.Center + Vector3.new(0, 0, -room.Size.Z / 2 + 8)))
        end
    end
end

local function clearWorld()
    puzzleService:Clear()
    gameFolder:ClearAllChildren()
end

local function resetRun(reason)
    local elapsed = os.clock() - runStart
    setHudState(string.format("Run reset (%s). Survived %.1fs. Press M to switch mode.", reason, elapsed))
    stage = 0
    runStart = os.clock()
    timerEndsAt = os.clock() + Config.Timed.StartSeconds

    clearWorld()
end

local function roomSizeForStage(currentStage)
    return Config.RoomBaseSize + (Config.RoomGrowthPerStage * (currentStage - 1))
end

local function nextRoomCenter(previousRoom, newSize)
    if not previousRoom then
        return Config.SpawnPosition + Vector3.new(0, newSize.Y / 2, 0)
    end

    local previousHalf = previousRoom.Size.Z / 2
    local newHalf = newSize.Z / 2
    return previousRoom.Center + Vector3.new(0, (newSize.Y - previousRoom.Size.Y) / 2, previousHalf + newHalf + Config.CorridorGap)
end

local function openDoorAndWait(room, onComplete)
    builder:SetDoorOpen(room, true)

    local touched = false
    local connection
    connection = room.Door.Touched:Connect(function(hit)
        if touched then
            return
        end

        local character = hit.Parent
        if not character then
            return
        end

        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        touched = true
        connection:Disconnect()
        onComplete()
    end)
end

local function beginStage()
    stage += 1

    local roomSize = roomSizeForStage(stage)
    local roomCenter = nextRoomCenter(activeRoom, roomSize)
    activeRoom = builder:CreateRoom(stage, roomCenter, roomSize)
    builder:SetDoorOpen(activeRoom, false)

    if stage == 1 then
        sendPlayersToSpawn(activeRoom)
    end

    local function solved()
        builder:SetDoorOpen(activeRoom, true)

        if mode == Config.Modes.Timed then
            timerEndsAt = math.min(timerEndsAt + Config.Timed.BonusPerClear, os.clock() + Config.Timed.MaxSeconds)
        end

        openDoorAndWait(activeRoom, function()
            beginStage()
        end)
    end

    puzzleService:CreatePuzzleForRoom(activeRoom, stage, solved)

    local clockText = mode == Config.Modes.Timed and string.format(" | Time left: %.1fs", math.max(0, timerEndsAt - os.clock())) or ""
    setHudState(string.format("Mode: %s | Stage: %d%s", mode, stage, clockText))
end

local function setMode(newMode)
    mode = newMode
    Workspace:SetAttribute("EscapeMode", mode)
    resetRun("mode changed")
    beginStage()
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if activeRoom and character.PrimaryPart then
            character:PivotTo(CFrame.new(activeRoom.Center + Vector3.new(0, 0, -activeRoom.Size.Z / 2 + 8)))
        end
    end)
end)

local modeEvent = Instance.new("RemoteEvent")
modeEvent.Name = "EscapeModeSwitch"
modeEvent.Parent = ReplicatedStorage
modeEvent.OnServerEvent:Connect(function(player)
    if not player then
        return
    end

    if mode == Config.Modes.Timed then
        setMode(Config.Modes.Endless)
    else
        setMode(Config.Modes.Timed)
    end
end)

resetRun("startup")
beginStage()

while true do
    task.wait(0.1)

    if mode == Config.Modes.Timed then
        local remaining = timerEndsAt - os.clock()
        if remaining <= 0 then
            if stage > 1 then
                local runTime = os.clock() - runStart
                if runTime < bestTime then
                    bestTime = runTime
                end
            end

            resetRun("timer expired")
            beginStage()
        else
            setHudState(string.format("Mode: %s | Stage: %d | Time left: %.1fs | Best: %.1fs", mode, stage, remaining, bestTime == math.huge and 0 or bestTime))
        end
    else
        setHudState(string.format("Mode: %s | Stage: %d | Endless rooms generated", mode, stage))
    end
end
