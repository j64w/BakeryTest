local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

Remotes.Definitions = {
	RequestPrepareProduct = "RemoteEvent",
	RequestPressIngredient = "RemoteEvent",
	RequestCollectFromTable = "RemoteEvent",
	RequestStartOven = "RemoteEvent",
	RequestCollectFromOven = "RemoteEvent",
	RequestPlaceOnShelf = "RemoteEvent",
	RequestBuyRecipe = "RemoteEvent",
	StateUpdated = "RemoteEvent",
	Notify = "RemoteEvent",
}

function Remotes.GetFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	return folder
end

function Remotes.Ensure()
	local folder = Remotes.GetFolder()

	for name, className in pairs(Remotes.Definitions) do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
	end
end

function Remotes.Get(name)
	local folder = Remotes.GetFolder()
	return folder:WaitForChild(name)
end

return Remotes
