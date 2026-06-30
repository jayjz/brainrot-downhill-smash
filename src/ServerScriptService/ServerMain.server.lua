-- ServerMain.server.lua
--!strict
-- Server entry point for Brainrot Downhill Smash
-- Bootstraps GameManager and handles server lifecycle

local GameManager = require(script.Parent.GameManager)

print("[ServerMain] Bootstrapping server...")

local success, err = pcall(function()
	GameManager:Init()
end)

if success then
	print("[ServerMain] Server successfully bootstrapped — GameManager ready")
else
	warn(`[ServerMain] Bootstrap failed: {err}`)
end

-- Cleanup on game shutdown
game:BindToClose(function()
	print("[ServerMain] Game closing — cleaning up")
	if typeof(GameManager.Destroy) == "function" then
		pcall(GameManager.Destroy)
	end
end)
