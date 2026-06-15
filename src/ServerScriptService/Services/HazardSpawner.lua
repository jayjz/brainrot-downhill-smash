-- File: src/ServerScriptService/Services/HazardSpawner.lua
--!strict
-- Enhanced with raycast-based slope surface spawning and InsertService loading

local HazardSpawner = {}
HazardSpawner.__index = HazardSpawner

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

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
	
	-- Setup local asset cache
	local assets = ServerStorage:FindFirstChild("Assets") or Instance.new("Folder", ServerStorage)
	assets.Name = "Assets"
	self.assetCache = assets:FindFirstChild("Hazards") or Instance.new("Folder", assets)
	self.assetCache.Name = "Hazards"
	
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
	if not spawnPos then 
		return nil 
	end
	
	local hazardInstance = self:_GetPooledHazard(hazardType) or self:_CreateHazardInstance(definition)
	if not hazardInstance then 
		warn(`[HazardSpawner] Failed to create hazard instance for {hazardType}`)
		return nil 
	end
	
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
	
	for attempt = 1, 5 do
		local offsetX = math.random(-30, 30)
		local offsetZ = math.random(40, 100)
		local testX = playerPos.X + offsetX
		local testZ = playerPos.Z - offsetZ
		local testY = playerPos.Y + math.random(30, 60)
		
		local rayOrigin = Vector3.new(testX, testY, testZ)
		local rayDirection = Vector3.new(0, -100, 0)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
		raycastParams.FilterDescendantsInstances = {workspace:FindFirstChild("SlopeContainer")}
		
		local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		
		if result and result.Instance then
			return result.Position + Vector3.new(0, 10, 0)
		end
	end
	
	return Vector3.new(
		playerPos.X + math.random(-20, 20),
		playerPos.Y + 40,
		playerPos.Z - math.random(50, 80)
	)
end

function HazardSpawner:_GetPooledHazard(hazardType: string): BasePart?
	local pool = self.hazardPool[hazardType]
	if pool and #pool > 0 then
		local instance = table.remove(pool)
		if instance then
			instance.Parent = workspace
			return instance
		end
	end
	return nil
end

-- ENHANCED: Prefer models via InsertService with local caching
function HazardSpawner:_CreateHazardInstance(definition: any): BasePart?
	local part: BasePart?
	local hazardName = definition.name:gsub("%s+", "")
	
	-- 1. Check local cache first
	local cached = self.assetCache:FindFirstChild(hazardName)
	if cached then
		local clone = cached:Clone()
		if clone:IsA("BasePart") then
			part = clone
		elseif clone:IsA("Model") then
			part = clone.PrimaryPart or clone:FindFirstChildOfClass("BasePart")
			if part then
				part = part:Clone()
				clone:Destroy()
			end
		end
	end
	
	-- 2. Try InsertService if not cached
	if not part and definition.assetId then
		local assetId = tonumber(definition.assetId:match("%d+"))
		if assetId then
			local success, model = pcall(function()
				return InsertService:LoadAsset(assetId)
			end)
			
			if success and model then
				-- Move to cache for future use
				local mainObject = model:FindFirstChildOfClass("Model") or model:FindFirstChildOfClass("BasePart")
				if mainObject then
					mainObject.Name = hazardName
					mainObject.Parent = self.assetCache
					
					-- Use a clone for the current hazard
					local clone = mainObject:Clone()
					if clone:IsA("BasePart") then
						part = clone
					elseif clone:IsA("Model") then
						part = clone.PrimaryPart or clone:FindFirstChildOfClass("BasePart")
						if part then
							part = part:Clone()
							clone:Destroy()
						end
					end
				end
				model:Destroy()
			end
		end
	end
	
	-- 3. Fallback to procedural Part
	if not part then
		if definition.name:find("Ball") or definition.name:find("Sphere") or definition.name:find("Barrel") then
			part = Instance.new("Part")
			part.Shape = Enum.PartType.Ball
		else
			part = Instance.new("Part")
		end
		part.Size = definition.size
		part.Color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), 100)
		part.Material = Enum.Material.SmoothPlastic
	end
	
	-- Configure physics and metadata
	if part then
		part.Name = definition.name
		part.CanCollide = true
		part.Anchored = false
		
		local mass = definition.mass or 20
		part.CustomPhysicalProperties = PhysicalProperties.new(mass, 0.3, 0.5, 0.5, 1)
		
		pcall(function()
			part.CollisionGroup = "Hazards"
		end)
		
		-- Add trail
		local attachment = Instance.new("Attachment")
		attachment.Parent = part
		
		local trail = Instance.new("Trail")
		trail.Attachment0 = attachment
		trail.Attachment1 = attachment
		trail.Color = ColorSequence.new(part.Color)
		trail.Lifetime = 0.3
		trail.Parent = part
	end
	
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
