local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
Remotes.Ensure()

local function createEventBus()
	local events = {}

	local function getEvent(name)
		if not events[name] then
			events[name] = Instance.new("BindableEvent")
		end

		return events[name]
	end

	return {
		Fire = function(name, ...)
			getEvent(name):Fire(...)
		end,

		Connect = function(name, callback)
			return getEvent(name).Event:Connect(callback)
		end,
	}
end

local servicesFolder = script:WaitForChild("Services")

local serviceOrder = {
	"DataService",
	"RecipeService",
	"EconomyService",
	"CarryService",
	"StationService",
	"ShelfService",
	"CustomerService",
	"MissionService",
	"UpgradeService",
}

local services = {}

for _, serviceName in ipairs(serviceOrder) do
	services[serviceName] = require(servicesFolder:WaitForChild(serviceName))
end

local context = {
	Events = createEventBus(),
	Remotes = Remotes,
	Services = services,
}

for _, serviceName in ipairs(serviceOrder) do
	local service = services[serviceName]
	if service.Init then
		service:Init(context)
	end
end

for _, serviceName in ipairs(serviceOrder) do
	local service = services[serviceName]
	if service.Start then
		service:Start()
	end
end

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		services.DataService:LoadPlayer(player)
		context.Events.Fire("PlayerReady", player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		services.DataService:LoadPlayer(player)
		context.Events.Fire("PlayerReady", player)
	end)
end

print("Bunny's Bakery server started")
