local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
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

local builder = RoomBuilder.new(gameFolder, Config)
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
local stageResolved = false

local stageValue = ReplicatedStorage:FindFirstChild("EscapeStage") or Instance.new("IntValue")
stageValue.Name = "EscapeStage"
stageValue.Parent = ReplicatedStorage

local timerValue = ReplicatedStorage:FindFirstChild("EscapeTimer") or Instance.new("NumberValue")
timerValue.Name = "EscapeTimer"
timerValue.Parent = ReplicatedStorage

local modeValue = ReplicatedStorage:FindFirstChild("EscapeModeValue") or Instance.new("StringValue")
modeValue.Name = "EscapeModeValue"
modeValue.Parent = ReplicatedStorage

local statusValue = ReplicatedStorage:FindFirstChild("EscapeStatus") or Instance.new("StringValue")
statusValue.Name = "EscapeStatus"
statusValue.Parent = ReplicatedStorage

local stageStore = DataStoreService:GetDataStore("EscapeBestStage_v1")

local beginStage

local function updateHud(message)
    statusValue.Value = message
    stageValue.Value = stage
    modeValue.Value = mode
    timerValue.Value = math.max(0, timerEndsAt - os.clock())
end

local function updateLeaderboardForPlayer(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player

        local bestStage = Instance.new("IntValue")
        bestStage.Name = "BestStage"
        bestStage.Parent = leaderstats

        local bestRun = Instance.new("NumberValue")
        bestRun.Name = "BestRunSeconds"
        bestRun.Parent = leaderstats
    end

    local bestStageValue = leaderstats:FindFirstChild("BestStage")
    if bestStageValue and stage > bestStageValue.Value then
        bestStageValue.Value = stage
    end

    local bestRunValue = leaderstats:FindFirstChild("BestRunSeconds")
    if bestRunValue and bestTime < math.huge then
        if bestRunValue.Value == 0 or bestTime < bestRunValue.Value then
            bestRunValue.Value = bestTime
        end
    end
end

local function savePlayerStats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local bestStageValue = leaderstats:FindFirstChild("BestStage")
    if not bestStageValue then
        return
    end

    local ok = pcall(function()
        stageStore:SetAsync(tostring(player.UserId), bestStageValue.Value)
    end)

    if not ok then
        warn("Failed to save leaderboard for", player.Name)
    end
end

local function loadPlayerStats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local bestStageValue = Instance.new("IntValue")
    bestStageValue.Name = "BestStage"
    bestStageValue.Parent = leaderstats

    local bestRunValue = Instance.new("NumberValue")
    bestRunValue.Name = "BestRunSeconds"
    bestRunValue.Parent = leaderstats

    local ok, result = pcall(function()
        return stageStore:GetAsync(tostring(player.UserId))
    end)

    if ok and type(result) == "number" then
        bestStageValue.Value = result
    end
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

local function grantTime(seconds)
    if mode ~= Config.Modes.Timed then
        return
    end

    timerEndsAt = math.min(timerEndsAt + seconds, os.clock() + Config.Timed.MaxSeconds)
end

local function resetRun(reason)
    local elapsed = os.clock() - runStart
    updateHud(string.format("Run reset (%s). Survived %.1fs.", reason, elapsed))
    stage = 0
    runStart = os.clock()
    timerEndsAt = os.clock() + Config.Timed.StartSeconds
    stageResolved = false
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
        local player = character and Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        touched = true
        connection:Disconnect()
        onComplete()
    end)
end

local function completeStage(requireDoorTouch, bonusSeconds)
    if not activeRoom or stageResolved then
        return
    end

    stageResolved = true
    local clearBonus = bonusSeconds or Config.Timed.BonusPerClear
    if clearBonus > 0 then
        grantTime(clearBonus)
    end

    for _, player in ipairs(Players:GetPlayers()) do
        updateLeaderboardForPlayer(player)
    end

    if requireDoorTouch then
        openDoorAndWait(activeRoom, function()
            beginStage()
        end)
    else
        beginStage()
    end
end

beginStage = function()
    stage += 1
    stageResolved = false

    local roomSize = roomSizeForStage(stage)
    local roomCenter = nextRoomCenter(activeRoom, roomSize)
    activeRoom = builder:CreateRoom(stage, roomCenter, roomSize)
    builder:SetDoorOpen(activeRoom, false)

    if stage == 1 then
        sendPlayersToSpawn(activeRoom)
    end

    puzzleService:CreatePuzzleForRoom(activeRoom, stage, function()
        completeStage(true)
    end)

    updateHud(string.format("Mode: %s | Room: %d", mode, stage))
end

local function setMode(newMode)
    mode = newMode
    Workspace:SetAttribute("EscapeMode", mode)
    resetRun("mode changed")
    beginStage()
end

Players.PlayerAdded:Connect(function(player)
    loadPlayerStats(player)

    player.CharacterAdded:Connect(function(character)
        if activeRoom and character.PrimaryPart then
            character:PivotTo(CFrame.new(activeRoom.Center + Vector3.new(0, 0, -activeRoom.Size.Z / 2 + 8)))
        end
    end)
end)

Players.PlayerRemoving:Connect(savePlayerStats)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlayerStats(player)
    end
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

MarketplaceService.ProcessReceipt = function(receiptInfo)
    if not Config.Monetization.Enabled then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local products = Config.Monetization.Products
    if receiptInfo.ProductId == products.SkipRoom.ProductId then
        completeStage(false, products.SkipRoom.BonusTimeOnSkip)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    if receiptInfo.ProductId == products.TimeBoost.ProductId then
        grantTime(products.TimeBoost.SecondsGranted)
        updateHud(string.format("Mode: %s | Room: %d | +%ds", mode, stage, products.TimeBoost.SecondsGranted))
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

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
            updateHud(string.format("Mode: %s | Room: %d | Best: %.1fs", mode, stage, bestTime == math.huge and 0 or bestTime))
        end
    else
        timerValue.Value = 0
        updateHud(string.format("Mode: %s | Room: %d | Endless", mode, stage))
    end
end
