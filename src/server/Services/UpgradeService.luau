local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StationData = require(ReplicatedStorage.Shared.Modules.StationData)

local UpgradeService = {}

local UPGRADE_COSTS = {
    Oven = {
        Speed = { Base = 50, Multiplier = 1.5 },
        Capacity = { Base = 100, Multiplier = 2.0 },
        Quality = { Base = 75, Multiplier = 1.8 }
    },
    Table = {
        Slots = { Base = 40, Multiplier = 1.5 },
        Speed = { Base = 30, Multiplier = 1.3 }
    },
    Shelf = {
        Capacity = { Base = 60, Multiplier = 1.6 }
    },
    Shop = {
        CustomerRate = { Base = 80, Multiplier = 2.0 }
    }
}

function UpgradeService:Init(context)
    self.Context = context
    self.DataService = context.Services.DataService
    self.EconomyService = context.Services.EconomyService
end

function UpgradeService:Start()
    self.Context.Remotes.Get("RequestUpgrade").OnServerEvent:Connect(function(player, category, stat)
        self:RequestUpgrade(player, category, stat)
    end)
    
    self.Context.Events.Connect("PlayerReady", function(player)
        self:SendSnapshot(player)
    end)
end

function UpgradeService:GetUpgradeCost(category, stat, currentLevel)
    local config = UPGRADE_COSTS[category] and UPGRADE_COSTS[category][stat]
    if not config then return nil end
    
    return math.floor(config.Base * (config.Multiplier ^ (currentLevel - 1)))
end

function UpgradeService:RequestUpgrade(player, category, stat)
    if type(category) ~= "string" or type(stat) ~= "string" then
        return
    end
    
    local data = self.DataService:GetData(player)
    local upgrades = data.Upgrades
    
    if not upgrades[category] or not upgrades[category][stat] then
        return self:Notify(player, "Invalid upgrade")
    end
    
    local currentLevel = upgrades[category][stat]
    local cost = self:GetUpgradeCost(category, stat, currentLevel)
    
    if not cost then
        return self:Notify(player, "Upgrade not available")
    end
    
    if data.Coins < cost then
        return self:Notify(player, "Not enough coins (need " .. cost .. ")")
    end
    
    -- Aplicar upgrade
    upgrades[category][stat] = currentLevel + 1
    self.DataService:SetValue(player, "Coins", data.Coins - cost)
    
    -- Aplicar efectos
    self:ApplyUpgradeEffects(player, category, stat, currentLevel + 1)
    
    self.EconomyService:SendSnapshot(player)
    self:SendSnapshot(player)
    self:Notify(player, category .. " " .. stat .. " upgraded to level " .. (currentLevel + 1) .. "!")
end

function UpgradeService:ApplyUpgradeEffects(player, category, stat, newLevel)
    -- Shelf capacity
    if category == "Shelf" and stat == "Capacity" then
        self.Context.Services.ShelfService:UpdateCapacity(player, newLevel)
    end
    
    -- Oven speed affects bake time (handled in StationService)
    -- Table speed affects prep time
    -- Customer rate affects spawn delays (handled in CustomerService)
end

function UpgradeService:SendSnapshot(player)
    local data = self.DataService:GetData(player)
    local snapshot = {}
    
    for category, stats in pairs(data.Upgrades) do
        snapshot[category] = {}
        for stat, level in pairs(stats) do
            snapshot[category][stat] = {
                Level = level,
                NextCost = self:GetUpgradeCost(category, stat, level)
            }
        end
    end
    
    self.Context.Remotes.Get("StateUpdated"):FireClient(player, "UpgradeSnapshot", snapshot)
end

function UpgradeService:Notify(player, message)
    self.Context.Remotes.Get("Notify"):FireClient(player, message)
end

return UpgradeService