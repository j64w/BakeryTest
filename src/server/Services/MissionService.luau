local MissionService = {}

function MissionService:Init(context)
	self.Context = context
end

function MissionService:Start()
	self.Context.Events.Connect("ProductSold", function(_player, _recipeId, _coins, _experience)
		-- Post-MVP hook.
	end)
end

return MissionService
