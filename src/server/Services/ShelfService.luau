local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Shared.Modules.Enums)
local StationData = require(ReplicatedStorage.Shared.Modules.StationData)

local ShelfService = {}

local shelfByPlayer = {}

local SHELF_PART_PATH = { "Bakery", "DisplayArea", "Shelf_01" }

local function getShelfPart()
	local current = workspace

	for _, name in ipairs(SHELF_PART_PATH) do
		current = current:FindFirstChild(name)
		if not current then
			return nil
		end
	end

	return current
end

local function isPlayerNearShelf(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local shelfPart = getShelfPart()

	if not root or not shelfPart or not shelfPart:IsA("BasePart") then
		return false
	end

	return (root.Position - shelfPart.Position).Magnitude <= 14
end

function ShelfService:Init(context)
	self.Context = context
	self.CarryService = context.Services.CarryService
	self.StateUpdated = context.Remotes.Get("StateUpdated")
end

function ShelfService:Start()
	self.Context.Remotes.Get("RequestPlaceOnShelf").OnServerEvent:Connect(function(player)
		self:RequestPlaceOnShelf(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		shelfByPlayer[player] = nil
	end)

	self.Context.Events.Connect("PlayerReady", function(player)
		self:GetShelf(player)
		self:SendSnapshot(player)
	end)
end

function ShelfService:GetShelf(player)
	if not shelfByPlayer[player] then
		shelfByPlayer[player] = {
			Capacity = StationData.Shelf.Capacity,
			Stock = {},
		}
	end

	return shelfByPlayer[player]
end

function ShelfService:GetTotalStock(player)
	local shelf = self:GetShelf(player)
	local total = 0

	for _, count in pairs(shelf.Stock) do
		total += count
	end

	return total
end

function ShelfService:GetStockSnapshot(player)
	local shelf = self:GetShelf(player)
	local copy = {}

	for recipeId, count in pairs(shelf.Stock) do
		copy[recipeId] = count
	end

	return copy
end

function ShelfService:RequestPlaceOnShelf(player)
	if not isPlayerNearShelf(player) then
		return self:Notify(player, "Move closer to the shelf")
	end

	local carriedItem = self.CarryService:GetCarriedItem(player)

	if not carriedItem or carriedItem.State ~= Enums.CarryState.CarryingBaked then
		return self:Notify(player, "Need baked product")
	end

	if not self:TryAddStock(player, carriedItem.RecipeId) then
		return self:Notify(player, "Shelf is full")
	end

	self.CarryService:ClearCarriedItem(player)
	self.Context.Events.Fire("ProductShelved", player, carriedItem.RecipeId)
end

function ShelfService:TryAddStock(player, recipeId)
	local shelf = self:GetShelf(player)

	if self:GetTotalStock(player) >= shelf.Capacity then
		return false
	end

	shelf.Stock[recipeId] = (shelf.Stock[recipeId] or 0) + 1
	self:SendSnapshot(player)

	return true
end

function ShelfService:TryRemoveStock(player, recipeId)
	local shelf = self:GetShelf(player)
	local currentStock = shelf.Stock[recipeId] or 0

	if currentStock <= 0 then
		return false
	end

	shelf.Stock[recipeId] = currentStock - 1
	self:SendSnapshot(player)

	return true
end

function ShelfService:SendSnapshot(player)
	local shelf = self:GetShelf(player)

	self.StateUpdated:FireClient(player, "ShelfSnapshot", {
		Capacity = shelf.Capacity,
		Stock = shelf.Stock,
		TotalStock = self:GetTotalStock(player),
	})
end

function ShelfService:Notify(player, message)
	self.Context.Remotes.Get("Notify"):FireClient(player, message)
end

return ShelfService
