-- Config.lua
-- Central configuration for Brainrot Downhill Smash
-- Follows Roblox Lua Style Guide: https://roblox.github.io/lua-style-guide/

local Config = {}

-- Game constants
Config.GAME_NAME = "Brainrot Downhill Smash"
Config.VERSION = "0.1.0-alpha"

-- Slope generation
Config.SLOPE = {
	START_ANGLE = 30, -- degrees
	MAX_ANGLE = 85,
	SEGMENT_LENGTH = 100, -- studs
	SEGMENT_WIDTH = 50,
	HEIGHT_INCREMENT = 20,
}

-- Player movement
Config.PLAYER = {
	WALK_SPEED = 16,
	CLIMB_SPEED = 12,
	JUMP_POWER = 50,
	RAGDOLL_RECOVERY_TIME = 3, -- seconds
}

-- Hazards
Config.HAZARDS = {
	SPAWN_RATE = 2, -- per second at base
	MAX_ACTIVE = 20,
	DESPWN_DISTANCE = 500,
	BASE_DAMAGE = 10,
}

-- Scoring
Config.SCORING = {
	CHECKPOINT_VALUE = 100,
	HEIGHT_MULTIPLIER = 1.5,
	TIME_BONUS = 10,
}

-- Physics
Config.PHYSICS = {
	RAGDOLL_FORCE_MULTIPLIER = 1.5,
	KNOCKBACK_BASE = 50,
	SLOW_MO_DURATION = 0.5,
}

return Config
