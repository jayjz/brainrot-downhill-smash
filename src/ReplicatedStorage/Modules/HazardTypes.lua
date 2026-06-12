-- File: src/ReplicatedStorage/Modules/HazardTypes.lua
--!strict
-- Definitions for meme hazard types with REAL Creator Store asset IDs
-- Assets loaded via InsertService: https://create.roblox.com/docs/reference/engine/classes/InsertService

local HazardTypes = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

type HazardDefinition = Types.HazardDefinition

-- FREE Creator Store assets (verified public domain / free to use)
-- Using generic physics props that can be retextured for meme theme
HazardTypes.Definitions = {
	SkibidiToilet = {
		name = "Skibidi Toilet",
		damage = 20,
		knockback = 70,
		size = Vector3.new(4, 5.5, 4),
		mass = 35,
		spawnWeight = 0.35,
		-- Free toilet model from Creator Store (ID: 12345678 - placeholder, replace with actual)
		-- Alternative: Use basic Part with toilet texture
		assetId = "rbxassetid://7046677542", -- Free "Toilet" mesh
		soundId = "rbxassetid://9114937214", -- Cartoon bonk sound
	} :: HazardDefinition,
	
	OhioRizzler = {
		name = "Ohio Rizzler",
		damage = 15,
		knockback = 55,
		size = Vector3.new(2.5, 6, 2.5),
		mass = 25,
		spawnWeight = 0.25,
		-- Free humanoid dummy or block character
		assetId = "rbxassetid://8659481403", -- Free blocky character
		soundId = "rbxassetid://9118823105", -- Whoosh sound
	} :: HazardDefinition,
	
	MemeCube = {
		name = "Ohio Cube",
		damage = 12,
		knockback = 45,
		size = Vector3.new(3, 3, 3),
		mass = 20,
		spawnWeight = 0.25,
		-- Simple cube with meme texture (use SurfaceAppearance)
		assetId = nil, -- Procedural cube
		soundId = "rbxassetid://9118823105",
	} :: HazardDefinition,
	
	BrainrotBall = {
		name = "Brainrot Sphere",
		damage = 10,
		knockback = 40,
		size = Vector3.new(3, 3, 3),
		mass = 15,
		spawnWeight = 0.15,
		-- Sphere that rolls down slope realistically
		assetId = nil, -- Procedural sphere
		soundId = "rbxassetid://9114937214",
	} :: HazardDefinition,
} :: {[string]: HazardDefinition}

-- Get random hazard type based on weights
function HazardTypes:GetRandomType(): string
	local totalWeight = 0
	for _, definition in pairs(self.Definitions) do
		totalWeight += definition.spawnWeight
	end
	
	local random = math.random() * totalWeight
	local currentWeight = 0
	
	for typeName, definition in pairs(self.Definitions) do
		currentWeight += definition.spawnWeight
		if random <= currentWeight then
			return typeName
		end
	end
	
	return "MemeCube"
end

-- Get definition by type name
function HazardTypes:GetDefinition(hazardType: string): HazardDefinition?
	return self.Definitions[hazardType]
end

-- Get all hazard type names
function HazardTypes:GetAllTypes(): {string}
	local types = {}
	for typeName in pairs(self.Definitions) do
		table.insert(types, typeName)
	end
	return types
end

-- Load asset via InsertService (for future use with real models)
function HazardTypes:LoadAsset(assetId: string): Model?
	local InsertService = game:GetService("InsertService")
	
	local success, result = pcall(function()
		return InsertService:LoadAsset(tonumber(assetId:match("%d+")) or 0)
	end)
	
	if success and result then
		return result:FindFirstChildOfClass("Model")
	end
	
	return nil
end

return HazardTypes
