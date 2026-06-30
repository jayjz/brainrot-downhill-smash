-- File: src/StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua
--!strict
-- Dynamic third-person camera with collision avoidance, FOV scaling, and screen shake

local CameraController = {}
CameraController.__index = CameraController

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character: Model? = nil
local rootPart: BasePart? = nil
local humanoid: Humanoid? = nil

-- Camera state
local cameraState = {
	targetCFrame = CFrame.new(),
	currentCFrame = CFrame.new(),
	distance = 12,
	minDistance = 6,
	maxDistance = 20,
	pitch = 15,
	yaw = 0,
	fov = Config.CAMERA.BASE_FOV,
	targetFov = Config.CAMERA.BASE_FOV,
	shakeIntensity = 0,
	shakeEndTime = 0,
	isRagdollMode = false,
}

-- Raycast params for collision
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- Initialize camera controller
function CameraController.Init()
	character = player.Character or player.CharacterAdded:Wait()
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	
	raycastParams.FilterDescendantsInstances = {character}
	
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = cameraState.fov
	
	-- Listen for ragdoll events
	local ragdollRemote = ReplicatedStorage.RemoteEvents:WaitForChild("RagdollTriggered") :: RemoteEvent
	ragdollRemote.OnClientEvent:Connect(function()
		CameraController:EnterRagdollMode()
	end)
	
	-- Start update loop
	RunService.RenderStepped:Connect(function(dt)
		CameraController:_Update(dt)
	end)
	
	print("[CameraController] Initialized")
end

-- Main update loop
function CameraController:_Update(dt: number)
	if not rootPart or not humanoid then
		return
	end
	
	-- Update camera position
	CameraController:_UpdatePosition(dt)
	
	-- Update FOV based on height
	CameraController:_UpdateFOV(dt)
	
	-- Apply screen shake if active
	CameraController:_ApplyShake(dt)
	
	-- Update camera
	camera.CFrame = cameraState.currentCFrame
	camera.FieldOfView = cameraState.fov
end

-- Update camera position with collision avoidance
function CameraController:_UpdatePosition(dt: number)
	if not rootPart then
		return
	end
	
	local targetPos = rootPart.Position + Vector3.new(0, 2, 0)
	local lookVector = rootPart.CFrame.LookVector
	
	-- Calculate desired camera position
	local desiredDistance = cameraState.distance
	local pitchRad = math.rad(cameraState.pitch)
	local yawRad = math.rad(cameraState.yaw)
	
	local offset = Vector3.new(
		math.sin(yawRad) * math.cos(pitchRad) * desiredDistance,
		math.sin(pitchRad) * desiredDistance,
		math.cos(yawRad) * math.cos(pitchRad) * desiredDistance
	)
	
	-- Account for character rotation
	offset = rootPart.CFrame:VectorToWorldSpace(offset)
	
	local desiredPosition = targetPos + offset
	
	-- Collision detection - raycast from target to camera
	local direction = (desiredPosition - targetPos)
	local distance = direction.Magnitude
	
	if distance > 0 then
		local result = workspace:Raycast(targetPos, direction, raycastParams)
		
		if result then
			-- Hit something, move camera closer
			local hitDistance = (result.Position - targetPos).Magnitude
			desiredDistance = math.max(cameraState.minDistance, hitDistance - 1)
			
			-- Recalculate position with adjusted distance
			offset = offset.Unit * desiredDistance
			desiredPosition = targetPos + offset
		end
	end
	
	-- Smooth interpolation
	local targetCFrame = CFrame.lookAt(desiredPosition, targetPos)
	cameraState.targetCFrame = targetCFrame
	
	local smoothness = cameraState.isRagdollMode and 0.08 or Config.CAMERA.FOLLOW_SMOOTHNESS
	cameraState.currentCFrame = cameraState.currentCFrame:Lerp(targetCFrame, smoothness)
end

-- Update FOV based on player height
function CameraController:_UpdateFOV(dt: number)
	if not rootPart then
		return
	end
	
	local height = rootPart.Position.Y
	local heightFactor = height * Config.CAMERA.FOV_HEIGHT_SCALE
	
	cameraState.targetFov = math.clamp(
		Config.CAMERA.BASE_FOV + heightFactor,
		Config.CAMERA.BASE_FOV,
		Config.CAMERA.MAX_FOV
	)
	
	-- Smooth FOV transition
	cameraState.fov = cameraState.fov + (cameraState.targetFov - cameraState.fov) * dt * 2
end

-- Apply screen shake effect
function CameraController:_ApplyShake(dt: number)
	local now = os.clock()
	
	if now > cameraState.shakeEndTime then
		cameraState.shakeIntensity = 0
		return
	end
	
	if cameraState.shakeIntensity <= 0 then
		return
	end
	
	-- Generate Perlin-style shake
	local shakeX = (math.noise(now * 50, 0, 0) - 0.5) * 2 * cameraState.shakeIntensity
	local shakeY = (math.noise(0, now * 50, 0) - 0.5) * 2 * cameraState.shakeIntensity
	local shakeZ = (math.noise(0, 0, now * 50) - 0.5) * 2 * cameraState.shakeIntensity
	
	local shakeOffset = Vector3.new(shakeX, shakeY, shakeZ)
	cameraState.currentCFrame = cameraState.currentCFrame * CFrame.new(shakeOffset)
	
	-- Decay shake intensity
	local timeRemaining = cameraState.shakeEndTime - now
	local progress = timeRemaining / Config.CAMERA.SHAKE_DURATION
	cameraState.shakeIntensity = cameraState.shakeIntensity * progress
end

-- Trigger screen shake
function CameraController:Shake(intensity: number?, duration: number?)
	local shakeIntensity = intensity or Config.CAMERA.SHAKE_INTENSITY_LIGHT
	local shakeDuration = duration or Config.CAMERA.SHAKE_DURATION
	
	cameraState.shakeIntensity = math.max(cameraState.shakeIntensity, shakeIntensity)
	cameraState.shakeEndTime = os.clock() + shakeDuration
end

-- Enter ragdoll camera mode (cinematic follow)
function CameraController:EnterRagdollMode()
	cameraState.isRagdollMode = true
	cameraState.distance = 8
	CameraController:Shake(Config.CAMERA.SHAKE_INTENSITY_HEAVY, 0.5)
	
	task.delay(3, function()
		cameraState.isRagdollMode = false
		cameraState.distance = 12
	end)
end

-- Set camera distance (for zoom)
function CameraController:SetDistance(distance: number)
	cameraState.distance = math.clamp(distance, cameraState.minDistance, cameraState.maxDistance)
end

-- Get current camera CFrame
function CameraController:GetCFrame(): CFrame
	return cameraState.currentCFrame
end


return CameraController
