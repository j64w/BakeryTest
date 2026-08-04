local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Shared.Modules.Enums)
local RecipeData = require(ReplicatedStorage.Shared.Modules.RecipeData)

local CarryService = {}

local carriedByPlayer = {}

local DOUGH_COLOR = Color3.fromRGB(235, 214, 173)

-- Crea la Tool que representa físicamente lo que el jugador está
-- cargando (masa cruda o producto horneado), para que aparezca en su
-- inventario/mano en vez de ser solo un estado invisible.
local function buildTool(item, recipe)
	local isBaked = item.State == Enums.CarryState.CarryingBaked

	local tool = Instance.new("Tool")
	tool.Name = isBaked and recipe.DisplayName or (recipe.DisplayName .. " (masa)")
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = isBaked and ("Llevas " .. recipe.DisplayName .. ", listo para vender")
		or ("Llevas masa de " .. recipe.DisplayName .. ", falta hornear")

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Ball
	handle.Size = Vector3.new(0.9, 0.9, 0.9)
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Color = isBaked and (recipe.Color or Color3.fromRGB(214, 170, 110)) or DOUGH_COLOR
	handle.Parent = tool

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = handle
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(140, 24)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	billboard.Parent = handle

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = tool.Name
	label.TextColor3 = Color3.fromRGB(72, 48, 36)
	label.TextStrokeTransparency = 0.4
	label.TextSize = 13
	label.Parent = billboard

	return tool
end

function CarryService:Init(context)
	self.Context = context
	self.StateUpdated = context.Remotes.Get("StateUpdated")
end

function CarryService:Start()
	Players.PlayerRemoving:Connect(function(player)
		self:DestroyTool(player)
		carriedByPlayer[player] = nil
	end)

	self.Context.Events.Connect("PlayerReady", function(player)
		self:SendSnapshot(player)
	end)
end

function CarryService:GetCarriedItem(player)
	return carriedByPlayer[player]
end

function CarryService:HasEmptyHands(player)
	return carriedByPlayer[player] == nil
end

function CarryService:DestroyTool(player)
	local existing = carriedByPlayer[player]

	if existing and existing.Tool then
		existing.Tool:Destroy()
		existing.Tool = nil
	end
end

function CarryService:SetCarriedItem(player, item)
	self:DestroyTool(player)

	local recipe = RecipeData[item.RecipeId]

	if recipe then
		local backpack = player:FindFirstChild("Backpack")
		local tool = buildTool(item, recipe)
		tool.Parent = backpack or player

		item.Tool = tool

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			-- Se equipa solo para que se note de inmediato en la mano,
			-- en vez de quedar escondido en el inventario.
			humanoid:EquipTool(tool)
		end
	end

	carriedByPlayer[player] = item
	self:SendSnapshot(player)
end

function CarryService:ClearCarriedItem(player)
	self:DestroyTool(player)
	carriedByPlayer[player] = nil
	self:SendSnapshot(player)
end

function CarryService:SendSnapshot(player)
	local item = carriedByPlayer[player]

	self.StateUpdated:FireClient(player, "CarrySnapshot", {
		State = item and item.State or Enums.CarryState.EmptyHands,
		RecipeId = item and item.RecipeId or nil,
	})
end

return CarryService
