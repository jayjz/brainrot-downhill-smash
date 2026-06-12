-- HazardTypes.lua
-- Definitions for meme hazard types
--!strict

local HazardTypes = {
	SkibidiToilet = {
		name = "Skibidi Toilet",
		damage = 15,
		knockback = 60,
		size = Vector3.new(4, 6, 4),
		spawnWeight = 0.4,
	},
	
	OhioRizzler = {
		name = "Ohio Rizzler",
		damage = 10,
		knockback = 40,
		size = Vector3.new(2, 5, 2),
		spawnWeight = 0.3,
	},
	
	MemeObject = {
		name = "Viral Meme",
		damage = 8,
		knockback = 30,
		size = Vector3.new(3, 3, 3),
		spawnWeight = 0.3,
	},
}

return HazardTypes
