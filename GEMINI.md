# GEMINI.md - Brainrot Downhill Smash

**Project:** Short-session viral Roblox physics chaos runner. Climb a steepening procedural slope, dodge meme hazards, and tumble downhill with momentum carry-over. Built for clip-ability and retention.
**Status (June 2026):** 0.1.0-alpha — Phase 1 stable. Phase 2 (hazards + ragdoll) is partially wired but physics are floaty.

---

## 🛠️ Repository Context & Mapping
Agents must strictly reference these paths for implementation details:
- **Project Structure:** `default.project.json` (Maps Rojo directories to Roblox services)
- **Shared Configuration:** `src/ReplicatedStorage/Shared/Config.lua` (All tunable physical constants)
- **Type Definitions:** `src/ReplicatedStorage/Shared/Types.lua` (`--!strict` signatures)
- **Procedural Logic:** `src/ReplicatedStorage/Modules/SlopeGenerator.lua` & `SlopeBuilder.lua`
- **Physics Controllers:** `src/ReplicatedStorage/Modules/RagdollController.lua` & `src/StarterPlayer/StarterPlayerScripts/Controllers/MovementController.lua`
- **Server Orchestration:** `src/ServerScriptService/GameManager.lua` & `src/ServerScriptService/Services/HazardSpawner.lua`

---

## 📐 Strict Coding Protocol
1. **Type Safety:** Every Luau file must head with `--!strict`. Zero untyped variables or `any` fallbacks allowed.
2. **Resource Management:** Every `game:GetService()` call must live at the top of the file. All event connections (`:Connect()`) must return a RBXScriptConnection stored for clean disposal upon instance destruction.
3. **No Client Authority:** The client only sends input intents via RemoteEvents. The server calculates hit registration, vector forces, and validates positioning against physics exploits.
4. **No Legacy APIs:** Do not use `wait()`, `delay()`, or `spawn()`. Use `task.wait()`, `task.delay()`, and `task.defer()`.

---

## 🎯 Immediate Loop Objective: Physics & Ragdoll Overhaul
- **Current Deficit:** Ragdolls feel lightweight, floaty, and fail to translate downhill velocity into rotational momentum during a collision.
- **Next Coding Step:** Rewrite `RagdollController.lua` to strip standard humanoid states using `Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)` and swap joint connections with highly tuned `BallSocketConstraints`.
- **Reference Constraints:** Match force application logic found in `src/ServerScriptService/Services/HazardCollisionDetector.lua`.

---

## 📚 Knowledge Base Links
- **Source Repository:** https://github.com/jayjz/brainrot-downhill-smash
- **Code Reference:** https://github.com/jayjz/brainrot-downhill-smash/tree/main/src
- **Style Foundations:** https://hackmd.io/@aquaisaquafina/aquas_luau_style_guide
- **Local Context Integration:** `C:\hermes-agents\lifeOS\RobloxDev\`
