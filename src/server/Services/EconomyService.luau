local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelData = require(ReplicatedStorage.Shared.Modules.LevelData)

local EconomyService = {}

function EconomyService:Init(context)
	self.Context = context
	self.DataService = context.Services.DataService
	self.StateUpdated = context.Remotes.Get("StateUpdated")
end

function EconomyService:Start()
	self.Context.Events.Connect("PlayerReady", function(player)
		self:SendSnapshot(player)
	end)
end

function EconomyService:AddCoins(player, amount)
	local data = self.DataService:GetData(player)
	self.DataService:SetValue(player, "Coins", data.Coins + amount)
	self:SendSnapshot(player)
end

function EconomyService:AddExperience(player, amount)
	local data = self.DataService:GetData(player)
	local newExperience = data.Experience + amount
	local newLevel = self:GetLevelForExperience(newExperience)

	self.DataService:SetValue(player, "Experience", newExperience)

	if newLevel ~= data.Level then
		self.DataService:SetValue(player, "Level", newLevel)
		self.Context.Events.Fire("LevelChanged", player, newLevel)
		self.Context.Remotes.Get("Notify"):FireClient(player, "Level " .. tostring(newLevel) .. "!")
	end

	self:SendSnapshot(player)
end

function EconomyService:GetLevelForExperience(experience)
    local bestLevel = 1
    
    -- Convertir a array ordenado
    local levels = {}
    for level, req in pairs(LevelData) do
        table.insert(levels, { Level = level, Required = req })
    end
    
    table.sort(levels, function(a, b) return a.Level < b.Level end)
    
    for _, entry in ipairs(levels) do
        if experience >= entry.Required then
            bestLevel = entry.Level
        else
            break
        end
    end
    
    return bestLevel
end

function EconomyService:SendSnapshot(player)
	local data = self.DataService:GetData(player)

	self.StateUpdated:FireClient(player, "EconomySnapshot", {
		Coins = data.Coins,
		Experience = data.Experience,
		Level = data.Level,
		NextLevelExperience = LevelData[data.Level + 1],
	})
end

return EconomyService
