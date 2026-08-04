local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RecipeData = require(ReplicatedStorage.Shared.Modules.RecipeData)
local StationData = require(ReplicatedStorage.Shared.Modules.StationData)

local CustomerService = {}

function CustomerService:Init(context)
	self.Context = context
	self.ShelfService = context.Services.ShelfService
	self.EconomyService = context.Services.EconomyService
end

function CustomerService:Start()
	task.spawn(function()
		task.wait(StationData.Customers.FirstSpawnDelay)

		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				self:TryServeBasicCustomer(player)
			end

			task.wait(math.random(StationData.Customers.MinSpawnDelay, StationData.Customers.MaxSpawnDelay))
		end
	end)
end

function CustomerService:TryServeBasicCustomer(player)
	local recipeId, recipe = self:FindAvailableProduct(player)

	if not recipeId or not recipe then
		return
	end

	self.EconomyService:AddCoins(player, recipe.SellPrice)
	self.EconomyService:AddExperience(player, recipe.SellExperience)
	self.Context.Events.Fire("ProductSold", player, recipeId, recipe.SellPrice, recipe.SellExperience)
	self.Context.Remotes.Get("Notify"):FireClient(player, recipe.DisplayName .. " sold +" .. recipe.SellPrice .. " coins")
end

function CustomerService:FindAvailableProduct(player)
	local bestRecipeId = nil
	local bestRecipe = nil
	local stock = self.ShelfService:GetStockSnapshot(player)

	for recipeId, recipe in pairs(RecipeData) do
		if (stock[recipeId] or 0) > 0 then
			if not bestRecipe or recipe.SellPrice > bestRecipe.SellPrice then
				bestRecipeId = recipeId
				bestRecipe = recipe
			end
		end
	end

	if bestRecipeId then
		self.ShelfService:TryRemoveStock(player, bestRecipeId)
	end

	return bestRecipeId, bestRecipe
end

return CustomerService
