-- File: src/StarterPlayer/StarterPlayerScripts/Controllers/RagdollClient.lua
--!strict
-- Client-side ragdoll controller that listens for server events
-- Handles ragdoll triggering, recovery, and visual feedback

local RagdollClient = {}
RagdollClient.__index = RagdollClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RagdollController = require(ReplicatedStorage.Modules.RagdollController)
local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local character: Model? = nil
local humanoid: Humanoid? = nil
local ragdollController: any = nil
local isRagdolled = false

-- Initialize ragdoll client
function RagdollClient.Init()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	
	ragdollController = RagdollController.new(character)
	
	-- Listen for ragdoll trigger from server
	local ragdollRemote = ReplicatedStorage.RemoteEvents:WaitForChild("RagdollTriggered") :: RemoteEvent
	ragdollRemote.OnClientEvent:Connect(function(hazardId: string, damage: number)
		RagdollClient:TriggerRagdoll(hazardId, damage)
	end)
	
	-- Also listen for direct HazardHit (fallback)
	local hazardHitRemote = ReplicatedStorage.RemoteEvents:WaitForChild("HazardHit") :: RemoteEvent
	hazardHitRemote.OnClientEvent:Connect(function(hazardId: string, damage: number)
		RagdollClient:TriggerRagdoll(hazardId, damage)
	end)
	
	-- Handle character respawn
	player.CharacterAdded:Connect(function(newCharacter)
		character = newCharacter
		humanoid = character:WaitForChild("Humanoid") :: Humanoid
		ragdollController = RagdollController.new(character)
		isRagdolled = false
	end)
	
	print("[RagdollClient] Initialized and listening for ragdoll events")
end

-- Trigger ragdoll with momentum preservation
function RagdollClient:TriggerRagdoll(hazardId: string, damage: number)
	if isRagdolled then
		return -- Already ragdolled, ignore
	end
	
	if not character or not humanoid or not ragdollController then
		warn("[RagdollClient] Cannot ragdoll - missing components")
		return
	end
	
	if humanoid.Health <= 0 then
		return -- Don't ragdoll if dead
	end
	
	isRagdolled = true
	
	-- Get current velocity for momentum preservation
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local currentVelocity = Vector3.zero
	
	if rootPart then
		currentVelocity = rootPart.AssemblyLinearVelocity
		
		-- Add extra knockback based on damage
		local knockbackMultiplier = 1 + (damage / 50)
		currentVelocity = currentVelocity * knockbackMultiplier
		
		-- Ensure minimum velocity for dramatic tumble
		if currentVelocity.Magnitude < 20 then
			currentVelocity = currentVelocity + Vector3.new(
				math.random(-10, 10),
				5,
				math.random(-20, -10)
			)
		end
	end
	
	print(`[RagdollClient] Triggering ragdoll from hazard {hazardId} (damage: {damage})`)
	
	-- Enable ragdoll with momentum
	ragdollController:EnableRagdoll(currentVelocity)
	
	-- Disable character controls during ragdoll
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	
	-- Recovery timer
	task.delay(Config.PLAYER.RAGDOLL_RECOVERY_TIME, function()
		RagdollClient:RecoverFromRagdoll()
	end)
	
	-- Visual feedback
	RagdollClient:_PlayRagdollEffects()
end

-- Recover from ragdoll state
function RagdollClient:RecoverFromRagdoll()
	if not isRagdolled then
		return
	end
	
	if not ragdollController or not humanoid then
		return
	end
	
	print("[RagdollClient] Recovering from ragdoll")
	
	-- Disable ragdoll physics
	ragdollController:DisableRagdoll()
	
	-- Restore character controls
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = Config.PLAYER.WALK_SPEED
	humanoid.JumpPower = Config.PLAYER.JUMP_POWER
	
	-- Brief invulnerability period
	humanoid:SetAttribute("RagdollInvulnerable", true)
	task.delay(Config.PLAYER.RAGDOLL_INVULNERABILITY, function()
		if humanoid then
			humanoid:SetAttribute("RagdollInvulnerable", false)
		end
	end)
	
	isRagdolled = false
	
	-- Recovery effects
	RagdollClient:_PlayRecoveryEffects()
end

-- Play visual/audio effects for ragdoll
function RagdollClient:_PlayRagdollEffects()
	if not character then return end
	
	-- Screen shake is handled by CameraController
	-- Add any additional effects here
	
	-- Temporary speed lines or impact effect
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		-- Could add particle emitter here for impact effect
	end
end

-- Play recovery effects
function RagdollClient:_PlayRecoveryEffects()
	if not character then return end
	
	-- Brief invulnerability visual
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Flash character or add brief transparency
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				local originalTransparency = part.Transparency
				part.Transparency = 0.5
				
				task.delay(0.1, function()
					if part and part.Parent then
						part.Transparency = originalTransparency
					end
				end)
			end
		end
	end
end

-- Check if currently ragdolled
function RagdollClient:IsRagdolled(): boolean
	return isRagdolled
end

-- Force recovery (for debugging or game state changes)
function RagdollClient:ForceRecovery()
	if isRagdolled then
		RagdollClient:RecoverFromRagdoll()
	end
end

-- Initialize on require
RagdollClient.Init()

return RagdollClient
