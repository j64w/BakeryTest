local Players = game:GetService("Players")

local UIController = {}

local player = Players.LocalPlayer
local labels = {}

local function makeLabel(parent, name, position, text)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundColor3 = Color3.fromRGB(255, 241, 222)
	label.BorderSizePixel = 0
	label.Position = position
	label.Size = UDim2.fromOffset(180, 32)
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(72, 48, 36)
	label.TextSize = 16
	label.Text = text
	label.Parent = parent

	return label
end

function UIController:Init(context)
	self.Context = context
end

function UIController:Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BunnysBakeryHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	labels.Coins = makeLabel(gui, "Coins", UDim2.fromOffset(16, 16), "Coins: 0")
	labels.Level = makeLabel(gui, "Level", UDim2.fromOffset(16, 54), "Level: 1")
	labels.Experience = makeLabel(gui, "Experience", UDim2.fromOffset(16, 92), "EXP: 0")
	labels.Carry = makeLabel(gui, "Carry", UDim2.fromOffset(16, 130), "Hands: empty")
	labels.Shelf = makeLabel(gui, "Shelf", UDim2.fromOffset(16, 168), "Shelf: 0/3")

	self.Context.Remotes.Get("StateUpdated").OnClientEvent:Connect(function(snapshotType, payload)
		self:ApplySnapshot(snapshotType, payload)
	end)
end

function UIController:ApplySnapshot(snapshotType, payload)
	if snapshotType == "EconomySnapshot" then
		labels.Coins.Text = "Coins: " .. tostring(payload.Coins)
		labels.Level.Text = "Level: " .. tostring(payload.Level)

		local nextExperience = payload.NextLevelExperience
		if nextExperience then
			labels.Experience.Text = "EXP: " .. tostring(payload.Experience) .. "/" .. tostring(nextExperience)
		else
			labels.Experience.Text = "EXP: " .. tostring(payload.Experience)
		end
	elseif snapshotType == "CarrySnapshot" then
		labels.Carry.Text = "Hands: " .. tostring(payload.State)
	elseif snapshotType == "ShelfSnapshot" then
		labels.Shelf.Text = "Shelf: " .. tostring(payload.TotalStock) .. "/" .. tostring(payload.Capacity)
	end
end

return UIController
