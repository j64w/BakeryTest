local Workspace = game:GetService("Workspace")

local StationController = {}

local latestStationSnapshot = nil

local function getPrompt(path)
	local current = Workspace

	for _, name in ipairs(path) do
		current = current:WaitForChild(name)
	end

	return current:WaitForChild("ProximityPrompt")
end

function StationController:Init(context)
	self.Context = context
end

function StationController:Start()
	self.Context.Remotes.Get("StateUpdated").OnClientEvent:Connect(function(snapshotType, payload)
		if snapshotType == "StationSnapshot" then
			latestStationSnapshot = payload
		end
	end)

	getPrompt({ "Bakery", "PreparationArea", "Table_01" }).Triggered:Connect(function()
		local tableState = latestStationSnapshot and latestStationSnapshot.Table and latestStationSnapshot.Table.State

		if tableState == "ReadyToCollect" then
			self.Context.Remotes.Get("RequestCollectFromTable"):FireServer()
		elseif tableState == nil or tableState == "Idle" then
			self.Context.Controllers.RecipeController:OpenPrepareMenu()
		end
		-- Si está "AwaitingIngredients" o "Preparing", el jugador debe usar
		-- los ProximityPrompt de cada ingrediente o esperar el amasado.
	end)

	getPrompt({ "Bakery", "BakingArea", "Oven_01" }).Triggered:Connect(function()
		local ovenState = latestStationSnapshot and latestStationSnapshot.Oven and latestStationSnapshot.Oven.State

		if ovenState == "ReadyToCollect" then
			self.Context.Remotes.Get("RequestCollectFromOven"):FireServer()
		else
			self.Context.Remotes.Get("RequestStartOven"):FireServer()
		end
	end)

	getPrompt({ "Bakery", "DisplayArea", "Shelf_01" }).Triggered:Connect(function()
		self.Context.Remotes.Get("RequestPlaceOnShelf"):FireServer()
	end)
end

return StationController
