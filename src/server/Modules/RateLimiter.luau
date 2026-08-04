local RateLimiter = {}
local cooldowns = {}
local MAX_VIOLATIONS = 10

function RateLimiter:CanProceed(player, actionId, cooldownSeconds)
    local key = player.UserId .. "_" .. actionId
    local now = os.clock()
    
    cooldowns[key] = cooldowns[key] or { lastTime = 0, violations = 0 }
    local record = cooldowns[key]
    
    -- Anti-spam: si viola muchas veces, bloquear temporalmente
    if record.violations >= MAX_VIOLATIONS then
        if now - record.lastTime < 30 then
            return false, "Rate limit exceeded"
        else
            record.violations = 0
        end
    end
    
    if record.lastTime and (now - record.lastTime) < cooldownSeconds then
        record.violations += 1
        return false, "Too fast"
    end
    
    record.lastTime = now
    return true
end

function RateLimiter:CleanupPlayer(player)
    local uid = tostring(player.UserId)
    for key, _ in pairs(cooldowns) do
        if string.sub(key, 1, #uid) == uid then
            cooldowns[key] = nil
        end
    end
end

return RateLimiter