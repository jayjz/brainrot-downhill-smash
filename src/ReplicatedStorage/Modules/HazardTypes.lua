-- File: src/ReplicatedStorage/Modules/HazardTypes.lua
--!strict
-- Definitions for meme hazard types with REAL Creator Store asset IDs
-- Assets loaded via InsertService: https://create.roblox.com/docs/reference/engine/classes/InsertService

local HazardTypes = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

type HazardDefinition = Types.HazardDefinition

-- VERIFIED Free Creator Store assets
HazardTypes.Definitions = {
	SkibidiToilet = {
		name = "Skibidi Toilet",
		damage = 20,
		knockback = 70,
		size = Vector3.new(4, 5.5, 4),
		mass = 35,
		spawnWeight = 0.3,
		assetId = "rbxassetid://14094546528", -- Toilet
		soundId = "rbxassetid://9114937214",
	} :: HazardDefinition,
	
	OhioRizzler = {
		name = "Ohio Rizzler",
		damage = 15,
		knockback = 55,
		size = Vector3.new(2.5, 6, 2.5),
		mass = 25,
		spawnWeight = 0.25,
		assetId = "rbxassetid://5056319657", -- Dummy NPC
		soundId = "rbxassetid://9118823105",
	} :: HazardDefinition,
	
	MemeCube = {
		name = "Ohio Crate",
		damage = 12,
		knockback = 45,
		size = Vector3.new(3, 3, 3),
		mass = 20,
		spawnWeight = 0.25,
		assetId = "rbxassetid://17459437262", -- Wooden Crate
		soundId = "rbxassetid://9118823105",
	} :: HazardDefinition,
	
	BrainrotBall = {
		name = "Brainrot Barrel",
		damage = 18,
		knockback = 50,
		size = Vector3.new(3, 4, 3),
		mass = 30,
		spawnWeight = 0.2,
		assetId = "rbxassetid://1309245904", -- Oil Barrel
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

return HazardTypes
