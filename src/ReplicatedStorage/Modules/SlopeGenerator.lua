-- File: src/ReplicatedStorage/Modules/SlopeGenerator.lua
--!strict
-- Procedural slope generation using mathematical progression
-- Generates segment data - does NOT create physical instances

local SlopeGenerator = {}
SlopeGenerator.__index = SlopeGenerator

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

type SlopeSegment = Types.SlopeSegment

-- Create new generator instance
function SlopeGenerator.new(): SlopeGenerator
	local self = setmetatable({}, SlopeGenerator)
	
	self.segments = {} :: {SlopeSegment}
	self.currentHeight = 0 :: number
	self.currentZ = 0 :: number
	self.seed = tick() :: number
	
	return self
end

-- Generate a single slope segment with calculated geometry
function SlopeGenerator:GenerateSegment(index: number): SlopeSegment
	-- Calculate progressive angle (starts shallow, gets steeper)
	local startAngle = math.min(
		Config.SLOPE.START_ANGLE + (index * Config.SLOPE.ANGLE_INCREMENT),
		Config.SLOPE.MAX_ANGLE - Config.SLOPE.ANGLE_INCREMENT
	)
	local endAngle = math.min(
		startAngle + Config.SLOPE.ANGLE_INCREMENT,
		Config.SLOPE.MAX_ANGLE
	)
	
	-- Convert to radians for math
	local startRad = math.rad(startAngle)
	local endRad = math.rad(endAngle)
	local avgRad = (startRad + endRad) / 2
	
	-- Calculate positions using trigonometry
	local startPos = Vector3.new(0, self.currentHeight, self.currentZ)
	local deltaY = Config.SLOPE.HEIGHT_INCREMENT
	local deltaZ = -Config.SLOPE.SEGMENT_LENGTH * math.cos(avgRad)
	
	self.currentHeight += deltaY
	self.currentZ += deltaZ
	
	local endPos = Vector3.new(0, self.currentHeight, self.currentZ)
	local centerPos = (startPos + endPos) / 2
	
	-- Create segment data structure
	local segment: SlopeSegment = {
		index = index,
		startPosition = startPos,
		endPosition = endPos,
		startAngle = startAngle,
		endAngle = endAngle,
		width = Config.SLOPE.SEGMENT_WIDTH,
		length = Config.SLOPE.SEGMENT_LENGTH,
		centerPosition = centerPos,
		instance = nil,
		hazards = {},
		isCheckpoint = (index % Config.SLOPE.CHECKPOINT_INTERVAL == 0) and index > 0,
	}
	
	table.insert(self.segments, segment)
	return segment
end

-- Generate multiple segments at once
function SlopeGenerator:GenerateSegments(count: number, startIndex: number?): {SlopeSegment}
	local generated = {}
	local start = startIndex or #self.segments
	
	for i = 1, count do
		local segment = self:GenerateSegment(start + i)
		table.insert(generated, segment)
	end
	
	return generated
end

-- Get segment containing a specific world position
function SlopeGenerator:GetSegmentAtPosition(position: Vector3): SlopeSegment?
	for _, segment in ipairs(self.segments) do
		local minZ = math.min(segment.startPosition.Z, segment.endPosition.Z)
		local maxZ = math.max(segment.startPosition.Z, segment.endPosition.Z)
		local minY = math.min(segment.startPosition.Y, segment.endPosition.Y) - 10
		local maxY = math.max(segment.startPosition.Y, segment.endPosition.Y) + 10
		
		if position.Z >= minZ and position.Z <= maxZ and position.Y >= minY and position.Y <= maxY then
			return segment
		end
	end
	return nil
end

-- Get segment by index
function SlopeGenerator:GetSegment(index: number): SlopeSegment?
	return self.segments[index]
end

-- Get total generated height
function SlopeGenerator:GetTotalHeight(): number
	return self.currentHeight
end

-- Get total segment count
function SlopeGenerator:GetSegmentCount(): number
	return #self.segments
end

-- Reset generator (for new round)
function SlopeGenerator:Reset()
	self.segments = {}
	self.currentHeight = 0
	self.currentZ = 0
	self.seed = tick()
end

export type SlopeGenerator = typeof(setmetatable({} :: any, SlopeGenerator))
return SlopeGenerator
