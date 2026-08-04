-- Nuevo módulo: src/server/Modules/AntiCheat.luau
local AntiCheat = {}

function AntiCheat:ValidateDistance(player, part, maxDistance)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    
    if not root or not part or not part:IsA("BasePart") then
        return false
    end
    
    return (root.Position - part.Position).Magnitude <= maxDistance
end

function AntiCheat:ValidateDistanceContinuous(player, part, maxDistance, duration, callback)
    local startTime = os.clock()
    
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if os.clock() - startTime > duration then
            connection:Disconnect()
            callback(true)
            return
        end
        
        if not AntiCheat:ValidateDistance(player, part, maxDistance) then
            connection:Disconnect()
            callback(false, "Player moved too far")
        end
    end)
    
    return connection
end

return AntiCheat