-- GameManager.server.lua
-- Main game orchestrator
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local GameManager = {}
GameManager.currentState = "Waiting" :: string
GameManager.players = {}

-- Initialize game
function GameManager:Init()
	print(`{Config.GAME_NAME} v{Config.VERSION} initialized`)
	
	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)
end

-- Handle player join
function GameManager:OnPlayerAdded(player: Player)
	self.players[player.UserId] = {
		score = 0,
		highScore = 0,
		checkpoints = 0,
	}
	print(`Player {player.Name} joined`)
end

-- Handle player leave
function GameManager:OnPlayerRemoving(player: Player)
	self.players[player.UserId] = nil
end

-- Start the game loop
function GameManager:Start()
	self.currentState = "Playing"
	print("Game started")
end

GameManager:Init()

return GameManager
