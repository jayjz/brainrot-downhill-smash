-- File: src/ServerScriptService/Services/HazardCollisionDetector.lua
--!strict
-- Detects hazard-player collisions and triggers ragdoll + knockback
-- Uses Touched events with debouncing for performance

local HazardCollisionDetector = {}
HazardCollisionDetector.__index = HazardCollisionDetector

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage.Shared.Config)

-- Track recent hits to prevent spam (player -> timestamp)
local recentHits = {} :: {[Player]: number}
local HIT_COOLDOWN = 0.5 -- seconds

function HazardCollisionDetector.new()
	local self = setmetatable({}, HazardCollisionDetector)
	self.activeConnections = {} :: {RBXScriptConnection}
	return self
end

function HazardCollisionDetector:Start()
	-- Listen for new hazards
	local addedConn = CollectionService:GetInstanceAddedSignal("Hazard"):Connect(function(hazard)
		self:_SetupHazardCollision(hazard)
	end)
	table.insert(self.activeConnections, addedConn)
	
	-- Setup existing hazards
	for _, hazard in ipairs(CollectionService:GetTagged("Hazard")) do
		self:_SetupHazardCollision(hazard)
	end
	
	print("[HazardCollisionDetector] Started")
end

function HazardCollisionDetector:_SetupHazardCollision(hazard: Instance)
	if not hazard:IsA("BasePart") then
		return
	end
	
	local connection = hazard.Touched:Connect(function(hit)
		self:_OnHazardTouched(hazard, hit)
	end)
	
	table.insert(self.activeConnections, connection)
end

function HazardCollisionDetector:_OnHazardTouched(hazard: BasePart, hit: BasePart)
	local character = hit.Parent
	if not character then
		return
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	
	-- Debounce hits
	local now = os.clock()
	local lastHit = recentHits[player]
	if lastHit and (now - lastHit) < HIT_COOLDOWN then
		return
	end
	recentHits[player] = now
	
	-- Get hazard data
	local hazardId = hazard:GetAttribute("HazardId") or "unknown"
	local damage = hazard:GetAttribute("Damage") or 10
	
	-- Apply damage
	humanoid:TakeDamage(damage)
	
	-- Fire to clients for ragdoll
	local remote = ReplicatedStorage.RemoteEvents:FindFirstChild("HazardHit")
	if remote then
		remote:FireClient(player, hazardId, damage)
	end
	
	-- Apply knockback
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		local knockbackDir = (rootPart.Position - hazard.Position).Unit
		knockbackDir = Vector3.new(knockbackDir.X, 0.4, knockbackDir.Z).Unit
		
		local knockbackForce = knockbackDir * Config.PHYSICS.KNOCKBACK_BASE
		rootPart.AssemblyLinearVelocity = knockbackForce
		
		-- Add spin for chaos
		rootPart.AssemblyAngularVelocity = Vector3.new(
			math.random(-10, 10),
			math.random(-10, 10),
			math.random(-10, 10)
		)
	end
	
	-- Screen shake for victim
	local shakeRemote = ReplicatedStorage.RemoteEvents:FindFirstChild("RagdollTriggered")
	if shakeRemote then
		shakeRemote:FireClient(player, hazardId, damage)
	end
	
	-- Visual feedback - brief highlight
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.7
	highlight.Parent = character
	Debris:AddItem(highlight, 0.3)
	
	print(`[HazardCollisionDetector] {player.Name} hit by {hazard.Name} for {damage} damage`)
end

function HazardCollisionDetector:Stop()
	for _, conn in ipairs(self.activeConnections) do
		conn:Disconnect()
	end
	self.activeConnections = {}
	recentHits = {}
	print("[HazardCollisionDetector] Stopped")
end

function HazardCollisionDetector:Destroy()
	self:Stop()
end

return HazardCollisionDetector
