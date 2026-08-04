local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
Remotes.Ensure()

local function createEventBus()
    local events = {}
    local connections = {}

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
            local conn = getEvent(name).Event:Connect(callback)
            table.insert(connections, conn)
            return conn
        end,
        Destroy = function()
            for _, conn in ipairs(connections) do
                conn:Disconnect()
            end
            for _, event in pairs(events) do
                event:Destroy()
            end
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

-- Init phase
for _, serviceName in ipairs(serviceOrder) do
    local service = services[serviceName]
    if service.Init then
        service:Init(context)
    end
end

-- Connect PlayerAdded BEFORE starting services
local function onPlayerAdded(player)
    task.defer(function()
        services.DataService:LoadPlayer(player)
        context.Events.Fire("PlayerReady", player)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Start phase
for _, serviceName in ipairs(serviceOrder) do
    local service = services[serviceName]
    if service.Start then
        service:Start()
    end
end

-- Process already-connected players
for _, player in ipairs(Players:GetPlayers()) do
    task.defer(onPlayerAdded, player)
end

print("Bunny's Bakery server started")