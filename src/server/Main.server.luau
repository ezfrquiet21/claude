--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "GameState"
stateEvent.Parent = ReplicatedStorage

local half = Config.ArenaSize / 2
local roundActive = false

-- Arena ---------------------------------------------------------------------

local arena = Instance.new("Folder")
arena.Name = "Arena"
arena.Parent = Workspace

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Parent = arena
	return part
end

makePart("Floor", Vector3.new(Config.ArenaSize, 2, Config.ArenaSize), Vector3.new(0, -1, 0), Color3.fromRGB(60, 140, 90))
for _, side in { -1, 1 } do
	makePart("WallX", Vector3.new(2, 12, Config.ArenaSize), Vector3.new(side * half, 5, 0), Color3.fromRGB(40, 40, 60))
	makePart("WallZ", Vector3.new(Config.ArenaSize, 12, 2), Vector3.new(0, 5, side * half), Color3.fromRGB(40, 40, 60))
end

-- A few pillars to run around.
local rng = Random.new()
for i = 1, 12 do
	local height = rng:NextInteger(6, 16)
	makePart(
		"Pillar" .. i,
		Vector3.new(rng:NextInteger(4, 8), height, rng:NextInteger(4, 8)),
		Vector3.new(rng:NextNumber(-half + 10, half - 10), height / 2, rng:NextNumber(-half + 10, half - 10)),
		Color3.fromHSV(rng:NextNumber(), 0.4, 0.8)
	)
end

local spawn = Instance.new("SpawnLocation")
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = arena

-- Players --------------------------------------------------------------------

local function setupPlayer(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = stats
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = stats
	stats.Parent = player
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

local function addCoins(player: Player, amount: number)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins") :: IntValue?
	if coins then
		coins.Value += amount
	end
end

local function speedBoost(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = Config.SpeedBoostWalkSpeed
	task.delay(Config.SpeedBoostDuration, function()
		if humanoid.Parent then
			humanoid.WalkSpeed = Config.DefaultWalkSpeed
		end
	end)
end

-- Coins ------------------------------------------------------------------------

local function spawnCoin()
	local roll = rng:NextNumber()
	local kind = "Coin"
	local color = Color3.fromRGB(255, 210, 40)
	local value = Config.CoinValue
	if roll < Config.SpeedBoostChance then
		kind = "Boost"
		color = Color3.fromRGB(60, 200, 255)
		value = 0
	elseif roll < Config.SpeedBoostChance + Config.GoldChance then
		kind = "Gold"
		color = Color3.fromRGB(255, 120, 30)
		value = Config.GoldValue
	end

	local coin = Instance.new("Part")
	coin.Name = kind
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.4, 3, 3)
	coin.Color = color
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	coin.CFrame = CFrame.new(rng:NextNumber(-half + 4, half - 4), 3, rng:NextNumber(-half + 4, half - 4))
		* CFrame.Angles(0, 0, math.rad(90))
	coin:SetAttribute("Value", value)
	CollectionService:AddTag(coin, Config.CoinTag)

	local collected = false
	coin.Touched:Connect(function(hit)
		if collected or not roundActive then
			return
		end
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then
			return
		end
		collected = true
		if kind == "Boost" then
			speedBoost(player)
		else
			addCoins(player, value)
		end
		coin:Destroy()
	end)
	coin.Parent = Workspace
end

local function clearCoins()
	for _, coin in CollectionService:GetTagged(Config.CoinTag) do
		coin:Destroy()
	end
end

-- Round loop ---------------------------------------------------------------------

local function broadcast(phase: string, secondsLeft: number, message: string?)
	stateEvent:FireAllClients(phase, secondsLeft, message)
end

local function runIntermission()
	roundActive = false
	clearCoins()
	for t = Config.IntermissionLength, 1, -1 do
		broadcast("Intermission", t, "Get ready!")
		task.wait(1)
	end
end

local function runRound()
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins") :: IntValue?
		if coins then
			coins.Value = 0
		end
		player:LoadCharacter()
	end

	roundActive = true
	local lastSpawn = 0
	for t = Config.RoundLength, 1, -1 do
		broadcast("Round", t, nil)
		for _ = 1, 4 do
			if os.clock() - lastSpawn >= Config.CoinSpawnInterval
				and #CollectionService:GetTagged(Config.CoinTag) < Config.MaxCoins
			then
				spawnCoin()
				lastSpawn = os.clock()
			end
			task.wait(0.25)
		end
	end
	roundActive = false

	local best: Player? = nil
	local bestScore = 0
	for _, player in Players:GetPlayers() do
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins") :: IntValue?
		if coins and coins.Value > bestScore then
			best, bestScore = player, coins.Value
		end
	end

	if best then
		local wins = best.leaderstats:FindFirstChild("Wins") :: IntValue?
		if wins then
			wins.Value += 1
		end
		broadcast("Result", 3, `{best.DisplayName} wins with {bestScore} coins!`)
	else
		broadcast("Result", 3, "Nobody collected any coins!")
	end
	task.wait(5)
end

Players.CharacterAutoLoads = false
Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end)
for _, player in Players:GetPlayers() do
	player:LoadCharacter()
end

while true do
	runIntermission()
	runRound()
end
