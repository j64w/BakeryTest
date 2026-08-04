local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Shared.Modules.Enums)

local CarryService = {}

local carriedByPlayer = {}

function CarryService:Init(context)
	self.Context = context
	self.StateUpdated = context.Remotes.Get("StateUpdated")
end

function CarryService:Start()
	Players.PlayerRemoving:Connect(function(player)
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

function CarryService:SetCarriedItem(player, item)
	carriedByPlayer[player] = item
	self:SendSnapshot(player)
end

function CarryService:ClearCarriedItem(player)
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
