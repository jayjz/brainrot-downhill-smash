-- SlopeGenerator.lua
-- Procedural slope generation using noise and segments
--!strict

local SlopeGenerator = {}
SlopeGenerator.__index = SlopeGenerator

local Config = require(script.Parent.Parent.Shared.Config)

-- Constructor
function SlopeGenerator.new()
	local self = setmetatable({}, SlopeGenerator)
	self.segments = {}
	self.currentHeight = 0
	return self
end

-- Generate a slope segment
function SlopeGenerator:GenerateSegment(index: number): any
	local angle = math.min(
		Config.SLOPE.START_ANGLE + (index * 2),
		Config.SLOPE.MAX_ANGLE
	)
	
	local segment = {
		index = index,
		startPosition = Vector3.new(0, self.currentHeight, -index * Config.SLOPE.SEGMENT_LENGTH),
		endPosition = Vector3.new(0, self.currentHeight + Config.SLOPE.HEIGHT_INCREMENT, -(index + 1) * Config.SLOPE.SEGMENT_LENGTH),
		angle = angle,
		width = Config.SLOPE.SEGMENT_WIDTH,
		hazards = {},
	}
	
	self.currentHeight += Config.SLOPE.HEIGHT_INCREMENT
	table.insert(self.segments, segment)
	
	return segment
end

-- Get segment at height
function SlopeGenerator:GetSegmentAtHeight(height: number): any
	for _, segment in ipairs(self.segments) do
		if height >= segment.startPosition.Y and height <= segment.endPosition.Y then
			return segment
		end
	end
	return nil
end

return SlopeGenerator
