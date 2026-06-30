-- File: src/ReplicatedStorage/Shared/Config.lua
--!strict
-- Central configuration for Brainrot Downhill Smash
-- Source [Lua Style Guide]: https://roblox.github.io/lua-style-guide/
-- Source [Luau Performance]: https://luau-lang.org/performance/

local Config = {}

-- [FIXED]: GameManager.server.lua expects a nested 'GAME' table, not flat variables.
Config.GAME = {
    NAME = "Brainrot Downhill Smash",
    VERSION = "0.1.0-alpha",
}

-- Slope generation
Config.SLOPE = {
    START_ANGLE = 30, -- degrees
    MAX_ANGLE = 85,
    ANGLE_INCREMENT = 2,
    CHECKPOINT_INTERVAL = 5,
    SEGMENT_LENGTH = 100, -- studs
    SEGMENT_WIDTH = 50,
    HEIGHT_INCREMENT = 20,
}

-- Player movement
Config.PLAYER = {
    WALK_SPEED = 16,
    SPRINT_SPEED = 24,
    CLIMB_SPEED = 12,
    CLIMB_SPEED_STEEP = 8,
    JUMP_POWER = 50,
    JUMP_COOLDOWN = 0.5,
    STAMINA_MAX = 100,
    STAMINA_DRAIN_RATE = 15,
    STAMINA_REGEN_RATE = 25,
    RAGDOLL_RECOVERY_TIME = 3, -- seconds
    RAGDOLL_INVULNERABILITY = 1, -- seconds
}

-- Hazards
Config.HAZARDS = {
    BASE_SPAWN_RATE = 2, -- per second at base
    SPAWN_RATE_SCALE = 0.5, -- how much spawn rate increases with height
    MAX_ACTIVE = 20,
    DESPAWN_TIME = 15, -- seconds
    DESPAWN_DISTANCE = 500,
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

-- [FIXED]: GameManager.server.lua requires a REMOTES table to map RemoteEvents safely.
-- Source [RemoteEvent Security]: https://create.roblox.com/docs/scripting/security/remote-events
Config.REMOTES = {
    HAZARD_HIT = "HazardHit",
    PLAYER_SCORED = "PlayerScored",
    RAGDOLL_TRIGGERED = "RagdollTriggered",
    CHECKPOINT_REACHED = "CheckpointReached",
    RAGDOLL_RECOVERED = "RagdollRecovered",
}

-- [OPTIMIZATION]: Freeze tables to prevent accidental runtime mutations. 
-- In Luau, freezing configuration tables ensures strict safety and slight lookup optimizations.
-- Source [Luau Library]: https://luau-lang.org/library#table-library
table.freeze(Config.GAME)
table.freeze(Config.SLOPE)
table.freeze(Config.PLAYER)
table.freeze(Config.HAZARDS)
table.freeze(Config.SCORING)
table.freeze(Config.PHYSICS)
table.freeze(Config.REMOTES)
table.freeze(Config)

return Config