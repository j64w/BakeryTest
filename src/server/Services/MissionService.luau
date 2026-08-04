local MissionService = {}

local MISSIONS = {
    {
        Id = "bake_5_bread",
        Title = "Panadero Novato",
        Description = "Hornea 5 panes básicos",
        Target = { Type = "Bake", RecipeId = "bread_basic", Amount = 5 },
        Reward = { Coins = 50, Experience = 20 }
    },
    {
        Id = "sell_10_items",
        Title = "Vendedor",
        Description = "Vende 10 productos",
        Target = { Type = "Sell", Amount = 10 },
        Reward = { Coins = 100, Experience = 30 }
    },
    {
        Id = "unlock_croissant",
        Title = "Chef Francés",
        Description = "Desbloquea el Croissant",
        Target = { Type = "Unlock", RecipeId = "croissant" },
        Reward = { Coins = 75, Experience = 25 }
    }
}

function MissionService:Init(context)
    self.Context = context
    self.DataService = context.Services.DataService
    self.EconomyService = context.Services.EconomyService
    self.ActiveMissions = {}
end

function MissionService:Start()
    self.Context.Events.Connect("PlayerReady", function(player)
        self:InitializePlayerMissions(player)
    end)
    
    self.Context.Events.Connect("ProductBaked", function(player, recipeId)
        self:TrackProgress(player, "Bake", recipeId)
    end)
    
    self.Context.Events.Connect("ProductSold", function(player, recipeId)
        self:TrackProgress(player, "Sell", recipeId)
    end)
    
    self.Context.Events.Connect("RecipeUnlocked", function(player, recipeId)
        self:TrackProgress(player, "Unlock", recipeId)
    end)
end

function MissionService:InitializePlayerMissions(player)
    local data = self.DataService:GetData(player)
    data.MissionProgress = data.MissionProgress or {}
    
    self.ActiveMissions[player] = {}
    for _, mission in ipairs(MISSIONS) do
        self.ActiveMissions[player][mission.Id] = {
            Progress = data.MissionProgress[mission.Id] or 0,
            Completed = data.MissionProgress[mission.Id .. "_completed"] or false
        }
    end
    
    self:SendSnapshot(player)
end

function MissionService:TrackProgress(player, actionType, recipeId)
    if not self.ActiveMissions[player] then return end
    
    for _, mission in ipairs(MISSIONS) do
        local progress = self.ActiveMissions[player][mission.Id]
        if progress and not progress.Completed then
            local target = mission.Target
            
            if target.Type == actionType then
                if not target.RecipeId or target.RecipeId == recipeId then
                    progress.Progress += 1
                    
                    if progress.Progress >= target.Amount then
                        self:CompleteMission(player, mission)
                    else
                        self:SendSnapshot(player)
                    end
                end
            end
        end
    end
end

function MissionService:CompleteMission(player, mission)
    local progress = self.ActiveMissions[player][mission.Id]
    progress.Completed = true
    
    local data = self.DataService:GetData(player)
    data.MissionProgress[mission.Id .. "_completed"] = true
    
    self.EconomyService:AddCoins(player, mission.Reward.Coins)
    self.EconomyService:AddExperience(player, mission.Reward.Experience)
    
    self.Context.Remotes.Get("Notify"):FireClient(
        player, 
        "Mission Complete: " .. mission.Title .. "! +" .. mission.Reward.Coins .. " coins"
    )
    
    self:SendSnapshot(player)
end

function MissionService:SendSnapshot(player)
    if not self.ActiveMissions[player] then return end
    
    local snapshot = {}
    for missionId, progress in pairs(self.ActiveMissions[player]) do
        snapshot[missionId] = progress
    end
    
    self.Context.Remotes.Get("StateUpdated"):FireClient(player, "MissionSnapshot", snapshot)
end

return MissionService