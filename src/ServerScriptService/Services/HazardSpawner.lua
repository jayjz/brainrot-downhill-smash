-- HazardSpawner.lua
-- Procedural hazard spawning system
--!strict

local HazardSpawner = {}
HazardSpawner.__index = HazardSpawner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)

function HazardSpawner.new()
	local self = setmetatable({}, HazardSpawner)
	self.activeHazards = {}
	self.spawnRate = Config.HAZARDS.SPAWN_RATE
	return self
end

-- Spawn a hazard at position
function HazardSpawner:SpawnHazard(hazardType: string, position: Vector3)
	-- Implementation in Phase 2
	-- Will clone from ServerStorage.Assets and apply physics
	local hazard = {
		id = game.HttpService:GenerateGUID(false),
		type = hazardType,
		position = position,
		spawnTime = os.clock(),
	}
	
	table.insert(self.activeHazards, hazard)
	return hazard
end

-- Clean up distant hazards
function HazardSpawner:Cleanup()
	local currentTime = os.clock()
	for i = #self.activeHazards, 1, -1 do
		local hazard = self.activeHazards[i]
		if currentTime - hazard.spawnTime > 30 then
			table.remove(self.activeHazards, i)
		end
	end
end

return HazardSpawner
