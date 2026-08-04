local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Enums = require(ReplicatedStorage.Shared.Modules.Enums)
local IngredientData = require(ReplicatedStorage.Shared.Modules.IngredientData)

local StationService = {}

local stationStateByPlayer = {}

-- Tiempo de "mezclado" una vez que todos los ingredientes fueron
-- presionados, antes de que la masa quede lista para hornear.
local MIX_TIME = 1.2

local STATION_PARTS = {
	Table = { "Bakery", "PreparationArea", "Table_01" },
	Oven = { "Bakery", "BakingArea", "Oven_01" },
}

local function getDefaultState()
	return {
		Table = {
			State = Enums.TableState.Idle,
			RecipeId = nil,
			StartedAt = nil,
			EndsAt = nil,
			Duration = nil,
			Ingredients = nil,
			Pressed = nil,
		},
		Oven = {
			State = Enums.OvenState.Idle,
			RecipeId = nil,
			StartedAt = nil,
			EndsAt = nil,
			Duration = nil,
		},
	}
end

local function getWorkspacePart(path)
	local current = workspace

	for _, name in ipairs(path) do
		current = current:FindFirstChild(name)
		if not current then
			return nil
		end
	end

	return current
end

local function isPlayerNearPart(player, part)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root or not part or not part:IsA("BasePart") then
		return false
	end

	return (root.Position - part.Position).Magnitude <= 14
end

function StationService:Init(context)
	self.Context = context
	self.RecipeService = context.Services.RecipeService
	self.CarryService = context.Services.CarryService
	self.StateUpdated = context.Remotes.Get("StateUpdated")
end

function StationService:Start()
	self.Context.Remotes.Get("RequestPrepareProduct").OnServerEvent:Connect(function(player, recipeId)
		self:RequestPrepareProduct(player, recipeId)
	end)

	self.Context.Remotes.Get("RequestPressIngredient").OnServerEvent:Connect(function(player, index)
		self:RequestPressIngredient(player, index)
	end)

	self.Context.Remotes.Get("RequestCollectFromTable").OnServerEvent:Connect(function(player)
		self:RequestCollectFromTable(player)
	end)

	self.Context.Remotes.Get("RequestStartOven").OnServerEvent:Connect(function(player)
		self:RequestStartOven(player)
	end)

	self.Context.Remotes.Get("RequestCollectFromOven").OnServerEvent:Connect(function(player)
		self:RequestCollectFromOven(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:DespawnIngredients(player)
		stationStateByPlayer[player] = nil
	end)

	self.Context.Events.Connect("PlayerReady", function(player)
		self:GetState(player)
		self:SendSnapshot(player)
	end)
end

function StationService:GetState(player)
	if not stationStateByPlayer[player] then
		stationStateByPlayer[player] = getDefaultState()
	end

	return stationStateByPlayer[player]
end

-- === Preparación: los ingredientes aparecen sobre la mesa === --

function StationService:RequestPrepareProduct(player, recipeId)
	recipeId = recipeId or "bread_basic"

	local tablePart = getWorkspacePart(STATION_PARTS.Table)

	if not isPlayerNearPart(player, tablePart) then
		return self:Notify(player, "Acércate a la mesa")
	end

	if not self.CarryService:HasEmptyHands(player) then
		return self:Notify(player, "Tienes las manos ocupadas")
	end

	if not self.RecipeService:IsRecipeUnlocked(player, recipeId) then
		return self:Notify(player, "Receta bloqueada")
	end

	local recipe = self.RecipeService:GetRecipe(recipeId)
	if not recipe then
		return self:Notify(player, "Receta desconocida")
	end

	local state = self:GetState(player)
	if state.Table.State ~= Enums.TableState.Idle then
		return self:Notify(player, "La mesa está ocupada")
	end

	local ingredients = recipe.Ingredients or {}
	local pressed = table.create(#ingredients, false)

	state.Table.State = Enums.TableState.AwaitingIngredients
	state.Table.RecipeId = recipeId
	state.Table.Ingredients = ingredients
	state.Table.Pressed = pressed
	state.Table.StartedAt = nil
	state.Table.EndsAt = nil
	state.Table.Duration = nil

	self:SpawnIngredients(player, tablePart, ingredients)
	self:SendSnapshot(player)
	self:Notify(player, "Junta los ingredientes en la mesa")
end

-- Crea una parte física y presionable por cada ingrediente de la receta,
-- flotando sobre la mesa. Cada una tiene su propio ProximityPrompt.
function StationService:SpawnIngredients(player, tablePart, ingredients)
	self:DespawnIngredients(player)

	local rig = Instance.new("Folder")
	rig.Name = "Ingredients_" .. player.UserId
	rig.Parent = tablePart

	local count = math.max(#ingredients, 1)
	local spacing = 1.6
	local startX = -((count - 1) * spacing) / 2

	for index, ingredientId in ipairs(ingredients) do
		local info = IngredientData[ingredientId]
			or { DisplayName = ingredientId, Color = Color3.fromRGB(230, 230, 230) }

		local part = Instance.new("Part")
		part.Name = "Ingredient_" .. index
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(1.1, 1.1, 1.1)
		part.Color = info.Color
		part.Material = info.Material or Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = true
		part.Position = tablePart.Position
			+ Vector3.new(startX + (index - 1) * spacing, tablePart.Size.Y / 2 + 1.4, 0)
		part:SetAttribute("Index", index)
		part.Parent = rig

		-- Pequeña animación de "aparición" (pop-in) para notar que llegó
		-- un ingrediente nuevo a la mesa.
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(1.1, 1.1, 1.1),
		}):Play()

		-- Flotación suave permanente para que la mesa se vea viva.
		TweenService:Create(
			part,
			TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = part.Position + Vector3.new(0, 0.25, 0) }
		):Play()

		local billboard = Instance.new("BillboardGui")
		billboard.Adornee = part
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(120, 26)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 1.1, 0)
		billboard.Parent = part

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBold
		label.Text = info.DisplayName
		label.TextColor3 = Color3.fromRGB(72, 48, 36)
		label.TextStrokeTransparency = 0.4
		label.TextSize = 15
		label.Parent = billboard

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Presionar"
		prompt.ObjectText = info.DisplayName
		prompt.HoldDuration = 0.15
		prompt.MaxActivationDistance = 10
		prompt.Parent = part

		prompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer == player then
				self:RequestPressIngredient(player, index)
			end
		end)
	end
end

function StationService:DespawnIngredients(player)
	local tablePart = getWorkspacePart(STATION_PARTS.Table)
	local rig = tablePart and tablePart:FindFirstChild("Ingredients_" .. player.UserId)

	if rig then
		rig:Destroy()
	end
end

function StationService:RequestPressIngredient(player, index)
	local tablePart = getWorkspacePart(STATION_PARTS.Table)

	if not isPlayerNearPart(player, tablePart) then
		return self:Notify(player, "Acércate a la mesa")
	end

	local state = self:GetState(player)

	if state.Table.State ~= Enums.TableState.AwaitingIngredients then
		return
	end

	local pressed = state.Table.Pressed

	if not pressed or not index or index < 1 or index > #pressed then
		return
	end

	if pressed[index] then
		return
	end

	pressed[index] = true

	self:PlayIngredientPressFx(player, tablePart, index)

	local allPressed = true
	for _, done in ipairs(pressed) do
		if not done then
			allPressed = false
			break
		end
	end

	if allPressed then
		local recipeId = state.Table.RecipeId
		state.Table.State = Enums.TableState.Preparing
		state.Table.Ingredients = nil
		state.Table.Pressed = nil
		state.Table.StartedAt = workspace:GetServerTimeNow()
		state.Table.Duration = MIX_TIME
		state.Table.EndsAt = state.Table.StartedAt + MIX_TIME
		self:Notify(player, "¡Todo listo! Amasando...")

		task.delay(MIX_TIME, function()
			if not player.Parent then
				return
			end

			local currentState = self:GetState(player)
			if currentState.Table.State == Enums.TableState.Preparing and currentState.Table.RecipeId == recipeId then
				currentState.Table.State = Enums.TableState.ReadyToCollect
				currentState.Table.StartedAt = nil
				currentState.Table.EndsAt = nil
				currentState.Table.Duration = nil
				self:SendSnapshot(player)
				self.Context.Events.Fire("ProductPrepared", player, recipeId)
				self:Notify(player, "Masa lista en la mesa")
			end
		end)
	end

	self:SendSnapshot(player)
end

-- Animación al presionar un ingrediente: chispas + vuelo hacia el centro
-- de la mesa + encogimiento, y luego se destruye.
function StationService:PlayIngredientPressFx(player, tablePart, index)
	local rig = tablePart:FindFirstChild("Ingredients_" .. player.UserId)
	local part = rig and rig:FindFirstChild("Ingredient_" .. index)

	if not part then
		return
	end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new(part.Color)
	sparkle.Lifetime = NumberRange.new(0.25, 0.4)
	sparkle.Rate = 0
	sparkle.Speed = NumberRange.new(4, 7)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new(0.35)
	sparkle.Parent = part
	sparkle:Emit(18)

	local bowlPosition = tablePart.Position + Vector3.new(0, tablePart.Size.Y / 2 + 0.6, 0)

	TweenService:Create(part, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = bowlPosition,
		Size = Vector3.new(0.05, 0.05, 0.05),
		Transparency = 1,
	}):Play()

	Debris:AddItem(part, 0.4)
end

function StationService:RequestCollectFromTable(player)
	local tablePart = getWorkspacePart(STATION_PARTS.Table)

	if not isPlayerNearPart(player, tablePart) then
		return self:Notify(player, "Acércate a la mesa")
	end

	local state = self:GetState(player)

	if state.Table.State ~= Enums.TableState.ReadyToCollect then
		return self:Notify(player, "La masa no está lista")
	end

	if not self.CarryService:HasEmptyHands(player) then
		return self:Notify(player, "Tienes las manos ocupadas")
	end

	local recipeId = state.Table.RecipeId
	state.Table.State = Enums.TableState.Idle
	state.Table.RecipeId = nil
	state.Table.StartedAt = nil
	state.Table.EndsAt = nil
	state.Table.Duration = nil
	state.Table.Ingredients = nil
	state.Table.Pressed = nil

	self:DespawnIngredients(player)

	self.CarryService:SetCarriedItem(player, {
		State = Enums.CarryState.CarryingPrepared,
		RecipeId = recipeId,
	})

	self:SendSnapshot(player)
end

-- === Horno === --

function StationService:RequestStartOven(player)
    local ovenPart = getWorkspacePart(STATION_PARTS.Oven)
    
    if not isPlayerNearPart(player, ovenPart) then
        return self:Notify(player, "Acércate al horno")
    end
    
    -- Validación de estado
    local carriedItem = self.CarryService:GetCarriedItem(player)
    if not carriedItem or carriedItem.State ~= Enums.CarryState.CarryingPrepared then
        return self:Notify(player, "Necesitas masa preparada")
    end
    
    local state = self:GetState(player)
    if state.Oven.State ~= Enums.OvenState.Idle then
        return self:Notify(player, "El horno está ocupado")
    end
    
    -- Validar que sigue cerca antes de proceder
    if not isPlayerNearPart(player, ovenPart) then
        return self:Notify(player, "Te alejaste del horno")
    end
    
    -- Proceder con la acción
    state.Oven.State = Enums.OvenState.Baking
    -- ... resto del código
    
    -- Timer con verificación de distancia al final
    task.delay(recipe.BakeTime, function()
        if not player.Parent then return end
        
        if not isPlayerNearPart(player, ovenPart) then
            -- Cancelar: resetear horno
            local currentState = self:GetState(player)
            currentState.Oven = getDefaultState().Oven
            self:SendSnapshot(player)
            return self:Notify(player, "Horneado cancelado - te alejaste")
        end
        
        -- Completar
        local currentState = self:GetState(player)
        if currentState.Oven.State == Enums.OvenState.Baking then
            currentState.Oven.State = Enums.OvenState.ReadyToCollect
		if not player.Parent then
			return
		end

		local currentState = self:GetState(player)
		if currentState.Oven.State == Enums.OvenState.Baking then
			currentState.Oven.State = Enums.OvenState.ReadyToCollect
			currentState.Oven.StartedAt = nil
			currentState.Oven.EndsAt = nil
			currentState.Oven.Duration = nil
			self:SendSnapshot(player)
			self.Context.Events.Fire("ProductBaked", player, currentState.Oven.RecipeId)
			self:Notify(player, "El pan está listo en el horno")
		end
	end)
end

function StationService:RequestCollectFromOven(player)
	local ovenPart = getWorkspacePart(STATION_PARTS.Oven)

	if not isPlayerNearPart(player, ovenPart) then
		return self:Notify(player, "Acércate al horno")
	end

	local state = self:GetState(player)

	if state.Oven.State ~= Enums.OvenState.ReadyToCollect then
		return self:Notify(player, "El horno no está listo")
	end

	if not self.CarryService:HasEmptyHands(player) then
		return self:Notify(player, "Tienes las manos ocupadas")
	end

	local recipeId = state.Oven.RecipeId
	state.Oven.State = Enums.OvenState.Idle
	state.Oven.RecipeId = nil
	state.Oven.StartedAt = nil
	state.Oven.EndsAt = nil
	state.Oven.Duration = nil

	self.CarryService:SetCarriedItem(player, {
		State = Enums.CarryState.CarryingBaked,
		RecipeId = recipeId,
	})

	self:SendSnapshot(player)
end

function StationService:SendSnapshot(player)
	self.StateUpdated:FireClient(player, "StationSnapshot", self:GetState(player))
end

function StationService:Notify(player, message)
	self.Context.Remotes.Get("Notify"):FireClient(player, message)
end

return StationService
