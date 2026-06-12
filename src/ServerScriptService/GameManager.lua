-- File: src/ServerScriptService/GameManager.lua
--!strict
-- FULLY INTEGRATED GameManager with HazardSpawner and CollisionDetector
-- Rojo [ModuleScript] Architecture: https://rojo.space/docs/v7/project-format

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

-- [UPDATED]: Added WaitForChild to prevent race conditions during server startup.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Services = script.Parent:WaitForChild("Services")

-- [UPDATED]: Explicitly waiting for modules before requiring them ensures they exist in the DataModel.
local Config = require(Shared:WaitForChild("Config") :: ModuleScript)
local Types = require(Shared:WaitForChild("Types") :: ModuleScript)
local SlopeGenerator = require(Modules:WaitForChild("SlopeGenerator") :: ModuleScript)
local SlopeBuilder = require(Modules:WaitForChild("SlopeBuilder") :: ModuleScript)
local HazardSpawner = require(Services:WaitForChild("HazardSpawner") :: ModuleScript)
local HazardCollisionDetector = require(Services:WaitForChild("HazardCollisionDetector") :: ModuleScript)

type PlayerData = Types.PlayerData
type GameState = Types.GameState

local GameManager = {
    currentState = "Waiting" :: GameState,
    players = {} :: {[number]: PlayerData},
    startTime = 0 :: number,
    roundNumber = 0 :: number,
    slopeGenerator = nil :: any,
    slopeBuilder = nil :: any,
    hazardSpawner = nil :: any,
    collisionDetector = nil :: any,
}

local remoteEventLimits = {} :: {[Player]: {[string]: number}}
local RATE_LIMIT_WINDOW = 1
local MAX_EVENTS_PER_WINDOW = 10

function GameManager:Init()
    print(`[{Config.GAME.NAME}] Initializing v{Config.GAME.VERSION}...`)
    
    self:_VerifyInstances()
    
    -- Initialize core systems
    self.slopeGenerator = SlopeGenerator.new()
    self.slopeBuilder = SlopeBuilder.new()
    self.hazardSpawner = HazardSpawner.new()
    self.collisionDetector = HazardCollisionDetector.new()
    
    Players.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
    
    self:_SetupRemoteHandlers()
    
    print(`[{Config.GAME.NAME}] Ready. State: {self.currentState}`)
end

function GameManager:_VerifyInstances()
    local required = {
        ReplicatedStorage:WaitForChild("Modules"),
        ReplicatedStorage:WaitForChild("Shared"),
        ReplicatedStorage:WaitForChild("RemoteEvents"),
    }
    for _, inst in ipairs(required) do
        if not inst then
            warn("[GameManager] Missing instance during verification")
        end
    end
end

function GameManager:_CheckRateLimit(player: Player, eventName: string): boolean
    local now = os.clock()
    if not remoteEventLimits[player] then
        remoteEventLimits[player] = {}
    end
    local limits = remoteEventLimits[player]
    if not limits[eventName] then
        limits[eventName] = now
        return true
    end
    if now - limits[eventName] < (RATE_LIMIT_WINDOW / MAX_EVENTS_PER_WINDOW) then
        return false
    end
    limits[eventName] = now
    return true
end

function GameManager:_SetupRemoteHandlers()
    local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
    local hazardHit = remotes:FindFirstChild(Config.REMOTES.HAZARD_HIT) :: RemoteEvent
    if hazardHit then
        hazardHit.OnServerEvent:Connect(function(player, hazardId, damage)
            if not self:_CheckRateLimit(player, "HazardHit") then return end
            if typeof(hazardId) ~= "string" or typeof(damage) ~= "number" then return end
            if damage < 0 or damage > 100 then return end
            self:OnHazardHit(player, hazardId, damage)
        end)
    end
    
    local playerScored = remotes:FindFirstChild(Config.REMOTES.PLAYER_SCORED) :: RemoteEvent
    if playerScored then
        playerScored.OnServerEvent:Connect(function(player, points, reason)
            if not self:_CheckRateLimit(player, "PlayerScored") then return end
            if typeof(points) ~= "number" or typeof(reason) ~= "string" then return end
            if points < 0 or points > 10000 then return end
            self:OnPlayerScored(player, points, reason)
        end)
    end
end

function GameManager:OnPlayerAdded(player: Player)
    print(`[GameManager] {player.Name} joined`)
    self.players[player.UserId] = {
        userId = player.UserId,
        username = player.Name,
        score = 0,
        highScore = 0,
        totalDistance = 0,
        checkpointsReached = 0,
        ragdollCount = 0,
        bestTime = nil,
        skinsOwned = {},
        gamepasses = {},
        lastPlayed = os.time(),
    }
    remoteEventLimits[player] = {}
    player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(player, character)
    end)
end

function GameManager:OnPlayerRemoving(player: Player)
    remoteEventLimits[player] = nil
    self.players[player.UserId] = nil
end

function GameManager:OnCharacterAdded(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid") :: Humanoid
    humanoid.WalkSpeed = Config.PLAYER.WALK_SPEED
    humanoid.JumpPower = Config.PLAYER.JUMP_POWER
    humanoid.MaxSlopeAngle = 89
    CollectionService:AddTag(character, "PlayerCharacter")
    
    if self.currentState == "Playing" then
        task.wait(0.5)
        local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
        if rootPart then
            rootPart.CFrame = CFrame.new(0, 10, 20)
        end
    end
end

function GameManager:OnHazardHit(player: Player, hazardId: string, damage: number)
    local data = self.players[player.UserId]
    if not data then return end
    data.ragdollCount += 1
    
    local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
    local remote = remotes:FindFirstChild(Config.REMOTES.RAGDOLL_TRIGGERED) :: RemoteEvent
    if remote then
        remote:FireClient(player, hazardId, damage)
    end
end

function GameManager:OnPlayerScored(player: Player, points: number, reason: string)
    local data = self.players[player.UserId]
    if not data then return end
    data.score += points
    if data.score > data.highScore then
        data.highScore = data.score
    end
end

function GameManager:StartRound()
    if self.currentState ~= "Waiting" then
        warn("[GameManager] Cannot start - wrong state")
        return
    end
    
    self.roundNumber += 1
    self.currentState = "Countdown"
    self.startTime = os.clock()
    
    print(`[GameManager] Building slope for round {self.roundNumber}...`)
    
    if self.slopeGenerator and self.slopeBuilder then
        self.slopeGenerator:Reset()
        self.slopeBuilder:Initialize()
        local segments = self.slopeGenerator:GenerateSegments(20)
        self.slopeBuilder:BuildSegments(segments)
        print(`[GameManager] Built { #segments } slope segments`)
    end
    
    if self.hazardSpawner then
        self.hazardSpawner:Start()
        print("[GameManager] Hazard spawner started")
    end
    
    if self.collisionDetector then
        self.collisionDetector:Start()
        print("[GameManager] Collision detector started")
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart
            if rootPart then
                rootPart.CFrame = CFrame.new(0, 10, 20)
            end
        end
    end
    
    task.wait(3)
    self.currentState = "Playing"
    print("[GameManager] Round active - GO!")
end

function GameManager:EndRound()
    if self.currentState ~= "Playing" then return end
    self.currentState = "Ended"
    
    if self.hazardSpawner then
        self.hazardSpawner:Stop()
    end
    if self.collisionDetector then
        self.collisionDetector:Stop()
    end
    
    print(`[GameManager] Round {self.roundNumber} ended`)
    task.wait(5)
    self.currentState = "Waiting"
end

function GameManager:GetPlayerData(userId: number): PlayerData?
    return self.players[userId]
end

function GameManager:GetState(): GameState
    return self.currentState
end

GameManager:Init()

return GameManager
