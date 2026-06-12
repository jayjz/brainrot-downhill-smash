-- File: src/ReplicatedStorage/Modules/SlopeBuilder.lua
--!strict
-- Builds physical slope parts in Workspace from SlopeGenerator data
-- Uses wedges and optimized part count for performance

local SlopeBuilder = {}
SlopeBuilder.__index = SlopeBuilder

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.Parent.Shared.Config)
local Types = require(script.Parent.Parent.Shared.Types)

type SlopeSegment = Types.SlopeSegment

-- Create new builder
function SlopeBuilder.new(): SlopeBuilder
	local self = setmetatable({}, SlopeBuilder)
	self.container = nil :: Folder?
	return self
end

-- Initialize container folder in Workspace
function SlopeBuilder:Initialize()
	local container = Workspace:FindFirstChild("SlopeContainer")
	if not container then
		container = Instance.new("Folder")
		container.Name = "SlopeContainer"
		container.Parent = Workspace
	end
	self.container = container
	self:Clear()
end

-- Clear existing slope
function SlopeBuilder:Clear()
	if not self.container then
		return
	end
	
	for _, child in ipairs(self.container:GetChildren()) do
		child:Destroy()
	end
end

-- Build physical parts for a segment
function SlopeBuilder:BuildSegment(segment: SlopeSegment): Model
	local model = Instance.new("Model")
	model.Name = `Segment_{segment.index}`
	
	-- Calculate wedge dimensions
	local delta = segment.endPosition - segment.startPosition
	local distance = delta.Magnitude
	local midpoint = segment.centerPosition
	
	-- Create main slope wedge
	local wedge = Instance.new("WedgePart")
	wedge.Name = "Slope"
	wedge.Size = Vector3.new(segment.width, delta.Y + 2, distance)
	wedge.CFrame = CFrame.new(midpoint, segment.endPosition) * CFrame.Angles(math.pi/2, 0, 0)
	wedge.Anchored = true
	wedge.CanCollide = true
	wedge.Material = Enum.Material.Slate
	wedge.Color = Color3.fromRGB(100, 100, 110)
	wedge.Parent = model
	
	-- Add side walls to prevent falling off
	local wallThickness = 2
	local wallHeight = 20
	
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(wallThickness, wallHeight, distance)
	leftWall.CFrame = wedge.CFrame * CFrame.new(-segment.width/2 - wallThickness/2, wallHeight/2 - 1, 0)
	leftWall.Anchored = true
	leftWall.CanCollide = true
	leftWall.Transparency = 0.7
	leftWall.Color = Color3.fromRGB(80, 80, 90)
	leftWall.Parent = model
	
	local rightWall = leftWall:Clone()
	rightWall.Name = "RightWall"
	rightWall.CFrame = wedge.CFrame * CFrame.new(segment.width/2 + wallThickness/2, wallHeight/2 - 1, 0)
	rightWall.Parent = model
	
	-- Add checkpoint if needed
	if segment.isCheckpoint then
		local checkpoint = self:_CreateCheckpoint(segment)
		checkpoint.Parent = model
	end
	
	-- Tag for CollectionService
	CollectionService:AddTag(model, "SlopeSegment")
	CollectionService:AddTag(wedge, "WalkableSurface")
	
	model.Parent = self.container
	segment.instance = model
	
	return model
end

-- Create checkpoint platform and trigger
function SlopeBuilder:_CreateCheckpoint(segment: SlopeSegment): Part
	local checkpoint = Instance.new("Part")
	checkpoint.Name = "Checkpoint"
	checkpoint.Size = Vector3.new(segment.width - 4, 1, 10)
	checkpoint.CFrame = CFrame.new(segment.endPosition + Vector3.new(0, 2, 0))
	checkpoint.Anchored = true
	checkpoint.CanCollide = true
	checkpoint.Material = Enum.Material.Neon
	checkpoint.Color = Color3.fromRGB(0, 255, 100)
	checkpoint.CanTouch = true
	
	-- Add ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Checkpoint"
	prompt.ActionText = "Reached!"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 20
	prompt.RequiresLineOfSight = false
	prompt.Parent = checkpoint
	
	-- Add particle effect
	local attachment = Instance.new("Attachment")
	attachment.Parent = checkpoint
	
	local particles = Instance.new("ParticleEmitter")
	particles.Rate = 20
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Speed = NumberRange.new(2, 5)
	particles.Size = NumberSequence.new(0.5)
	particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 100))
	particles.Parent = attachment
	
	CollectionService:AddTag(checkpoint, "Checkpoint")
	
	return checkpoint
end

-- Build multiple segments
function SlopeBuilder:BuildSegments(segments: {SlopeSegment})
	if not self.container then
		self:Initialize()
	end
	
	for _, segment in ipairs(segments) do
		self:BuildSegment(segment)
	end
end

-- Destroy builder and cleanup
function SlopeBuilder:Destroy()
	self:Clear()
	if self.container then
		self.container:Destroy()
		self.container = nil
	end
end

export type SlopeBuilder = typeof(setmetatable({} :: any, SlopeBuilder))
return SlopeBuilder
