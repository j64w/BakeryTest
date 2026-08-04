local NotificationController = {}
local player = Players.LocalPlayer

local activeNotifications = {}
local MAX_NOTIFICATIONS = 5

function NotificationController:Show(message)
    local gui = player:WaitForChild("PlayerGui"):FindFirstChild("BunnysBakeryHUD")
    if not gui then return end
    
    -- Limitar cantidad
    while #activeNotifications >= MAX_NOTIFICATIONS do
        local oldest = table.remove(activeNotifications, 1)
        if oldest and oldest.Label and oldest.Label.Parent then
            oldest.Label:Destroy()
        end
    end
    
    local yOffset = 0.12 + (#activeNotifications * 0.055)
    
    local label = Instance.new("TextLabel")
    label.BackgroundColor3 = Color3.fromRGB(255, 223, 186)
    label.BorderSizePixel = 0
    label.Position = UDim2.fromScale(0.5, yOffset)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Size = UDim2.fromOffset(240, 36)
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(72, 48, 36)
    label.TextSize = 16
    label.Text = tostring(message)
    label.Parent = gui
    
    table.insert(activeNotifications, { Label = label, Time = os.clock() })
    
    -- Animación de entrada
    TweenService:Create(label, TweenInfo.new(0.25), {
        Position = UDim2.fromScale(0.5, yOffset - 0.025),
    }):Play()
    
    -- Auto-destruir con fade out
    task.delay(1.4, function()
        if label.Parent then
            local fadeTween = TweenService:Create(label, TweenInfo.new(0.3), {
                TextTransparency = 1,
                BackgroundTransparency = 1,
            })
            fadeTween:Play()
            fadeTween.Completed:Wait()
            if label.Parent then
                label:Destroy()
            end
        end
        
        -- Remover de la lista
        for i, notif in ipairs(activeNotifications) do
            if notif.Label == label then
                table.remove(activeNotifications, i)
                break
            end
        end
    end)
end

return NotificationController