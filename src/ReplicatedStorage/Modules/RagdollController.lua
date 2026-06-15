-- RagdollController.lua
-- Enhanced ragdoll physics using BallSocketConstraints for momentum preservation
--!strict

local RagdollController = {}
RagdollController.__index = RagdollController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

export type RagdollControllerType = {
	character: Model,
	humanoid: Humanoid,
	isRagdolled: boolean,
	constraints: {Constraint},
	attachments: {Attachment},
	disabledJoints: {Motor6D},
}

function RagdollController.new(character: Model): RagdollControllerType
	local humanoid = character:WaitForChild("Humanoid")
	if not humanoid:IsA("Humanoid") then
		error("RagdollController: Model must contain a Humanoid")
	end

	local self = setmetatable({
		character = character,
		humanoid = humanoid,
		isRagdolled = false,
		constraints = {},
		attachments = {},
		disabledJoints = {},
	}, RagdollController)

	return (self :: any) :: RagdollControllerType
end

-- Enable ragdoll physics with momentum preservation
function RagdollController:EnableRagdoll(velocity: Vector3?)
	if self.isRagdolled then return end
	self.isRagdolled = true

	-- Physics validation: Only proceed if we have network ownership (usually client for player)
	-- or if we are on the server.
	
	-- Disable humanoid state
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	self.humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	
	-- Create constraints first so momentum is applied to the constrained assembly
	self:_CreateConstraints()

	-- Apply initial velocity to all parts to ensure momentum carries over
	if velocity then
		for _, part in ipairs(self.character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity = velocity * Config.PHYSICS.RAGDOLL_FORCE_MULTIPLIER
				
				-- Add some angular velocity for a more natural tumble
				part.AssemblyAngularVelocity = Vector3.new(
					math.random(-5, 5),
					math.random(-5, 5),
					math.random(-5, 5)
				)
			end
		end
	end
end

-- Disable ragdoll and recover
function RagdollController:DisableRagdoll()
	if not self.isRagdolled then return end
	self.isRagdolled = false
	
	self:_DestroyConstraints()
	
	-- Restore humanoid state
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
	self.humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

-- Create physical constraints (BallSocketConstraints)
function RagdollController:_CreateConstraints()
	self:_DestroyConstraints() -- Safety check

	for _, joint in ipairs(self.character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			local part0 = joint.Part0
			local part1 = joint.Part1
			
			-- Create Attachments
			local att0 = Instance.new("Attachment")
			att0.CFrame = joint.C0
			att0.Parent = part0
			att0.Name = "RagdollAttachment"

			local att1 = Instance.new("Attachment")
			att1.CFrame = joint.C1
			att1.Parent = part1
			att1.Name = "RagdollAttachment"

			-- Create BallSocketConstraint
			local bsc = Instance.new("BallSocketConstraint")
			bsc.Attachment0 = att0
			bsc.Attachment1 = att1
			
			-- Highly tuned properties to prevent "floatiness" and ensure solid momentum
			bsc.LimitsEnabled = true
			bsc.UpperAngle = 45 -- Prevent extreme limb twisting
			bsc.Restitution = 0.1 -- Small bounce for impact feel
			
			bsc.Parent = part1
			bsc.Name = "RagdollConstraint"

			-- Disable Motor6D
			joint.Enabled = false
			
			table.insert(self.constraints, bsc)
			table.insert(self.attachments, att0)
			table.insert(self.attachments, att1)
			table.insert(self.disabledJoints, joint)
		end
	end
	
	-- Disable the root part's influence on physics to allow limbs to drive the tumble
	local rootPart = self.character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.CanCollide = false
	end
end

-- Clean up constraints and re-enable joints
function RagdollController:_DestroyConstraints()
	for _, joint in ipairs(self.disabledJoints) do
		if joint and joint.Parent then
			joint.Enabled = true
		end
	end
	
	for _, constraint in ipairs(self.constraints) do
		if constraint and constraint.Parent then
			constraint:Destroy()
		end
	end
	
	for _, attachment in ipairs(self.attachments) do
		if attachment and attachment.Parent then
			attachment:Destroy()
		end
	end
	
	local rootPart = self.character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.CanCollide = true
	end

	self.constraints = {}
	self.attachments = {}
	self.disabledJoints = {}
end

return RagdollController
