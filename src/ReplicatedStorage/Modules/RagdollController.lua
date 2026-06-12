-- RagdollController.lua
-- Client-side ragdoll physics using BallSocketConstraints
--!strict

local RagdollController = {}
RagdollController.__index = RagdollController

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Parent.Shared.Config)

function RagdollController.new(character: Model)
	local self = setmetatable({}, RagdollController)
	self.character = character
	self.humanoid = character:WaitForChild("Humanoid") :: Humanoid
	self.isRagdolled = false
	self.constraints = {}
	return self
end

-- Enable ragdoll physics
function RagdollController:EnableRagdoll(velocity: Vector3?)
	self.isRagdolled = true
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	self.humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	
	-- Apply initial velocity if provided
	if velocity and self.character.PrimaryPart then
		self.character.PrimaryPart.AssemblyLinearVelocity = velocity * Config.PHYSICS.RAGDOLL_FORCE_MULTIPLIER
	end
	
	-- Create ball socket constraints for limbs
	self:_CreateConstraints()
end

-- Disable ragdoll and recover
function RagdollController:DisableRagdoll()
	self.isRagdolled = false
	self:_DestroyConstraints()
	self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

-- Create physical constraints
function RagdollController:_CreateConstraints()
	-- Implementation: Replace Motor6Ds with BallSocketConstraints
	-- See DevForum ragdoll tutorials for full implementation
	for _, joint in ipairs(self.character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			-- Store and replace with constraint
			-- Full implementation in Phase 2
		end
	end
end

-- Clean up constraints
function RagdollController:_DestroyConstraints()
	for _, constraint in ipairs(self.constraints) do
		if constraint and constraint.Parent then
			constraint:Destroy()
		end
	end
	self.constraints = {}
end

return RagdollController
