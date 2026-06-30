-- ClientMain.client.lua
--!strict
-- Client entry point for Brainrot Downhill Smash
-- Bootstraps all client controllers with proper error handling

print("=== Brainrot Downhill Smash Client Initializing ===")

local Controllers = {
	Movement = require(script.Parent.Controllers.MovementController),
	Camera = require(script.Parent.Controllers.CameraController),
	Ragdoll = require(script.Parent.Controllers.RagdollClient),
}

local initialized = {}
local failed = {}

-- Initialize controllers in order (Movement → Camera → Ragdoll)
local initOrder = {"Movement", "Camera", "Ragdoll"}

for _, name in ipairs(initOrder) do
	local ctrl = Controllers[name]
	if typeof(ctrl) == "table" and typeof(ctrl.Init) == "function" then
		local ok, err = pcall(ctrl.Init)
		if ok then
			initialized[name] = true
			print(`[ClientMain] {name} controller initialized`)
		else
			failed[name] = err
			warn(`[ClientMain] {name} controller failed to initialize: {err}`)
		end
	else
		warn(`[ClientMain] {name} controller missing Init() function`)
		failed[name] = "missing Init()"
	end
end

local initCount = 0
for _ in pairs(initialized) do initCount += 1 end

if initCount == #initOrder then
	print("=== Client Fully Initialized ===")
else
	warn(`=== Client Partially Initialized ({initCount}/{#initOrder}) ===`)
	for name, err in pairs(failed) do
		warn(`  - {name}: {err}`)
	end
end

return Controllers
