-- Types.lua
-- Type definitions for Luau strict mode
--!strict

export type PlayerData = {
	userId: number,
	score: number,
	highScore: number,
	checkpointsReached: number,
	totalDistance: number,
	ragdollCount: number,
	skinsOwned: {string},
}

export type HazardType = "SkibidiToilet" | "OhioRizzler" | "MemeObject"

export type HazardData = {
	id: string,
	hazardType: HazardType,
	position: Vector3,
	velocity: Vector3,
	damage: number,
	spawnTime: number,
}

export type SlopeSegment = {
	index: number,
	startPosition: Vector3,
	endPosition: Vector3,
	angle: number,
	width: number,
	hazards: {HazardData},
}

export type RagdollState = {
	isRagdolled: boolean,
	ragdollStartTime: number,
	recoveryTime: number,
	initialVelocity: Vector3,
}

export type GameState = "Waiting" | "Playing" | "Ended"

return {}
