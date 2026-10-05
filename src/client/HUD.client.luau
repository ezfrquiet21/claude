--!strict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local stateEvent = ReplicatedStorage:WaitForChild("GameState") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "CoinRushHUD"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local function makeLabel(position: UDim2, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = position
	label.Size = UDim2.fromOffset(500, size + 10)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.FredokaOne
	label.TextSize = size
	label.Text = ""
	label.Parent = gui
	return label
end

local timerLabel = makeLabel(UDim2.fromScale(0.5, 0.02), 36)
local messageLabel = makeLabel(UDim2.fromScale(0.5, 0.1), 28)

stateEvent.OnClientEvent:Connect(function(phase: string, secondsLeft: number, message: string?)
	if phase == "Round" then
		timerLabel.Text = `Time left: {secondsLeft}s`
		messageLabel.Text = "Collect coins! Orange = 5, blue = speed"
	elseif phase == "Intermission" then
		timerLabel.Text = `Next round in {secondsLeft}s`
		messageLabel.Text = message or ""
	else
		timerLabel.Text = "Round over"
		messageLabel.Text = message or ""
	end
end)

-- Spin and bob coins locally (cheap, keeps the server quiet).
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for _, coin in CollectionService:GetTagged(Config.CoinTag) do
		if coin:IsA("BasePart") then
			local pos = coin.Position
			coin.CFrame = CFrame.new(pos.X, 3 + math.sin(now * 2 + pos.X) * 0.5, pos.Z)
				* CFrame.Angles(0, now * 2, math.rad(90))
		end
	end
end)
