local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local StationFeedbackController = {}

local player = Players.LocalPlayer

local stationSnapshot = nil
local shelfSnapshot = nil
local widgets = {}
local previousState = {}
local ovenDoorOpen = false
local steamEmitter = nil
local hud = nil
local hudRows = {}

local STATIONS = {
	Table = {
		Path = { "Bakery", "PreparationArea", "Table_01" },
		Title = "Mesa",
		Idle = "Elegir producto",
		AwaitingIngredients = "Presiona los ingredientes",
		Working = "Amasando",
		Ready = "Masa lista",
		ReadyColor = Color3.fromRGB(92, 220, 128),
		WorkingColor = Color3.fromRGB(255, 196, 92),
		AwaitingColor = Color3.fromRGB(255, 224, 145),
	},
	Oven = {
		Path = { "Bakery", "BakingArea", "Oven_01" },
		Title = "Horno",
		Idle = "Esperando masa",
		Working = "Horneando",
		Ready = "Pan listo",
		ReadyColor = Color3.fromRGB(255, 238, 87),
		WorkingColor = Color3.fromRGB(255, 122, 72),
	},
	Shelf = {
		Path = { "Bakery", "DisplayArea", "Shelf_01" },
		Title = "Estante",
		Idle = "Sin stock",
		Ready = "En venta",
		ReadyColor = Color3.fromRGB(117, 202, 255),
		WorkingColor = Color3.fromRGB(172, 122, 78),
	},
}

local function getPart(path)
	local current = Workspace

	for _, name in ipairs(path) do
		current = current:WaitForChild(name)
	end

	return current
end

local function makeBillboard(part, title)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StationFeedback"
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 80
	billboard.Size = UDim2.fromOffset(200, 90)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	billboard.Parent = part

	local frame = Instance.new("Frame")
	frame.Name = "Card"
	frame.BackgroundColor3 = Color3.fromRGB(255, 250, 242)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Position = UDim2.fromOffset(10, 6)
	titleLabel.Size = UDim2.new(1, -20, 0, 22)
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(72, 48, 36)
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = frame

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamMedium
	status.Position = UDim2.fromOffset(10, 30)
	status.Size = UDim2.new(1, -20, 0, 20)
	status.TextColor3 = Color3.fromRGB(96, 67, 50)
	status.TextSize = 14
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = frame

	local countdown = Instance.new("TextLabel")
	countdown.BackgroundTransparency = 1
	countdown.Font = Enum.Font.GothamBlack
	countdown.Position = UDim2.fromOffset(10, 50)
	countdown.Size = UDim2.new(1, -20, 0, 26)
	countdown.TextColor3 = Color3.fromRGB(255, 122, 72)
	countdown.TextSize = 22
	countdown.TextXAlignment = Enum.TextXAlignment.Left
	countdown.Text = ""
	countdown.Parent = frame

	local barBack = Instance.new("Frame")
	barBack.BackgroundColor3 = Color3.fromRGB(226, 210, 194)
	barBack.BorderSizePixel = 0
	barBack.Position = UDim2.fromOffset(10, 78)
	barBack.Size = UDim2.new(1, -20, 0, 8)
	barBack.Parent = frame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBack

	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color3.fromRGB(255, 172, 87)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.fromScale(0, 1)
	bar.Parent = barBack

	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = bar

	return {
		Billboard = billboard,
		Card = frame,
		Status = status,
		Countdown = countdown,
		Bar = bar,
		Part = part,
		BaseColor = part.Color,
		BaseSize = part.Size,
	}
end

local function tweenPart(widget, color, scale)
	local part = widget.Part
	local targetSize = widget.BaseSize * scale

	TweenService:Create(part, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Color = color,
		Size = targetSize,
	}):Play()
end

-- "Pop" elástico + destello cuando una estación pasa a estar lista.
local function playReadyPop(widget)
	local card = widget.Card
	card.Size = UDim2.fromScale(1, 1)

	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(1.12, 0, 1.12, 0),
	}):Play()

	task.delay(0.45, function()
		if card and card.Parent then
			TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(1, 1),
			}):Play()
		end
	end)

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 238, 150))
	sparkle.Lifetime = NumberRange.new(0.4, 0.7)
	sparkle.Rate = 0
	sparkle.Speed = NumberRange.new(3, 6)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new(0.4)
	sparkle.Parent = widget.Part
	sparkle:Emit(24)
	game:GetService("Debris"):AddItem(sparkle, 1)
end

local function setPromptText(stationName, stationData)
	local widget = widgets[stationName]
	local prompt = widget and widget.Part:FindFirstChildOfClass("ProximityPrompt")

	if not prompt then
		return
	end

	if stationName == "Table" then
		-- Mientras los ingredientes están afuera, el prompt propio de la
		-- mesa ("Elegir") solo genera confusión al lado del prompt de cada
		-- ingrediente. Se oculta y vuelve a aparecer cuando corresponde.
		prompt.Enabled = stationData.State ~= "AwaitingIngredients"
		prompt.ActionText = stationData.State == "ReadyToCollect" and "Recoger" or "Elegir"
	elseif stationName == "Oven" then
		prompt.ActionText = stationData.State == "ReadyToCollect" and "Recoger" or "Hornear"
	elseif stationName == "Shelf" then
		prompt.ActionText = "Reponer"
	end
end

-- === Panel fijo en pantalla con los tiempos activos === --
-- Responde directamente a "no sé en cuánto tiempo está listo": siempre
-- visible en pantalla, sin depender de la cámara o la distancia.

local function buildHud()
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("BunnysBakeryHUD")

	local container = Instance.new("Frame")
	container.Name = "StationTimers"
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.BackgroundTransparency = 1
	container.Position = UDim2.new(0.5, 0, 1, -18)
	container.Size = UDim2.fromOffset(320, 90)
	container.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = container

	local function buildRow(name)
		local row = Instance.new("Frame")
		row.Name = name
		row.BackgroundColor3 = Color3.fromRGB(255, 250, 242)
		row.BackgroundTransparency = 0.05
		row.Size = UDim2.fromOffset(150, 64)
		row.Visible = false
		row.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = row

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamMedium
		label.Position = UDim2.fromOffset(10, 6)
		label.Size = UDim2.new(1, -20, 0, 18)
		label.TextColor3 = Color3.fromRGB(96, 67, 50)
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row

		local time = Instance.new("TextLabel")
		time.BackgroundTransparency = 1
		time.Font = Enum.Font.GothamBlack
		time.Position = UDim2.fromOffset(10, 24)
		time.Size = UDim2.new(1, -20, 0, 32)
		time.TextColor3 = Color3.fromRGB(255, 122, 72)
		time.TextSize = 26
		time.TextXAlignment = Enum.TextXAlignment.Left
		time.Parent = row

		return { Row = row, Label = label, Time = time }
	end

	hudRows.Table = buildRow("Table")
	hudRows.Oven = buildRow("Oven")

	return container
end

function StationFeedbackController:Init(context)
	self.Context = context
end

function StationFeedbackController:Start()
	for stationName, config in pairs(STATIONS) do
		local part = getPart(config.Path)
		widgets[stationName] = makeBillboard(part, config.Title)
	end

	self:SetupOvenExtras()

	hud = buildHud()

	self.Context.Remotes.Get("StateUpdated").OnClientEvent:Connect(function(snapshotType, payload)
		if snapshotType == "StationSnapshot" then
			stationSnapshot = payload
			self:ApplyImmediateStationState()
		elseif snapshotType == "ShelfSnapshot" then
			shelfSnapshot = payload
			self:ApplyShelfState()
		end
	end)

	if self.OvenDoor and self.OvenDoorClosedCFrame then
        self.OvenDoor.CFrame = self.OvenDoorClosedCFrame
        ovenDoorOpen = false
    end

	RunService.RenderStepped:Connect(function()
		self:UpdateProgress()
	end)

	player.CharacterRemoving:Connect(function()
        self:Cleanup()
    end)
end

function StationFeedbackController:Cleanup()
    -- Limpiar widgets
    for _, widget in pairs(widgets) do
        if widget.Billboard and widget.Billboard.Parent then
            widget.Billboard:Destroy()
        end
    end
    widgets = {}
    
    -- Limpiar HUD
    if hud and hud.Parent then
        hud:Destroy()
        hud = nil
    end
    hudRows = {}
    
    -- Limpiar partículas
    if steamEmitter and steamEmitter.Parent then
        steamEmitter:Destroy()
        steamEmitter = nil
    end
    
    -- Resetear estado
    stationSnapshot = nil
    shelfSnapshot = nil
    previousState = {}
    ovenDoorOpen = false
end


-- Puerta del horno (sube al hornear) + humo mientras cocina.
function StationFeedbackController:SetupOvenExtras()
	local ovenPart = getPart(STATIONS.Oven.Path)
	local door = ovenPart:FindFirstChild("Door")
	local attachment = ovenPart:FindFirstChild("SteamAttachment")

	self.OvenDoor = door
	self.OvenDoorClosedCFrame = door and door.CFrame

	if attachment then
		steamEmitter = Instance.new("ParticleEmitter")
		steamEmitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		steamEmitter.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235))
		steamEmitter.Lifetime = NumberRange.new(0.8, 1.4)
		steamEmitter.Rate = 0
		steamEmitter.Speed = NumberRange.new(1.5, 2.5)
		steamEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 1.6),
		})
		steamEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		steamEmitter.Parent = attachment
	end
end

function StationFeedbackController:SetOvenDoorOpen(open)
    if not self.OvenDoor or not self.OvenDoorClosedCFrame then
        return
    end
    
    -- Cancelar tween anterior si existe
    if self.CurrentDoorTween then
        self.CurrentDoorTween:Cancel()
    end
    
    ovenDoorOpen = open
    local targetCFrame = open 
        and (self.OvenDoorClosedCFrame + Vector3.new(0, 1.6, 0)) 
        or self.OvenDoorClosedCFrame
    
    self.CurrentDoorTween = TweenService:Create(
        self.OvenDoor, 
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
        { CFrame = targetCFrame }
    )
    self.CurrentDoorTween:Play()
end

function StationFeedbackController:ApplyImmediateStationState()
	if not stationSnapshot then
		return
	end

	for stationName, config in pairs(STATIONS) do
		if stationName ~= "Shelf" then
			local data = stationSnapshot[stationName]
			local widget = widgets[stationName]

			if data and widget then
				setPromptText(stationName, data)

				local justBecameReady = data.State == "ReadyToCollect" and previousState[stationName] ~= "ReadyToCollect"
				previousState[stationName] = data.State

				if stationName == "Table" then
					-- La bolita de cada ingrediente ya trae su propio
					-- cartel con nombre; mostrar además la tarjeta de la
					-- mesa encima se veía amontonado y con texto solapado.
					widget.Billboard.Enabled = data.State ~= "AwaitingIngredients"
				end

				if stationName == "Oven" then
					self:SetOvenDoorOpen(data.State == "Baking")

					if steamEmitter then
						steamEmitter.Rate = data.State == "Baking" and 12 or 0
					end
				end

				if data.State == "Idle" then
					widget.Status.Text = config.Idle
					widget.Countdown.Text = ""
					widget.Bar.Size = UDim2.fromScale(0, 1)
					tweenPart(widget, widget.BaseColor, 1)
				elseif data.State == "AwaitingIngredients" then
					widget.Status.Text = config.AwaitingIngredients or config.Working
					widget.Countdown.Text = "🧺"
					widget.Bar.Size = UDim2.fromScale(0, 1)
					tweenPart(widget, config.AwaitingColor or config.WorkingColor, 1.02)
				elseif data.State == "ReadyToCollect" then
					widget.Status.Text = config.Ready .. "!"
					widget.Countdown.Text = "✔"
					widget.Bar.Size = UDim2.fromScale(1, 1)
					tweenPart(widget, config.ReadyColor, 1.08)

					if justBecameReady then
						playReadyPop(widget)
					end
				else
					widget.Status.Text = config.Working .. "..."
					tweenPart(widget, config.WorkingColor, 1.03)
				end
			end
		end
	end
end

function StationFeedbackController:ApplyShelfState()
	local widget = widgets.Shelf
	if not widget or not shelfSnapshot then
		return
	end

	local total = shelfSnapshot.TotalStock or 0
	local capacity = shelfSnapshot.Capacity or 1
	local ratio = math.clamp(total / capacity, 0, 1)

	widget.Status.Text = total > 0 and ("Stock " .. total .. "/" .. capacity) or STATIONS.Shelf.Idle
	widget.Countdown.Text = ""
	widget.Bar.Size = UDim2.fromScale(ratio, 1)

	if total > 0 then
		tweenPart(widget, STATIONS.Shelf.ReadyColor, 1.03)
	else
		tweenPart(widget, widget.BaseColor, 1)
	end
end

function StationFeedbackController:UpdateProgress()
	if not stationSnapshot then
		return
	end

	local now = Workspace:GetServerTimeNow()

	for stationName, config in pairs(STATIONS) do
		if stationName ~= "Shelf" then
			local data = stationSnapshot[stationName]
			local widget = widgets[stationName]
			local hudRow = hudRows[stationName]

			if data and widget and data.EndsAt and data.Duration then
				local remaining = math.max(data.EndsAt - now, 0)
				local progress = math.clamp(1 - (remaining / data.Duration), 0, 1)
				local seconds = math.ceil(remaining)

				widget.Status.Text = config.Working .. "..."
				widget.Countdown.Text = seconds .. "s"
				widget.Bar.Size = UDim2.fromScale(progress, 1)

				if hudRow then
					hudRow.Row.Visible = true
					hudRow.Label.Text = config.Title .. " · " .. config.Working
					hudRow.Time.Text = seconds .. "s"
				end
			elseif hudRow then
				hudRow.Row.Visible = false
			end
		end
	end
end

return StationFeedbackController
