-- File: src/ServerScriptService/GameManager.server.lua (INTEGRATED)
--!strict
-- Main game orchestrator with SlopeBuilder integration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local SlopeGenerator = require(ReplicatedStorage.Modules.SlopeGenerator)
local SlopeBuilder = require(ReplicatedStorage.Modules.SlopeBuilder)

type PlayerData = Types.PlayerData
type GameState = Types.GameState

local GameManager = {
	currentState = "Waiting" :: GameState,
	players = {} :: {[number]: PlayerData},
	startTime = 0 :: number,
	roundNumber = 0 :: number,
	slopeGenerator = nil :: any,
	slopeBuilder = nil :: any,
}

-- Rate limiting for RemoteEvents
local remoteEventLimits = {} :: {[Player]: {[string]: number}}
local RATE_LIMIT_WINDOW = 1
local MAX_EVENTS_PER_WINDOW = 10

-- Initialize game services
function GameManager:Init()
	print(`[{Config.GAME.NAME}] Initializing v{Config.GAME.VERSION}...`)
	
	self:_VerifyInstances()
	self.slopeGenerator = SlopeGenerator.new()
	self.slopeBuilder = SlopeBuilder.new()
	
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

-- Verify required instances
function GameManager:_VerifyInstances()
	local required = {
		ReplicatedStorage.Modules,
		ReplicatedStorage.Shared,
		ReplicatedStorage.RemoteEvents,
	}
	
	for _, inst in ipairs(required) do
		if not inst then
			warn("[GameManager] Missing instance")
		end
	end
end

-- Rate limit check
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

-- Setup RemoteEvent handlers with validation
function GameManager:_SetupRemoteHandlers()
	local remotes = ReplicatedStorage.RemoteEvents
	
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
	
	local checkpointReached = remotes:FindFirstChild(Config.REMOTES.CHECKPOINT_REACHED) :: RemoteEvent
	if checkpointReached then
		checkpointReached.OnServerEvent:Connect(function(player, checkpointIndex, height)
			if not self:_CheckRateLimit(player, "CheckpointReached") then return end
			if typeof(checkpointIndex) ~= "number" or typeof(height) ~= "number" then return end
			self:OnCheckpointReached(player, checkpointIndex, height)
		end)
	end
end

-- Player joined
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

-- Player leaving
function GameManager:OnPlayerRemoving(player: Player)
	remoteEventLimits[player] = nil
	self.players[player.UserId] = nil
end

-- Character added
function GameManager:OnCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.WalkSpeed = Config.PLAYER.WALK_SPEED
	humanoid.JumpPower = Config.PLAYER.JUMP_POWER
	humanoid.MaxSlopeAngle = 89
	CollectionService:AddTag(character, "PlayerCharacter")
	
	-- Teleport to slope start if game is active
	if self.currentState == "Playing" then
		task.wait(0.5)
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if rootPart then
			rootPart.CFrame = CFrame.new(0, 10, 20)
		end
	end
end

-- Hazard hit
function GameManager:OnHazardHit(player: Player, hazardId: string, damage: number)
	local data = self.players[player.UserId]
	if not data then return end
	
	data.ragdollCount += 1
	
	local remote = ReplicatedStorage.RemoteEvents:FindFirstChild(Config.REMOTES.RAGDOLL_TRIGGERED) :: RemoteEvent
	if remote then
		remote:FireClient(player, hazardId, damage)
	end
end

-- Player scored
function GameManager:OnPlayerScored(player: Player, points: number, reason: string)
	local data = self.players[player.UserId]
	if not data then return end
	
	data.score += points
	if data.score > data.highScore then
		data.highScore = data.score
	end
end

-- Checkpoint reached
function GameManager:OnCheckpointReached(player: Player, checkpointIndex: number, height: number)
	local data = self.players[player.UserId]
	if not data then return end
	
	data.checkpointsReached += 1
	data.totalDistance = math.max(data.totalDistance, height)
	self:OnPlayerScored(player, Config.SCORING.CHECKPOINT_VALUE, `Checkpoint {checkpointIndex}`)
end

-- Start round - BUILDS SLOPE
function GameManager:StartRound()
	if self.currentState ~= "Waiting" then
		warn("[GameManager] Cannot start - wrong state")
		return
	end
	
	self.roundNumber += 1
	self.currentState = "Countdown"
	self.startTime = os.clock()
	
	print(`[GameManager] Building slope for round {self.roundNumber}...`)
	
	-- CRITICAL: Build the physical slope
	if self.slopeGenerator and self.slopeBuilder then
		self.slopeGenerator:Reset()
		self.slopeBuilder:Initialize()
		
		-- Generate 20 segments for initial playtest
		local segments = self.slopeGenerator:GenerateSegments(20)
		self.slopeBuilder:BuildSegments(segments)
		
		print(`[GameManager] Built { #segments } slope segments`)
	end
	
	-- Teleport all players to start
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

-- End round
function GameManager:EndRound()
	if self.currentState ~= "Playing" then return end
	self.currentState = "Ended"
	print(`[GameManager] Round {self.roundNumber} ended`)
	task.wait(5)
	self.currentState = "Waiting"
end

-- Getters
function GameManager:GetPlayerData(userId: number): PlayerData?
	return self.players[userId]
end

function GameManager:GetState(): GameState
	return self.currentState
end

function GameManager:GetSlopeGenerator()
	return self.slopeGenerator
end

function GameManager:GetSlopeBuilder()
	return self.slopeBuilder
end

-- Initialize
GameManager:Init()

return GameManager
