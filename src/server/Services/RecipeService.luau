local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RecipeData = require(ReplicatedStorage.Shared.Modules.RecipeData)

local RecipeService = {}

local COMPUTER_PART_PATH = { "Bakery", "OfficeArea", "Computer_01" }

local function getComputerPart()
	local current = workspace

	for _, name in ipairs(COMPUTER_PART_PATH) do
		current = current:FindFirstChild(name)
		if not current then
			return nil
		end
	end

	return current
end

local function isPlayerNearComputer(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local computer = getComputerPart()

	if not root or not computer or not computer:IsA("BasePart") then
		return false
	end

	return (root.Position - computer.Position).Magnitude <= 14
end

function RecipeService:Init(context)
	self.Context = context
	self.DataService = context.Services.DataService
	self.StateUpdated = context.Remotes.Get("StateUpdated")
end

function RecipeService:Start()
	self.Context.Remotes.Get("RequestBuyRecipe").OnServerEvent:Connect(function(player, recipeId)
		self:RequestBuyRecipe(player, recipeId)
	end)

	self.Context.Events.Connect("PlayerReady", function(player)
		self:SendCatalog(player)
	end)
end

function RecipeService:GetRecipe(recipeId)
	return RecipeData[recipeId]
end

function RecipeService:GetCatalog()
	local catalog = {}

	for recipeId, recipe in pairs(RecipeData) do
		table.insert(catalog, {
			Id = recipeId,
			DisplayName = recipe.DisplayName,
			Rarity = recipe.Rarity,
			RequiredLevel = recipe.RequiredLevel,
			UnlockCost = recipe.UnlockCost,
			PrepTime = recipe.PrepTime,
			BakeTime = recipe.BakeTime,
			SellPrice = recipe.SellPrice,
			SellExperience = recipe.SellExperience,
			Ingredients = recipe.Ingredients,
		})
	end

	table.sort(catalog, function(left, right)
		return left.UnlockCost < right.UnlockCost
	end)

	return catalog
end

function RecipeService:IsRecipeUnlocked(player, recipeId)
	local data = self.DataService:GetData(player)

	for _, unlockedRecipeId in ipairs(data.UnlockedRecipes) do
		if unlockedRecipeId == recipeId then
			return true
		end
	end

	return false
end

function RecipeService:UnlockRecipe(player, recipeId)
	if self:IsRecipeUnlocked(player, recipeId) then
		return false
	end

	local data = self.DataService:GetData(player)
	table.insert(data.UnlockedRecipes, recipeId)
	self:SendCatalog(player)

	return true
end

function RecipeService:RequestBuyRecipe(player, recipeId)
	if type(recipeId) ~= "string" then
		return
	end

	if not isPlayerNearComputer(player) then
		return self:Notify(player, "Move closer to the computer")
	end

	local recipe = self:GetRecipe(recipeId)
	if not recipe then
		return self:Notify(player, "Unknown product")
	end

	if self:IsRecipeUnlocked(player, recipeId) then
		return self:Notify(player, "Already owned")
	end

	local data = self.DataService:GetData(player)

	if data.Level < recipe.RequiredLevel then
		return self:Notify(player, "Level too low")
	end

	if data.Coins < recipe.UnlockCost then
		return self:Notify(player, "Not enough coins")
	end

	self.DataService:SetValue(player, "Coins", data.Coins - recipe.UnlockCost)
	self:UnlockRecipe(player, recipeId)

	if self.Context.Services.EconomyService then
		self.Context.Services.EconomyService:SendSnapshot(player)
	end

	self:Notify(player, "Unlocked " .. recipe.DisplayName)
end

function RecipeService:SendCatalog(player)
	local data = self.DataService:GetData(player)
	self.StateUpdated:FireClient(player, "RecipeCatalog", {
		Recipes = self:GetCatalog(),
		UnlockedRecipes = data.UnlockedRecipes,
	})
end

function RecipeService:Notify(player, message)
	self.Context.Remotes.Get("Notify"):FireClient(player, message)
end

return RecipeService
