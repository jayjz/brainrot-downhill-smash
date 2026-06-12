-- File: src/StarterPlayer/StarterPlayerScripts/Controllers/MovementController.lua
--!strict
-- Custom movement controller for climbing steep slopes with stamina system
-- Mobile-first with touch support and gamepad compatibility

local MovementController = {}
MovementController.__index = MovementController

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)

local player = Players.LocalPlayer
local character: Model? = nil
local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil

-- Movement state
local movementState = {
	isSprinting = false,
	isClimbing = false,
	isWallRunning = false,
	stamina = Config.PLAYER.STAMINA_MAX,
	lastJumpTime = 0,
	moveDirection = Vector3.zero,
	lookDirection = Vector3.zero,
	currentSlopeAngle = 0,
}

-- Input state
local inputState = {
	forward = 0,
	backward = 0,
	left = 0,
	right = 0,
	jump = false,
	sprint = false,
}

-- Raycast parameters (reused for performance)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {}

-- Initialize controller
function MovementController.Init()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	
	-- Configure humanoid
	humanoid.WalkSpeed = Config.PLAYER.WALK_SPEED
	humanoid.JumpPower = Config.PLAYER.JUMP_POWER
	humanoid.MaxSlopeAngle = 89 -- Allow climbing very steep slopes
	humanoid.AutoRotate = true
	
	-- Set up raycast filter
	raycastParams.FilterDescendantsInstances = {character}
	
	-- Connect input handlers
	MovementController:_SetupInputHandlers()
	
	-- Start update loop
	RunService.RenderStepped:Connect(function(dt)
		MovementController:_Update(dt)
	end)
	
	-- Start stamina regen loop
	task.spawn(function()
		while true do
			MovementController:_UpdateStamina(1/30)
			task.wait(1/30)
		end
	end)
	
	print("[MovementController] Initialized")
end

-- Set up input handling for all platforms
function MovementController:_SetupInputHandlers()
	-- Keyboard input
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		
		if input.KeyCode == Enum.KeyCode.W then
			inputState.forward = 1
		elseif input.KeyCode == Enum.KeyCode.S then
			inputState.backward = 1
		elseif input.KeyCode == Enum.KeyCode.A then
			inputState.left = 1
		elseif input.KeyCode == Enum.KeyCode.D then
			inputState.right = 1
		elseif input.KeyCode == Enum.KeyCode.Space then
			inputState.jump = true
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			inputState.sprint = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.W then
			inputState.forward = 0
		elseif input.KeyCode == Enum.KeyCode.S then
			inputState.backward = 0
		elseif input.KeyCode == Enum.KeyCode.A then
			inputState.left = 0
		elseif input.KeyCode == Enum.KeyCode.D then
			inputState.right = 0
		elseif input.KeyCode == Enum.KeyCode.Space then
			inputState.jump = false
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			inputState.sprint = false
		end
	end)
	
	-- Mobile touch controls via ContextActionService
	local function handleMoveForward(actionName, state, input)
		if state == Enum.UserInputState.Begin then
			inputState.forward = 1
		elseif state == Enum.UserInputState.End then
			inputState.forward = 0
		end
		return Enum.ContextActionResult.Pass
	end
	
	local function handleJump(actionName, state, input)
		if state == Enum.UserInputState.Begin then
			inputState.jump = true
			task.wait(0.1)
			inputState.jump = false
		end
		return Enum.ContextActionResult.Pass
	end
	
	ContextActionService:BindAction("MoveForward", handleMoveForward, true, Enum.KeyCode.ButtonR2)
	ContextActionService:BindAction("Jump", handleJump, true, Enum.KeyCode.ButtonA)
	
	-- Set mobile buttons if on touch device
	if UserInputService.TouchEnabled then
		ContextActionService:SetPosition("MoveForward", UDim2.new(0.8, 0, 0.7, 0))
		ContextActionService:SetPosition("Jump", UDim2.new(0.9, 0, 0.5, 0))
	end
end

-- Main update loop (called every frame)
function MovementController:_Update(dt: number)
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end
	
	-- Calculate movement direction
	local moveVector = Vector3.new(
		inputState.right - inputState.left,
		0,
		inputState.backward - inputState.forward
	)
	
	if moveVector.Magnitude > 0 then
		moveVector = moveVector.Unit
	end
	
	movementState.moveDirection = moveVector
	
	-- Detect slope angle via raycast (1 raycast per frame max)
	local slopeAngle = MovementController:_DetectSlopeAngle()
	movementState.currentSlopeAngle = slopeAngle
	
	-- Update movement based on slope
	MovementController:_UpdateMovementSpeed(slopeAngle)
	
	-- Handle wall-run detection
	if MovementController:_CanWallRun() then
		MovementController:_StartWallRun()
	else
		MovementController:_StopWallRun()
	end
	
	-- Handle jumping
	if inputState.jump and MovementController:_CanJump() then
		MovementController:_PerformJump()
	end
	
	-- Update stamina drain
	if movementState.isSprinting or movementState.isClimbing then
		movementState.stamina = math.max(0, movementState.stamina - Config.PLAYER.STAMINA_DRAIN_RATE * dt)
		if movementState.stamina <= 0 then
			movementState.isSprinting = false
		end
	end
end

-- Detect slope angle using single raycast
function MovementController:_DetectSlopeAngle(): number
	if not rootPart then
		return 0
	end
	
	local origin = rootPart.Position
	local direction = Vector3.new(0, -10, 0)
	
	local result = workspace:Raycast(origin, direction, raycastParams)
	if not result then
		return 0
	end
	
	local normal = result.Normal
	local angle = math.deg(math.acos(normal:Dot(Vector3.yAxis)))
	
	return angle
end

-- Update movement speed based on slope angle and stamina
function MovementController:_UpdateMovementSpeed(slopeAngle: number)
	if not humanoid then
		return
	end
	
	local baseSpeed = Config.PLAYER.WALK_SPEED
	local isOnSlope = slopeAngle > 5
	
	-- Check if sprinting (and has stamina)
	movementState.isSprinting = inputState.sprint and movementState.stamina > 0 and not isOnSlope
	
	if movementState.isSprinting then
		humanoid.WalkSpeed = Config.PLAYER.SPRINT_SPEED
		movementState.isClimbing = false
	elseif isOnSlope then
		-- Reduce speed on slopes, more reduction on steeper slopes
		movementState.isClimbing = true
		local slopeFactor = math.clamp(slopeAngle / 60, 0, 1)
		local climbSpeed = Config.PLAYER.CLIMB_SPEED
		
		if slopeAngle > 60 then
			climbSpeed = Config.PLAYER.CLIMB_SPEED_STEEP
		end
		
		humanoid.WalkSpeed = climbSpeed * (1 - slopeFactor * 0.5)
	else
		movementState.isClimbing = false
		humanoid.WalkSpeed = baseSpeed
	end
end

-- Check if player can wall-run
function MovementController:_CanWallRun(): boolean
	if not rootPart or not humanoid then
		return false
	end
	
	-- Must be moving forward and in air
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		return false
	end
	
	if movementState.moveDirection.Z >= 0 then
		return false
	end
	
	-- Raycast to sides to detect walls
	local origin = rootPart.Position
	local rightDirection = rootPart.CFrame.RightVector * 3
	local leftDirection = -rightDirection
	
	local rightResult = workspace:Raycast(origin, rightDirection, raycastParams)
	local leftResult = workspace:Raycast(origin, leftDirection, raycastParams)
	
	return rightResult ~= nil or leftResult ~= nil
end

-- Start wall-run state
function MovementController:_StartWallRun()
	if movementState.isWallRunning then
		return
	end
	
	movementState.isWallRunning = true
	
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
	end
	
	-- Apply upward force to maintain height
	if rootPart then
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "WallRunVelocity"
		bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
		bodyVelocity.Velocity = Vector3.new(0, 5, 0)
		bodyVelocity.Parent = rootPart
		
		task.delay(1.5, function()
			if bodyVelocity then
				bodyVelocity:Destroy()
			end
			movementState.isWallRunning = false
		end)
	end
end

-- Stop wall-run state
function MovementController:_StopWallRun()
	if not movementState.isWallRunning then
		return
	end
	
	movementState.isWallRunning = false
	
	if rootPart then
		local velocity = rootPart:FindFirstChild("WallRunVelocity")
		if velocity then
			velocity:Destroy()
		end
	end
	
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	end
end

-- Check if player can jump (cooldown + stamina)
function MovementController:_CanJump(): boolean
	local now = os.clock()
	if now - movementState.lastJumpTime < Config.PLAYER.JUMP_COOLDOWN then
		return false
	end
	
	if movementState.stamina < 10 then
		return false
	end
	
	return true
end

-- Perform jump with stamina cost
function MovementController:_PerformJump()
	if not humanoid then
		return
	end
	
	movementState.lastJumpTime = os.clock()
	movementState.stamina = math.max(0, movementState.stamina - 10)
	
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

-- Update stamina regeneration
function MovementController:_UpdateStamina(dt: number)
	if movementState.isSprinting or movementState.isClimbing then
		return
	end
	
	if movementState.stamina < Config.PLAYER.STAMINA_MAX then
		movementState.stamina = math.min(
			Config.PLAYER.STAMINA_MAX,
			movementState.stamina + Config.PLAYER.STAMINA_REGEN_RATE * dt
		)
	end
end

-- Get current stamina (for UI)
function MovementController.GetStamina(): number
	return movementState.stamina / Config.PLAYER.STAMINA_MAX
end

-- Get current slope angle (for UI/effects)
function MovementController.GetSlopeAngle(): number
	return movementState.currentSlopeAngle
end

-- Check if climbing
function MovementController.IsClimbing(): boolean
	return movementState.isClimbing
end

-- Initialize when script runs
MovementController.Init()

return MovementController
