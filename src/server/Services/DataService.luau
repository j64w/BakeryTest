local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

local PlayerDataStore = DataStoreService:GetDataStore("BunnyBakeryData_v2")
local SAVE_COOLDOWN = 6
local lastSaveTime = {}

local DEFAULT_DATA = {
    Coins = 0,
    Experience = 0,
    Level = 1,
    UnlockedRecipes = { "bread_basic" },
    Upgrades = {
        Oven = { Speed = 1, Capacity = 1, Quality = 1 },
        Table = { Slots = 1, Speed = 1 },
        Shelf = { Capacity = 3 },
        Shop = { CustomerRate = 1 },
    },
    MissionProgress = {},
}

local playerData = {}

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = deepCopy(child)
    end
    return copy
end

local function ensureLeaderstats(player, data)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local coins = leaderstats:FindFirstChild("Coins")
    if not coins then
        coins = Instance.new("IntValue")
        coins.Name = "Coins"
        coins.Parent = leaderstats
    end
    coins.Value = data.Coins

    local level = leaderstats:FindFirstChild("Level")
    if not level then
        level = Instance.new("IntValue")
        level.Name = "Level"
        level.Parent = leaderstats
    end
    level.Value = data.Level
end

function DataService:Init(context)
    self.Context = context
end

function DataService:Start()
    Players.PlayerRemoving:Connect(function(player)
        self:SavePlayer(player)
        self:ReleasePlayer(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:LoadPlayer(player)
    end
end

function DataService:MigrateData(savedData)
    local migrated = deepCopy(DEFAULT_DATA)
    
    for key, value in pairs(savedData) do
        if migrated[key] ~= nil then
            if type(value) == "table" and type(migrated[key]) == "table" then
                for subKey, subValue in pairs(value) do
                    migrated[key][subKey] = subValue
                end
            else
                migrated[key] = value
            end
        end
    end
    
    return migrated
end

function DataService:LoadPlayer(player)
    if playerData[player] then return end
    
    local success, data = pcall(function()
        return PlayerDataStore:GetAsync("Player_" .. player.UserId)
    end)
    
    local loadedData
    if success and data then
        loadedData = self:MigrateData(data)
    else
        loadedData = deepCopy(DEFAULT_DATA)
        if not success then
            warn("DataStore load failed for " .. player.Name .. ": " .. tostring(data))
        end
    end
    
    playerData[player] = loadedData
    ensureLeaderstats(player, loadedData)
end

function DataService:SavePlayer(player)
    local data = playerData[player]
    if not data then return end
    
    local now = os.clock()
    if lastSaveTime[player] and (now - lastSaveTime[player]) < SAVE_COOLDOWN then
        return
    end
    lastSaveTime[player] = now
    
    local success, err = pcall(function()
        PlayerDataStore:SetAsync("Player_" .. player.UserId, data)
    end)
    
    if not success then
        warn("DataStore save failed for " .. player.Name .. ": " .. tostring(err))
    end
end

function DataService:ReleasePlayer(player)
    playerData[player] = nil
    lastSaveTime[player] = nil
end

function DataService:GetData(player)
    if not playerData[player] then
        self:LoadPlayer(player)
    end
    return playerData[player]
end

function DataService:SetValue(player, key, value)
    local data = self:GetData(player)
    data[key] = value

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats and (key == "Coins" or key == "Level") then
        local stat = leaderstats:FindFirstChild(key)
        if stat then
            stat.Value = value
        end
    end
end

-- Auto-save periódico
task.spawn(function()
    while true do
        task.wait(60)
        for player, _ in pairs(playerData) do
            if player.Parent then
                pcall(function() DataService:SavePlayer(player) end)
            end
        end
    end
end)

return DataService