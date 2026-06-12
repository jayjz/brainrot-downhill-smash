-- File: src/ServerScriptService/Services/HazardSpawner.lua
--!strict
-- Server-side hazard spawning system with object pooling and physics

local HazardSpawner = {}
HazardSpawner.__index = HazardSpawner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local HazardTypes = require(ReplicatedStorage.Modules.HazardTypes)

type ActiveHazard = Types.ActiveHazard

-- Create new spawner instance
function HazardSpawner.new(): HazardSpawner
	local self = setmetatable({}, HazardSpawner)
	
	self.activeHazards = {} :: {ActiveHazard}
	self.hazardPool = {} :: {[string]: {BasePart}}
	self.spawnRate = Config.HAZARDS.BASE_SPAWN_RATE
	self.lastSpawnTime = 0 :: number
	self.isActive = false
	
	-- Set up collision groups
	self:_SetupCollisionGroups()
	
	return self
end

-- Set up physics collision groups
function HazardSpawner:_SetupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Hazards")
		PhysicsService:CollisionGroupSetCollidable("Hazards", "Hazards", false)
		PhysicsService:CollisionGroupSetCollidable("Hazards", "Default", true)
	end)
end

-- Start spawning hazards
function HazardSpawner:Start()
	if self.isActive then
		return
	end
	
	self.isActive = true
	print("[HazardSpawner] Started")
	
	task.spawn(function()
		while self.isActive do
			self:_SpawnLoop()
			task.wait(1 / self.spawnRate)
		end
	end)
	
	task.spawn(function()
		while self.isActive do
			self:Cleanup()
			task.wait(5)
		end
	end)
end

-- Stop spawning
function HazardSpawner:Stop()
	self.isActive = false
	print("[HazardSpawner] Stopped")
	self:ClearAllHazards()
end

-- Main spawn loop
function HazardSpawner:_SpawnLoop()
	local currentTime = os.clock()
	
	if currentTime - self.lastSpawnTime < (1 / self.spawnRate) then
		return
	end
	
	if #self.activeHazards >= Config.HAZARDS.MAX_ACTIVE then
		return
	end
	
	self:SpawnRandomHazard()
	self.lastSpawnTime = currentTime
end

-- Spawn a random hazard
function HazardSpawner:SpawnRandomHazard(position: Vector3?): ActiveHazard?
	local hazardType = HazardTypes:GetRandomType()
	local definition = HazardTypes:GetDefinition(hazardType)
	
	if not definition then
		return nil
	end
	
	local spawnPos = position or self:_GetRandomSpawnPosition()
	if not spawnPos then
		return nil
	end
	
	local hazardInstance = self:_GetPooledHazard(hazardType) or self:_CreateHazardInstance(definition)
	if not hazardInstance then
		return nil
	end
	
	hazardInstance.CFrame = CFrame.new(spawnPos)
	hazardInstance.AssemblyLinearVelocity = Vector3.new(
		math.random(-20, 20),
		math.random(-5, 5),
		math.random(-30, -10)
	)
	hazardInstance.AssemblyAngularVelocity = Vector3.new(
		math.random(-10, 10),
		math.random(-10, 10),
		math.random(-10, 10)
	)
	hazardInstance.Parent = workspace
	
	local activeHazard: ActiveHazard = {
		id = game.HttpService:GenerateGUID(false),
		hazardType = hazardType :: any,
		instance = hazardInstance,
		position = spawnPos,
		velocity = hazardInstance.AssemblyLinearVelocity,
		damage = definition.damage,
		spawnTime = os.clock(),
		lastHitTime = nil,
	}
	
	CollectionService:AddTag(hazardInstance, "Hazard")
	hazardInstance:SetAttribute("HazardId", activeHazard.id)
	hazardInstance:SetAttribute("Damage", definition.damage)
	
	table.insert(self.activeHazards, activeHazard)
	return activeHazard
end

-- Get random spawn position
function HazardSpawner:_GetRandomSpawnPosition(): Vector3?
	local players = Players:GetPlayers()
	if #players == 0 then
		return Vector3.new(0, 50, -100)
	end
	
	local targetPlayer = players[math.random(1, #players)]
	local character = targetPlayer.Character
	if not character or not character.PrimaryPart then
		return nil
	end
	
	local playerPos = character.PrimaryPart.Position
	local offsetX = math.random(-Config.HAZARDS.MAX_SPAWN_DISTANCE, Config.HAZARDS.MAX_SPAWN_DISTANCE)
	local offsetY = math.random(20, 60)
	local offsetZ = math.random(Config.HAZARDS.MIN_SPAWN_DISTANCE, Config.HAZARDS.MAX_SPAWN_DISTANCE)
	
	return playerPos + Vector3.new(offsetX, offsetY, -offsetZ)
end

-- Get pooled hazard or create new
function HazardSpawner:_GetPooledHazard(hazardType: string): BasePart?
	local pool = self.hazardPool[hazardType]
	if pool and #pool > 0 then
		return table.remove(pool)
	end
	return nil
end

-- Create new hazard instance
function HazardSpawner:_CreateHazardInstance(definition: any): BasePart?
	local part = Instance.new("Part")
	part.Name = definition.name
	part.Size = definition.size
	part.Color = Color3.fromRGB(255, 100, 100)
	part.Material = Enum.Material.Neon
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	
	local mass = definition.mass or 20
	part.CustomPhysicalProperties = PhysicalProperties.new(mass, 0.3, 0.5)
	
	pcall(function()
		part.CollisionGroup = "Hazards"
	end)
	
	return part
end

-- Return hazard to pool
function HazardSpawner:_ReturnToPool(hazard: ActiveHazard)
	if not hazard.instance then
		return
	end
	
	hazard.instance.Parent = nil
	hazard.instance.AssemblyLinearVelocity = Vector3.zero
	hazard.instance.AssemblyAngularVelocity = Vector3.zero
	
	local hazardType = hazard.hazardType
	if not self.hazardPool[hazardType] then
		self.hazardPool[hazardType] = {}
	end
	
	table.insert(self.hazardPool[hazardType], hazard.instance)
end

-- Clean up old/distant hazards
function HazardSpawner:Cleanup()
	local currentTime = os.clock()
	local toRemove = {}
	
	for i, hazard in ipairs(self.activeHazards) do
		local shouldRemove = false
		
		if currentTime - hazard.spawnTime > Config.HAZARDS.DESPAWN_TIME then
			shouldRemove = true
		elseif hazard.instance and hazard.instance.Parent then
			local distance = (hazard.instance.Position - Vector3.zero).Magnitude
			if distance > Config.HAZARDS.DESPAWN_DISTANCE then
				shouldRemove = true
			end
		else
			shouldRemove = true
		end
		
		if shouldRemove then
			table.insert(toRemove, i)
			if hazard.instance then
				self:_ReturnToPool(hazard)
			end
		end
	end
	
	for i = #toRemove, 1, -1 do
		table.remove(self.activeHazards, toRemove[i])
	end
end

-- Clear all active hazards
function HazardSpawner:ClearAllHazards()
	for _, hazard in ipairs(self.activeHazards) do
		if hazard.instance then
			hazard.instance:Destroy()
		end
	end
	self.activeHazards = {}
end

-- Get active hazard count
function HazardSpawner:GetActiveCount(): number
	return #self.activeHazards
end

-- Update spawn rate based on game progression
function HazardSpawner:UpdateSpawnRate(height: number)
	local scaleFactor = 1 + (height / 100) * Config.HAZARDS.SPAWN_RATE_SCALE
	self.spawnRate = Config.HAZARDS.BASE_SPAWN_RATE * scaleFactor
end

export type HazardSpawner = typeof(setmetatable({} :: any, HazardSpawner))
return HazardSpawner
