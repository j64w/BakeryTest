local Players = game:GetService("Players")

local DataService = {}

local DEFAULT_DATA = {
	Coins = 0,
	Experience = 0,
	Level = 1,
	UnlockedRecipes = { "bread_basic" },
	Upgrades = {
		Oven = { Speed = 1, Capacity = 1, Quality = 1 },
		Table = { Slots = 1, Speed = 1 },
		Shelf = { Capacity = 3 },
		Shop = { CustomerRate = 1 },
	},
	MissionProgress = {},
}

local playerData = {}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in pairs(value) do
		copy[key] = deepCopy(child)
	end

	return copy
end

local function ensureLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.Level
	level.Parent = leaderstats
end

function DataService:Init(context)
	self.Context = context
end

function DataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:LoadPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:ReleasePlayer(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:LoadPlayer(player)
	end
end

function DataService:LoadPlayer(player)
	if playerData[player] then
		return
	end

	local data = deepCopy(DEFAULT_DATA)
	playerData[player] = data
	ensureLeaderstats(player, data)
end

function DataService:ReleasePlayer(player)
	playerData[player] = nil
end

function DataService:GetData(player)
	if not playerData[player] then
		self:LoadPlayer(player)
	end

	return playerData[player]
end

function DataService:SetValue(player, key, value)
	local data = self:GetData(player)
	data[key] = value

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and (key == "Coins" or key == "Level") then
		local stat = leaderstats:FindFirstChild(key)
		if stat then
			stat.Value = value
		end
	end
end

return DataService
