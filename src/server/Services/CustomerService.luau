local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local RecipeData = require(ReplicatedStorage.Shared.Modules.RecipeData)
local StationData = require(ReplicatedStorage.Shared.Modules.StationData)

local CustomerService = {}

local CUSTOMER_PATHS = {
	Entrance = { "Bakery", "CustomerArea", "EntrancePoint" },
	Exit = { "Bakery", "CustomerArea", "ExitPoint" },
	Register = { "Bakery", "CustomerArea", "Register_01" },
	Shelf = { "Bakery", "DisplayArea", "Shelf_01" },
}

local MAX_CUSTOMERS_PER_PLAYER = 2
local MAX_ITEMS_PER_ORDER = 3
local MOVE_TIMEOUT = 12
local BROWSE_TIME = 1.4
local FRIEND_CACHE_SECONDS = 300

-- Cuánto se espera al jugador en cada paso manual antes de resolverlo
-- solo, para que un cliente nunca quede trabado para siempre si el
-- jugador está ocupado en otra parte.
local ATTEND_CLICK_TIMEOUT = 45
local BAG_CLICK_TIMEOUT = 60
local PAY_PROMPT_TIMEOUT = 45
local REGISTER_WAIT_TIMEOUT = 90

local friendCache = {}
local activeCountByPlayer = {}
local registerBusyByPlayer = {}

local function getPart(path)
	local current = Workspace

	for _, name in ipairs(path) do
		current = current and current:FindFirstChild(name)
	end

	return current
end

local function getBagTemplate()
	local modelsFolder = ReplicatedStorage:FindFirstChild("Models")
	return modelsFolder and modelsFolder:FindFirstChild("Bag")
end

-- === Apariencia: intenta usar el avatar de un amigo real del jugador === --

local function fetchFriendIds(player)
	local ids = {}

	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)

	if ok and pages then
		local pageOk, page = pcall(function()
			return pages:GetCurrentPage()
		end)

		if pageOk and page then
			for _, entry in ipairs(page) do
				table.insert(ids, entry.Id)
			end
		end
	end

	return ids
end

local function getFriendPool(player)
	local cached = friendCache[player]

	if not cached or (os.clock() - cached.FetchedAt) > FRIEND_CACHE_SECONDS then
		cached = {
			Ids = fetchFriendIds(player),
			FetchedAt = os.clock(),
		}
		friendCache[player] = cached
	end

	return cached.Ids
end

-- Avatar clásico genérico con colores al azar. Es la red de seguridad
-- para cuando no se puede leer ningún avatar real (por ejemplo, en Play
-- Solo dentro de Studio, donde el "jugador" de prueba no existe de
-- verdad en Roblox y las consultas de amigos/avatar fallan).
local function getFallbackDescription()
	local description = Instance.new("HumanoidDescription")

	local skinTones = {
		Color3.fromRGB(255, 213, 170),
		Color3.fromRGB(196, 142, 96),
		Color3.fromRGB(140, 96, 66),
		Color3.fromRGB(255, 224, 189),
	}

	local skin = skinTones[math.random(1, #skinTones)]
	description.HeadColor = skin
	description.LeftArmColor = skin
	description.RightArmColor = skin
	description.TorsoColor = Color3.fromRGB(math.random(120, 230), math.random(120, 230), math.random(120, 230))

	local legColor = Color3.fromRGB(math.random(80, 200), math.random(80, 200), math.random(80, 200))
	description.LeftLegColor = legColor
	description.RightLegColor = legColor

	return description
end

local function getCustomerDescription(player)
	local friendIds = getFriendPool(player)

	if #friendIds > 0 then
		local candidateId = friendIds[math.random(1, #friendIds)]

		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(candidateId)
		end)

		if ok and description then
			return description
		end
	end

	return getFallbackDescription()
end

local function buildCustomerModel(player)
	local description = getCustomerDescription(player)

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)

	if not ok or not model then
		warn("[CustomerService] No se pudo crear el modelo del cliente: " .. tostring(model))
		return nil
	end

	local setupOk, setupErr = pcall(function()
		model.Name = "Customer_" .. player.Name

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayName = "Cliente"
			humanoid.WalkSpeed = 12
		end

		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)

	if not setupOk then
		warn("[CustomerService] Error preparando al cliente: " .. tostring(setupErr))
		model:Destroy()
		return nil
	end

	return model
end

-- Cartelito flotante reutilizable para pedirle una acción al jugador
-- (atender al cliente, esperar mientras arma el pedido, etc.).
local function attachHint(part, text)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Hint"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(160, 30)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(255, 250, 242)
	label.BackgroundTransparency = 0.05
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(72, 48, 36)
	label.TextSize = 15
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	return billboard
end

-- Agrega un ClickDetector a cada BasePart del modelo (personaje o bolsa)
-- para que se pueda hacer click en cualquier parte visible de él, y
-- conecta todos a un único callback filtrado por jugador.
local function makeClickable(model, player, onClicked)
	local triggered = false

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 32
			clickDetector.Parent = part

			clickDetector.MouseClick:Connect(function(triggeringPlayer)
				if triggeringPlayer == player and not triggered then
					triggered = true
					onClicked()
				end
			end)
		end
	end
end

-- === Movimiento === --

local function moveTo(humanoid, position, timeout)
	local finished = false

	local connection = humanoid.MoveToFinished:Connect(function()
		finished = true
	end)

	humanoid:MoveTo(position)

	local elapsed = 0
	while not finished and elapsed < timeout and humanoid.Parent do
		task.wait(0.1)
		elapsed += 0.1
	end

	connection:Disconnect()

	return finished
end

-- Punto justo delante de una parte (mirando desde donde viene el
-- cliente), para que se quede parado frente a ella en vez de
-- caminar encima o a través suyo.
local function getStandPoint(targetPart, fromZ, margin)
	local halfDepth = targetPart.Size.Z / 2
	local sign = fromZ < targetPart.Position.Z and -1 or 1

	return targetPart.Position + Vector3.new(math.random(-3, 3) * 0.3, 0, sign * (halfDepth + margin))
end

function CustomerService:Init(context)
	self.Context = context
	self.ShelfService = context.Services.ShelfService
	self.EconomyService = context.Services.EconomyService
end

function CustomerService:Start()
	local customersFolder = Instance.new("Folder")
	customersFolder.Name = "Customers"
	customersFolder.Parent = Workspace
	self.CustomersFolder = customersFolder

	local register = getPart(CUSTOMER_PATHS.Register)
	if register then
		local payPrompt = Instance.new("ProximityPrompt")
		payPrompt.Name = "PayPrompt"
		payPrompt.ActionText = "Cobrar"
		payPrompt.ObjectText = "Caja"
		payPrompt.HoldDuration = 0.2
		payPrompt.MaxActivationDistance = 10
		payPrompt.Enabled = false
		payPrompt.Parent = register
		self.PayPrompt = payPrompt
	else
		warn("[CustomerService] No se encontró Register_01: revisa Workspace.Bakery.CustomerArea")
	end

	Players.PlayerRemoving:Connect(function(player)
		friendCache[player] = nil
		activeCountByPlayer[player] = nil
		registerBusyByPlayer[player] = nil
	end)

	task.spawn(function()
		task.wait(StationData.Customers.FirstSpawnDelay)

		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				self:TrySpawnCustomer(player)
			end

			task.wait(math.random(StationData.Customers.MinSpawnDelay, StationData.Customers.MaxSpawnDelay))
		end
	end)
end

-- Elige el mejor producto con stock y reserva 1-3 unidades para el
-- pedido del cliente (si comprás 2 panes, después aparecen 2 bolsas).
function CustomerService:ReserveOrder(player)
	local recipeId, recipe = self:FindAvailableProduct(player)

	if not recipeId or not recipe then
		return nil
	end

	local stock = self.ShelfService:GetStockSnapshot(player)
	local available = stock[recipeId] or 0
	local desired = math.random(1, math.min(MAX_ITEMS_PER_ORDER, available))

	local reserved = 0
	for _ = 1, desired do
		if self.ShelfService:TryRemoveStock(player, recipeId) then
			reserved += 1
		else
			break
		end
	end

	if reserved == 0 then
		return nil
	end

	return { RecipeId = recipeId, Recipe = recipe, Quantity = reserved }
end

function CustomerService:TrySpawnCustomer(player)
	local activeCount = activeCountByPlayer[player] or 0
	if activeCount >= MAX_CUSTOMERS_PER_PLAYER then
		return
	end

	local order = self:ReserveOrder(player)
	if not order then
		return
	end

	print(
		"[CustomerService] Generando cliente para "
			.. player.Name
			.. " por "
			.. order.Quantity
			.. "x "
			.. order.Recipe.DisplayName
	)

	activeCountByPlayer[player] = activeCount + 1

	task.spawn(function()
		self:RunCustomerVisit(player, order)
		activeCountByPlayer[player] = math.max((activeCountByPlayer[player] or 1) - 1, 0)
	end)
end

-- Recorrido completo: entra, camina hasta el estante, se para delante
-- de la caja (sin atravesarla) y espera. El jugador tiene que:
--  1) hacerle click al cliente para atenderlo,
--  2) hacerle click a cada bolsa de su pedido,
--  3) cobrarle con el ProximityPrompt de la caja.
function CustomerService:RunCustomerVisit(player, order)
	local entrance = getPart(CUSTOMER_PATHS.Entrance)
	local exit = getPart(CUSTOMER_PATHS.Exit)
	local register = getPart(CUSTOMER_PATHS.Register)
	local shelf = getPart(CUSTOMER_PATHS.Shelf)

	if not entrance or not exit or not register or not shelf then
		warn("[CustomerService] Falta alguna parte de CustomerArea/DisplayArea en el mapa (revisa Workspace.Bakery)")
		self:CompleteSale(player, order)
		return
	end

	local model = buildCustomerModel(player)
	if not model then
		self:CompleteSale(player, order)
		return
	end

	model:PivotTo(CFrame.new(entrance.Position))
	model.Parent = self.CustomersFolder

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		model:Destroy()
		self:CompleteSale(player, order)
		return
	end

	Debris:AddItem(model, (MOVE_TIMEOUT + ATTEND_CLICK_TIMEOUT + BAG_CLICK_TIMEOUT + PAY_PROMPT_TIMEOUT) * 1.2)

	-- 1) Camina hasta el estante a "revisar" el producto.
	moveTo(humanoid, getStandPoint(shelf, entrance.Position.Z, 1.5), MOVE_TIMEOUT)
	if humanoid.Parent then
		task.wait(BROWSE_TIME)
	end

	-- Solo un cliente ocupa la caja a la vez; el resto espera cerca del
	-- estante hasta que se libere.
	local waited = 0
	while registerBusyByPlayer[player] and waited < REGISTER_WAIT_TIMEOUT and humanoid.Parent do
		task.wait(0.3)
		waited += 0.3
	end
	registerBusyByPlayer[player] = true

	-- 2) Camina hasta pararse DELANTE de la caja, no encima ni a través.
	moveTo(humanoid, getStandPoint(register, shelf.Position.Z, 1.8), MOVE_TIMEOUT)

	if humanoid.Parent then
		self:WaitToBeAttended(player, model)
	end

	if humanoid.Parent then
		self:WaitForBags(player, register, order)
	end

	if humanoid.Parent then
		self:WaitForPayment(player, order)
	else
		self:CompleteSale(player, order)
	end

	registerBusyByPlayer[player] = false

	if humanoid.Parent then
		moveTo(humanoid, exit.Position, MOVE_TIMEOUT)
	end

	if model.Parent then
		model:Destroy()
	end
end

-- Paso 1: el cliente espera parado con un cartel de "Click para
-- atender" hasta que el jugador le hace click.
function CustomerService:WaitToBeAttended(player, model)
	local anchor = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	local hint = anchor and attachHint(anchor, "🛎 Click para atender")

	local attended = false
	makeClickable(model, player, function()
		attended = true
	end)

	local elapsed = 0
	while not attended and elapsed < ATTEND_CLICK_TIMEOUT and model.Parent do
		task.wait(0.1)
		elapsed += 0.1
	end

	if hint then
		hint:Destroy()
	end
end

-- Paso 2: aparecen tantas bolsas como unidades compró, apoyadas sobre
-- la caja. Cada click hace "pop" a una bolsa hasta que no quede
-- ninguna.
function CustomerService:WaitForBags(player, register, order)
	local bagTemplate = getBagTemplate()

	if not bagTemplate then
		warn("[CustomerService] No se encontró ReplicatedStorage.Models.Bag; se omite el paso de bolsas")
		return
	end

	local bagsFolder = Instance.new("Folder")
	bagsFolder.Name = "Bags"
	bagsFolder.Parent = register

	local remaining = order.Quantity
	local spacing = 1.4
	local startX = -((order.Quantity - 1) * spacing) / 2
	local baseHeight = register.Size.Y / 2 + 0.6

	for index = 1, order.Quantity do
		local bag = bagTemplate:Clone()
		bag.Parent = bagsFolder

		local targetPosition = register.Position
			+ Vector3.new(startX + (index - 1) * spacing, baseHeight, -(register.Size.Z / 2 + 0.4))

		local ok = pcall(function()
			bag:PivotTo(CFrame.new(targetPosition))
		end)

		if not ok then
			local basePart = bag:FindFirstChildWhichIsA("BasePart", true)
			if basePart then
				basePart.CFrame = CFrame.new(targetPosition)
			end
		end

		for _, part in ipairs(bag:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
		end

		-- Pequeño "pop-in" y flotación, en línea con el resto de los
		-- objetos interactuables del juego (ingredientes, etc.).
		local basePart = bag.PrimaryPart or bag:FindFirstChildWhichIsA("BasePart", true)
		if basePart then
			TweenService:Create(
				basePart,
				TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ CFrame = basePart.CFrame + Vector3.new(0, 0.2, 0) }
			):Play()
		end

		makeClickable(bag, player, function()
			remaining -= 1

			for _, part in ipairs(bag:GetDescendants()) do
				if part:IsA("BasePart") then
					TweenService:Create(part, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Transparency = 1,
						Size = part.Size * 0.2,
					}):Play()
				end
			end

			Debris:AddItem(bag, 0.3)
		end)
	end

	local elapsed = 0
	while remaining > 0 and elapsed < BAG_CLICK_TIMEOUT and register.Parent do
		task.wait(0.1)
		elapsed += 0.1
	end

	if bagsFolder.Parent then
		bagsFolder:Destroy()
	end
end

-- Paso 3: se habilita el ProximityPrompt de la caja para cobrar el
-- total del pedido.
function CustomerService:WaitForPayment(player, order)
	local prompt = self.PayPrompt

	if not prompt then
		self:CompleteSale(player, order)
		return
	end

	local total = order.Recipe.SellPrice * order.Quantity
	prompt.ObjectText = order.Quantity .. "x " .. order.Recipe.DisplayName .. " · $" .. total
	prompt.Enabled = true

	local paid = false
	local connection = prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player and not paid then
			paid = true
		end
	end)

	local elapsed = 0
	while not paid and elapsed < PAY_PROMPT_TIMEOUT do
		task.wait(0.1)
		elapsed += 0.1
	end

	connection:Disconnect()
	prompt.Enabled = false

	self:CompleteSale(player, order)
end

function CustomerService:CompleteSale(player, order)
	local totalCoins = order.Recipe.SellPrice * order.Quantity
	local totalExperience = order.Recipe.SellExperience * order.Quantity

	self.EconomyService:AddCoins(player, totalCoins)
	self.EconomyService:AddExperience(player, totalExperience)
	self.Context.Events.Fire("ProductSold", player, order.RecipeId, totalCoins, totalExperience)
	self.Context.Remotes.Get("Notify"):FireClient(
		player,
		order.Quantity .. "x " .. order.Recipe.DisplayName .. " cobrado +" .. totalCoins .. " monedas"
	)
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

	return bestRecipeId, bestRecipe
end

return CustomerService
