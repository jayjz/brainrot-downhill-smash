-- File: src/ServerScriptService/Services/HazardSpawner.lua (ENHANCED)
--!strict
-- Enhanced with raycast-based slope surface spawning

local HazardSpawner = {}
HazardSpawner.__index = HazardSpawner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local HazardTypes = require(ReplicatedStorage.Modules.HazardTypes)

type ActiveHazard = Types.ActiveHazard

function HazardSpawner.new(): HazardSpawner
	local self = setmetatable({}, HazardSpawner)
	self.activeHazards = {} :: {ActiveHazard}
	self.hazardPool = {} :: {[string]: {BasePart}}
	self.spawnRate = Config.HAZARDS.BASE_SPAWN_RATE
	self.lastSpawnTime = 0 :: number
	self.isActive = false
	self:_SetupCollisionGroups()
	return self
end

function HazardSpawner:_SetupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Hazards")
		PhysicsService:CollisionGroupSetCollidable("Hazards", "Hazards", false)
		PhysicsService:CollisionGroupSetCollidable("Hazards", "Default", true)
	end)
end

function HazardSpawner:Start()
	if self.isActive then return end
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

function HazardSpawner:Stop()
	self.isActive = false
	print("[HazardSpawner] Stopped")
	self:ClearAllHazards()
end

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

function HazardSpawner:SpawnRandomHazard(position: Vector3?): ActiveHazard?
	local hazardType = HazardTypes:GetRandomType()
	local definition = HazardTypes:GetDefinition(hazardType)
	if not definition then return nil end
	
	local spawnPos = position or self:_GetValidSpawnPosition()
	if not spawnPos then return nil end
	
	local hazardInstance = self:_GetPooledHazard(hazardType) or self:_CreateHazardInstance(definition)
	if not hazardInstance then return nil end
	
	hazardInstance.CFrame = CFrame.new(spawnPos)
	hazardInstance.AssemblyLinearVelocity = Vector3.new(
		math.random(-15, 15),
		math.random(-5, 0),
		math.random(-25, -5)
	)
	hazardInstance.AssemblyAngularVelocity = Vector3.new(
		math.random(-8, 8),
		math.random(-8, 8),
		math.random(-8, 8)
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

-- ENHANCED: Raycast to find valid spawn position on slope surface
function HazardSpawner:_GetValidSpawnPosition(): Vector3?
	local players = Players:GetPlayers()
	if #players == 0 then
		return Vector3.new(math.random(-20, 20), 80, -150)
	end
	
	local targetPlayer = players[math.random(1, #players)]
	local character = targetPlayer.Character
	if not character or not character.PrimaryPart then
		return nil
	end
	
	local playerPos = character.PrimaryPart.Position
	
	-- Try multiple positions to find valid spawn above slope
	for attempt = 1, 5 do
		local offsetX = math.random(-30, 30)
		local offsetZ = math.random(40, 100)
		local testX = playerPos.X + offsetX
		local testZ = playerPos.Z - offsetZ
		local testY = playerPos.Y + math.random(30, 60)
		
		-- Raycast down to find slope surface
		local rayOrigin = Vector3.new(testX, testY, testZ)
		local rayDirection = Vector3.new(0, -100, 0)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
		raycastParams.FilterDescendantsInstances = {workspace.SlopeContainer}
		
		local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		
		if result and result.Instance then
			-- Found slope surface, spawn 10 studs above it
			return result.Position + Vector3.new(0, 10, 0)
		end
	end
	
	-- Fallback: spawn at estimated height
	return Vector3.new(
		playerPos.X + math.random(-20, 20),
		playerPos.Y + 40,
		playerPos.Z - math.random(50, 80)
	)
end

function HazardSpawner:_GetPooledHazard(hazardType: string): BasePart?
	local pool = self.hazardPool[hazardType]
	if pool and #pool > 0 then
		return table.remove(pool)
	end
	return nil
end

function HazardSpawner:_CreateHazardInstance(definition: any): BasePart?
	local part: BasePart
	
	if definition.assetId then
		-- Try to load asset via InsertService
		local InsertService = game:GetService("InsertService")
		local success, asset = pcall(function()
			return InsertService:LoadAsset(tonumber(definition.assetId:match("%d+")) or 0)
		end)
		
		if success and asset then
			local model = asset:FindFirstChildOfClass("Model")
			if model and model.PrimaryPart then
				part = model.PrimaryPart:Clone()
				model:Destroy()
			end
		end
	end
	
	-- Fallback to procedural part
	if not part then
		if definition.name:find("Ball") or definition.name:find("Sphere") then
			part = Instance.new("Part")
			part.Shape = Enum.PartType.Ball
		else
			part = Instance.new("Part")
		end
		part.Size = definition.size
		part.Color = Color3.fromRGB(
			math.random(100, 255),
			math.random(50, 150),
			math.random(50, 150)
		)
		part.Material = Enum.Material.SmoothPlastic
	end
	
	part.Name = definition.name
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	part.Massless = false
	
	local mass = definition.mass or 20
	part.CustomPhysicalProperties = PhysicalProperties.new(mass, 0.3, 0.5, 0.5, 1)
	
	pcall(function()
		part.CollisionGroup = "Hazards"
	end)
	
	-- Add particle trail for visibility
	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	
	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment
	trail.Attachment1 = attachment
	trail.Color = ColorSequence.new(part.Color)
	trail.Lifetime = 0.3
	trail.MinLength = 0.1
	trail.Parent = part
	
	return part
end

function HazardSpawner:_ReturnToPool(hazard: ActiveHazard)
	if not hazard.instance then return end
	hazard.instance.Parent = nil
	hazard.instance.AssemblyLinearVelocity = Vector3.zero
	hazard.instance.AssemblyAngularVelocity = Vector3.zero
	local hazardType = hazard.hazardType
	if not self.hazardPool[hazardType] then
		self.hazardPool[hazardType] = {}
	end
	table.insert(self.hazardPool[hazardType], hazard.instance)
end

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

function HazardSpawner:ClearAllHazards()
	for _, hazard in ipairs(self.activeHazards) do
		if hazard.instance then
			hazard.instance:Destroy()
		end
	end
	self.activeHazards = {}
end

function HazardSpawner:GetActiveCount(): number
	return #self.activeHazards
end

function HazardSpawner:UpdateSpawnRate(height: number)
	local scaleFactor = 1 + (height / 100) * Config.HAZARDS.SPAWN_RATE_SCALE
	self.spawnRate = Config.HAZARDS.BASE_SPAWN_RATE * scaleFactor
end

export type HazardSpawner = typeof(setmetatable({} :: any, HazardSpawner))
return HazardSpawner
