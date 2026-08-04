local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RecipeData = require(ReplicatedStorage.Shared.Modules.RecipeData)

local RecipeController = {}

local player = Players.LocalPlayer

local catalog = {}
local unlockedLookup = {
	bread_basic = true,
}

local activePanel = nil
-- "prepare" | "computer" | nil — qué panel está abierto, para poder
-- refrescarlo en lugar de cerrarlo cuando llega un nuevo catálogo.
local activePanelType = nil

local function getPrompt(path)
	local current = Workspace

	for _, name in ipairs(path) do
		current = current:WaitForChild(name)
	end

	return current:WaitForChild("ProximityPrompt")
end

local function isUnlocked(recipeId)
	return unlockedLookup[recipeId] == true
end

local function clearPanel()
	if activePanel then
		activePanel:Destroy()
		activePanel = nil
	end

	activePanelType = nil
end

local function makeButton(parent, text, order)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Color3.fromRGB(255, 241, 222)
	button.BorderSizePixel = 0
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, 42)
	button.Font = Enum.Font.GothamMedium
	button.TextColor3 = Color3.fromRGB(72, 48, 36)
	button.TextSize = 15
	button.Text = text
	button.Parent = parent

	return button
end

local function buildLocalCatalog()
	local recipes = {}

	for recipeId, recipe in pairs(RecipeData) do
		table.insert(recipes, {
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

	table.sort(recipes, function(left, right)
		return left.UnlockCost < right.UnlockCost
	end)

	return recipes
end

function RecipeController:Init(context)
    self.Context = context
    -- Validar default
    self.Context.SelectedRecipeId = "bread_basic"
    catalog = buildLocalCatalog()
end

function RecipeController:Start()
	self.Context.Remotes.Get("StateUpdated").OnClientEvent:Connect(function(snapshotType, payload)
		if snapshotType == "RecipeCatalog" then
			self:ApplyCatalog(payload)
		end
	end)

	getPrompt({ "Bakery", "OfficeArea", "Computer_01" }).Triggered:Connect(function()
		self:OpenComputer()
	end)
end

function RecipeController:ApplyCatalog(payload)
	catalog = payload.Recipes or {}
	unlockedLookup = {}

	for _, recipeId in ipairs(payload.UnlockedRecipes or {}) do
		unlockedLookup[recipeId] = true
	end

	if not isUnlocked(self.Context.SelectedRecipeId) then
		self.Context.SelectedRecipeId = "bread_basic"
	end

	-- Si la computadora está abierta cuando llega un catálogo nuevo
	-- (por ejemplo, justo después de comprar algo), se refresca en lugar
	-- de cerrarse, para poder seguir comprando/eligiendo sin reabrir.
	if activePanelType == "computer" then
		self:OpenComputer()
	elseif activePanelType == "prepare" then
		self:OpenPrepareMenu()
	end
end

function RecipeController:CreatePanel(title)
	clearPanel()

	local gui = player:WaitForChild("PlayerGui"):WaitForChild("BunnysBakeryHUD")

	local frame = Instance.new("Frame")
	frame.Name = "RecipePanel"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(255, 250, 242)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(360, 320)
	frame.Parent = gui
	activePanel = frame

	local heading = Instance.new("TextLabel")
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.fromOffset(16, 10)
	heading.Size = UDim2.new(1, -56, 0, 32)
	heading.Font = Enum.Font.GothamBold
	heading.TextColor3 = Color3.fromRGB(72, 48, 36)
	heading.TextSize = 18
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.Text = title
	heading.Parent = frame

	local close = Instance.new("TextButton")
	close.BackgroundColor3 = Color3.fromRGB(239, 180, 166)
	close.BorderSizePixel = 0
	close.Position = UDim2.new(1, -42, 0, 10)
	close.Size = UDim2.fromOffset(28, 28)
	close.Font = Enum.Font.GothamBold
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(72, 48, 36)
	close.TextSize = 14
	close.Parent = frame
	close.Activated:Connect(clearPanel)

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(16, 54)
	list.Size = UDim2.new(1, -32, 1, -70)
	list.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	return list
end

function RecipeController:OpenPrepareMenu()
    local list = self:CreatePanel("Elegir producto")
    activePanelType = "prepare"
    
    local hasUnlockedRecipes = false
    
    for index, recipe in ipairs(catalog) do
        if isUnlocked(recipe.Id) then
            hasUnlockedRecipes = true
            -- ... crear botón ...
        end
    end
    
    -- Mostrar mensaje si no hay recetas desbloqueadas
    if not hasUnlockedRecipes then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Size = UDim2.new(1, 0, 0, 40)
        emptyLabel.Font = Enum.Font.GothamMedium
        emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        emptyLabel.TextSize = 14
        emptyLabel.Text = "No tienes recetas desbloqueadas"
        emptyLabel.Parent = list
    end
end

-- Computadora de productos: recetas ya desbloqueadas se pueden volver a
-- pedir tantas veces como se quiera sin cerrar el panel; las que faltan
-- se compran una sola vez (desbloqueo permanente).
function RecipeController:OpenComputer()
	local list = self:CreatePanel("Computadora de productos")
	activePanelType = "computer"

	for index, recipe in ipairs(catalog) do
		local owned = isUnlocked(recipe.Id)
		local text

		if owned then
			text = "Pedir " .. recipe.DisplayName .. " (desbloqueado)"
		else
			text = "Comprar " .. recipe.DisplayName .. " - " .. recipe.UnlockCost .. " monedas"
		end

		local button = makeButton(list, text, index)

		if owned then
			button.Activated:Connect(function()
				self.Context.SelectedRecipeId = recipe.Id
				self.Context.Remotes.Get("RequestPrepareProduct"):FireServer(recipe.Id)
				-- El panel se queda abierto a propósito: así se puede
				-- seguir pidiendo el mismo producto u otros sin tener
				-- que volver a acercarse a la computadora cada vez.
			end)
		else
			button.Activated:Connect(function()
				self.Context.Remotes.Get("RequestBuyRecipe"):FireServer(recipe.Id)
				-- No se cierra el panel: al desbloquearse, el catálogo se
				-- refresca solo (ver ApplyCatalog) y se puede comprar el
				-- siguiente producto sin reabrir la computadora.
			end)
		end
	end
end

return RecipeController
