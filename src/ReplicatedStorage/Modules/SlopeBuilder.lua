-- File: src/ReplicatedStorage/Modules/SlopeBuilder.lua
--!strict
-- Builds physical slope parts in Workspace from SlopeGenerator data
-- Optimized for mathematical precision and continuous, smooth surfaces.
-- Source [Rojo Project Format]: https://rojo.space/docs/v7/project-format

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

-- Build physical parts for a segment with precise 3D math
-- Ensures segments connect seamlessly regardless of angle changes.
function SlopeBuilder:BuildSegment(segment: SlopeSegment): Model
	local model = Instance.new("Model")
	model.Name = `Segment_{segment.index}`
	
	local startPos = segment.startPosition
	local endPos = segment.endPosition
	local delta = endPos - startPos
	local distance = delta.Magnitude
	local center = segment.centerPosition
	
	-- [GEOMETRY FIX]: Using tilted Part for the walkable surface.
	-- WedgeParts create "stepping" artifacts at angle transitions. 
	-- A Part aligned via CFrame.lookAt creates a mathematically perfect continuous slope.
	local slope = Instance.new("Part")
	slope.Name = "Slope"
	slope.Size = Vector3.new(segment.width, 4, distance) -- Thick base for "solid" look
	-- Align part so it stretches from startPos to endPos
	slope.CFrame = CFrame.lookAt(center, endPos)
	slope.Anchored = true
	slope.CanCollide = true
	slope.TopSurface = Enum.SurfaceType.Smooth
	slope.Material = Enum.Material.Slate
	slope.Color = Color3.fromRGB(100, 100, 110)
	slope.Parent = model
	
	-- Side Walls (Contained gameplay area)
	local wallHeight = 25
	local wallThickness = 2
	
	local leftWall = Instance.new("Part")
	leftWall.Name = "LeftWall"
	leftWall.Size = Vector3.new(wallThickness, wallHeight, distance)
	-- Offset left from the slope's center
	leftWall.CFrame = slope.CFrame * CFrame.new(-segment.width/2 - wallThickness/2, wallHeight/2 - 2, 0)
	leftWall.Anchored = true
	leftWall.CanCollide = true
	leftWall.Transparency = 0.8
	leftWall.CastShadow = false
	leftWall.Color = Color3.fromRGB(150, 150, 180)
	leftWall.Parent = model
	
	local rightWall = leftWall:Clone()
	rightWall.Name = "RightWall"
	rightWall.CFrame = slope.CFrame * CFrame.new(segment.width/2 + wallThickness/2, wallHeight/2 - 2, 0)
	rightWall.Parent = model
	
	-- Checkpoint handling
	if segment.isCheckpoint then
		self:_CreateCheckpoint(segment, model)
	end
	
	-- Metadata and Tags
	CollectionService:AddTag(model, "SlopeSegment")
	CollectionService:AddTag(slope, "WalkableSurface")
	
	model.Parent = self.container
	segment.instance = model
	
	return model
end

-- Create checkpoint platform and logic
function SlopeBuilder:_CreateCheckpoint(segment: SlopeSegment, parent: Model)
	local checkpoint = Instance.new("Part")
	checkpoint.Name = "Checkpoint"
	checkpoint.Size = Vector3.new(segment.width, 1, 15)
	-- Place at the end of the segment, slightly above the surface
	checkpoint.CFrame = CFrame.new(segment.endPosition + Vector3.new(0, 0.6, 0))
	checkpoint.Anchored = true
	checkpoint.CanCollide = false -- Trigger only
	checkpoint.Transparency = 0.5
	checkpoint.Material = Enum.Material.Neon
	checkpoint.Color = Color3.fromRGB(0, 255, 150)
	checkpoint.Parent = parent
	
	local attachment = Instance.new("Attachment")
	attachment.Parent = checkpoint
	
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://244221440"
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 10)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Parent = attachment
	
	CollectionService:AddTag(checkpoint, "Checkpoint")
end

-- Build multiple segments in batch
function SlopeBuilder:BuildSegments(segments: {SlopeSegment})
	if not self.container then
		self:Initialize()
	end
	
	for _, segment in ipairs(segments) do
		self:BuildSegment(segment)
	end
end

-- Cleanup
function SlopeBuilder:Destroy()
	self:Clear()
	if self.container then
		self.container:Destroy()
		self.container = nil
	end
end

export type SlopeBuilder = typeof(setmetatable({} :: any, SlopeBuilder))
return SlopeBuilder
