local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local controllersFolder = script:WaitForChild("Controllers")

local controllerOrder = {
	"UIController",
	"NotificationController",
	"StationFeedbackController",
	"RecipeController",
	"StationController",
}

local context = {
	Remotes = Remotes,
}

local controllers = {}

for _, controllerName in ipairs(controllerOrder) do
	local controller = require(controllersFolder:WaitForChild(controllerName))
	controllers[controllerName] = controller

	if controller.Init then
		controller:Init(context)
	end
end

context.Controllers = controllers

for _, controllerName in ipairs(controllerOrder) do
	local controller = controllers[controllerName]

	if controller.Start then
		controller:Start()
	end
end

print("Bunny's Bakery client started")
