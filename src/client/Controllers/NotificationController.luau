local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local NotificationController = {}

local player = Players.LocalPlayer

function NotificationController:Init(context)
	self.Context = context
end

function NotificationController:Start()
	self.Context.Remotes.Get("Notify").OnClientEvent:Connect(function(message)
		self:Show(message)
	end)
end

function NotificationController:Show(message)
	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("BunnysBakeryHUD")
	if not gui then
		return
	end

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(255, 223, 186)
	label.BorderSizePixel = 0
	label.Position = UDim2.fromScale(0.5, 0.15)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = UDim2.fromOffset(240, 36)
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(72, 48, 36)
	label.TextSize = 16
	label.Text = tostring(message)
	label.Parent = gui

	TweenService:Create(label, TweenInfo.new(0.25), {
		Position = UDim2.fromScale(0.5, 0.12),
	}):Play()

	task.delay(1.4, function()
		if label.Parent then
			label:Destroy()
		end
	end)
end

return NotificationController
