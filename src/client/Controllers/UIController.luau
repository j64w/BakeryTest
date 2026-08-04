local UIController = {}
local player = Players.LocalPlayer

function UIController:Init(context)
    self.Context = context
    self.Labels = {}  -- Mover a instancia
end

function UIController:Start()
    self:BuildUI()
    
    self.StateConnection = self.Context.Remotes.Get("StateUpdated").OnClientEvent:Connect(function(snapshotType, payload)
        self:ApplySnapshot(snapshotType, payload)
    end)
end

function UIController:BuildUI()
    if self.Gui then
        self.Gui:Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "BunnysBakeryHUD"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    self.Gui = gui
    
    self.Labels = {}
    self.Labels.Coins = self:MakeLabel(gui, "Coins", UDim2.fromOffset(16, 16), "Coins: 0")
    self.Labels.Level = self:MakeLabel(gui, "Level", UDim2.fromOffset(16, 54), "Level: 1")
    self.Labels.Experience = self:MakeLabel(gui, "Experience", UDim2.fromOffset(16, 92), "EXP: 0")
    self.Labels.Carry = self:MakeLabel(gui, "Carry", UDim2.fromOffset(16, 130), "Hands: empty")
    self.Labels.Shelf = self:MakeLabel(gui, "Shelf", UDim2.fromOffset(16, 168), "Shelf: 0/3")
end

function UIController:MakeLabel(parent, name, position, text)
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

function UIController:Destroy()
    if self.StateConnection then
        self.StateConnection:Disconnect()
        self.StateConnection = nil
    end
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
    self.Labels = {}
end

function UIController:ApplySnapshot(snapshotType, payload)
    if not self.Labels.Coins then return end  -- Validar que existen
    
    if snapshotType == "EconomySnapshot" then
        self.Labels.Coins.Text = "Coins: " .. tostring(payload.Coins)
        self.Labels.Level.Text = "Level: " .. tostring(payload.Level)
        -- ... resto
    end
end

return UIController