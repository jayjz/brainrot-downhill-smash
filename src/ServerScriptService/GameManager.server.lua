-- File: src/ServerScriptService/GameManager.server.lua
--!strict
-- Main game orchestrator with validated RemoteEvent handling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerData = Types.PlayerData
type GameState = Types.GameState

local GameManager = {
	currentState = "Waiting" :: GameState,
	players = {} :: {[number]: PlayerData},
	startTime = 0 :: number,
	roundNumber = 0 :: number,
}

-- Rate limiting for RemoteEvents
local remoteEventLimits = {} :: {[Player]: {[string]: number}}
local RATE_LIMIT_WINDOW = 1 -- second
local MAX_EVENTS_PER_WINDOW = 10

-- Initialize game services and connections
function GameManager:Init()
	print(`[{Config.GAME.NAME}] Initializing v{Config.GAME.VERSION}...`)
	
	self:_VerifyInstances()
	
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
	
	print(`[{Config.GAME.NAME}] Initialization complete. State: {self.currentState}`)
end

-- Verify required instances exist
function GameManager:_VerifyInstances()
	local requiredPaths = {
		ReplicatedStorage.Modules,
		ReplicatedStorage.Shared,
		ReplicatedStorage.RemoteEvents,
		ServerStorage.Assets,
	}
	
	for _, instance in ipairs(requiredPaths) do
		if not instance then
			warn(`[GameManager] Missing required instance`)
		end
	end
end

-- Check rate limit for RemoteEvent
function GameManager:_CheckRateLimit(player: Player, eventName: string): boolean
	local now = os.clock()
	
	if not remoteEventLimits[player] then
		remoteEventLimits[player] = {}
	end
	
	local playerLimits = remoteEventLimits[player]
	
	if not playerLimits[eventName] then
		playerLimits[eventName] = now
		return true
	end
	
	local lastTime = playerLimits[eventName]
	if now - lastTime < (RATE_LIMIT_WINDOW / MAX_EVENTS_PER_WINDOW) then
		warn(`[GameManager] Rate limit exceeded for {player.Name} on {eventName}`)
		return false
	end
	
	playerLimits[eventName] = now
	return true
end

-- Set up RemoteEvent connections with validation
function GameManager:_SetupRemoteHandlers()
	local remotes = ReplicatedStorage.RemoteEvents
	
	-- HazardHit: Validate player, hazardId, and damage
	local hazardHit = remotes:FindFirstChild(Config.REMOTES.HAZARD_HIT) :: RemoteEvent
	if hazardHit then
		hazardHit.OnServerEvent:Connect(function(player, hazardId, damage)
			if not self:_CheckRateLimit(player, "HazardHit") then
				return
			end
			
			-- Validate parameters
			if typeof(hazardId) ~= "string" or typeof(damage) ~= "number" then
				warn(`[GameManager] Invalid HazardHit parameters from {player.Name}`)
				return
			end
			
			if damage < 0 or damage > 100 then
				warn(`[GameManager] Suspicious damage value from {player.Name}: {damage}`)
				return
			end
			
			self:OnHazardHit(player, hazardId, damage)
		end)
	end
	
	-- PlayerScored: Validate points and reason
	local playerScored = remotes:FindFirstChild(Config.REMOTES.PLAYER_SCORED) :: RemoteEvent
	if playerScored then
		playerScored.OnServerEvent:Connect(function(player, points, reason)
			if not self:_CheckRateLimit(player, "PlayerScored") then
				return
			end
			
			if typeof(points) ~= "number" or typeof(reason) ~= "string" then
				warn(`[GameManager] Invalid PlayerScored parameters from {player.Name}`)
				return
			end
			
			if points < 0 or points > 10000 then
				warn(`[GameManager] Suspicious points from {player.Name}: {points}`)
				return
			end
			
			self:OnPlayerScored(player, points, reason)
		end)
	end
	
	-- CheckpointReached: Validate checkpoint data
	local checkpointReached = remotes:FindFirstChild(Config.REMOTES.CHECKPOINT_REACHED) :: RemoteEvent
	if checkpointReached then
		checkpointReached.OnServerEvent:Connect(function(player, checkpointIndex, height)
			if not self:_CheckRateLimit(player, "CheckpointReached") then
				return
			end
			
			if typeof(checkpointIndex) ~= "number" or typeof(height) ~= "number" then
				warn(`[GameManager] Invalid CheckpointReached parameters from {player.Name}`)
				return
			end
			
			self:OnCheckpointReached(player, checkpointIndex, height)
		end)
	end
end

-- Handle player joining
function GameManager:OnPlayerAdded(player: Player)
	print(`[GameManager] Player joined: {player.Name} ({player.UserId})`)
	
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

-- Handle player leaving
function GameManager:OnPlayerRemoving(player: Player)
	print(`[GameManager] Player leaving: {player.Name}`)
	remoteEventLimits[player] = nil
	self.players[player.UserId] = nil
end

-- Handle character spawn
function GameManager:OnCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	
	humanoid.WalkSpeed = Config.PLAYER.WALK_SPEED
	humanoid.JumpPower = Config.PLAYER.JUMP_POWER
	humanoid.MaxSlopeAngle = 85
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
	
	CollectionService:AddTag(character, "PlayerCharacter")
end

-- Handle hazard hit with validation
function GameManager:OnHazardHit(player: Player, hazardId: string, damage: number)
	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end
	
	playerData.ragdollCount += 1
	
	local remote = ReplicatedStorage.RemoteEvents:FindFirstChild(Config.REMOTES.RAGDOLL_TRIGGERED) :: RemoteEvent
	if remote then
		remote:FireClient(player, hazardId, damage)
	end
	
	print(`[GameManager] {player.Name} hit by hazard {hazardId}`)
end

-- Handle player scoring with validation
function GameManager:OnPlayerScored(player: Player, points: number, reason: string)
	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end
	
	playerData.score += points
	
	if playerData.score > playerData.highScore then
		playerData.highScore = playerData.score
	end
	
	print(`[GameManager] {player.Name} +{points} ({reason}) = {playerData.score}`)
end

-- Handle checkpoint reached
function GameManager:OnCheckpointReached(player: Player, checkpointIndex: number, height: number)
	local playerData = self.players[player.UserId]
	if not playerData then
		return
	end
	
	playerData.checkpointsReached += 1
	playerData.totalDistance = math.max(playerData.totalDistance, height)
	
	-- Award checkpoint points
	self:OnPlayerScored(player, Config.SCORING.CHECKPOINT_VALUE, `Checkpoint {checkpointIndex}`)
	
	print(`[GameManager] {player.Name} reached checkpoint {checkpointIndex} at height {height}`)
end

-- Start a new round
function GameManager:StartRound()
	if self.currentState ~= "Waiting" then
		warn("[GameManager] Cannot start round - invalid state")
		return
	end
	
	self.roundNumber += 1
	self.currentState = "Countdown"
	self.startTime = os.clock()
	
	print(`[GameManager] Round {self.roundNumber} starting...`)
	
	task.wait(3)
	
	self.currentState = "Playing"
	print("[GameManager] Round active")
end

-- End current round
function GameManager:EndRound()
	if self.currentState ~= "Playing" then
		return
	end
	
	self.currentState = "Ended"
	print(`[GameManager] Round {self.roundNumber} ended`)
	
	task.wait(5)
	self.currentState = "Waiting"
end

-- Get player data
function GameManager:GetPlayerData(userId: number): PlayerData?
	return self.players[userId]
end

-- Get current game state
function GameManager:GetState(): GameState
	return self.currentState
end

-- Initialize on require
GameManager:Init()

return GameManager
