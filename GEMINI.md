# GEMINI.md - Brainrot Downhill Smash

**Project:** A short-session viral Roblox physics chaos runner. Climb a steepening procedural slope while dodging brainrot meme hazards. One hit = satisfying ragdoll tumble downhill with momentum. Built for clip-ability and replayability.

**Status (as of June 15, 2026):** 0.1.0-alpha — Phase 1 (slope + movement) complete and integrated. Phase 2 (hazards + ragdoll) ~60-70% wired (files exist, integration fixes pushed, client listener pending full verification). Playable vertical slice exists but needs heavy tuning for fun factor.

## Core Loop (Target <30s sessions)
1. Spawn at base of massive procedural slope (gradient 30° → 80°+).
2. Climb using stamina-based movement (mobile/gamepad optimized).
3. Dodge procedurally spawned meme hazards (Skibidi Toilet, Ohio Rizzler, etc.).
4. Hit → full ragdoll tumble downhill with physics carry-over.
5. Recover, climb again, or wipe out. Score based on height/checkpoints.

## Tech Stack
- **Rojo 7+** for external Luau development.
- Strict Luau (`--!strict`), R15 characters.
- Procedural generation (SlopeGenerator + SlopeBuilder).
- Custom ragdoll via constraints.
- RemoteEvents with validation/rate limiting.
- StreamingEnabled planned for perf.

## Key Files & Responsibilities
**Core Modules (ReplicatedStorage/Modules):**
- `SlopeGenerator.lua`: Math for progressive steepening.
- `SlopeBuilder.lua`: Physical wedge/part generation.
- `RagdollController.lua`: Client ragdoll logic (BallSocketConstraints etc.).
- `HazardTypes.lua`: Meme hazard definitions + asset IDs.

**Shared (ReplicatedStorage/Shared):**
- `Config.lua`: All tunable values (no magic numbers).
- `Types.lua`: Type definitions.

**Server (ServerScriptService):**
- `GameManager.lua`: Main orchestration, round lifecycle.
- `Services/HazardSpawner.lua`, `HazardCollisionDetector.lua`: Spawning + Touched events + knockback.

**Client (StarterPlayerScripts/Controllers):**
- MovementController, CameraController, etc.

## Current Strengths
- Solid procedural slope math and config-driven design.
- Performance-aware (single raycast slope detection).
- Good self-audit via MEMORY.md.
- Mobile-first controls via ContextActionService.

## Brutal Gaps (Reality Check)
- Ragdoll/knockback feel is floaty/untuned — core chaos missing.
- Hazard spawning/positioning needs raycast validation to avoid slope embeds.
- UI/feedback (stamina bar, score, particles, sounds, screen shake) minimal.
- No server movement validation yet (exploit risk).
- Asset placeholders dominate; visual polish is zero.
- No playtesting data beyond Studio — fun factor unproven.

## Roadmap Priorities
1. **Immediate:** Full client ragdoll listener + Studio verification of hit → tumble loop.
2. **Short-term:** Tune physics, add juice, basic UI/score.
3. **Phase 3+:** Leaderboards, shop, multiplayer chaos, optimization.

**Setup:**
```bash
cargo install rojo
rojo serve
## Connect Studio to localhost:34872


## Knowledge:
https://github.com/jayjz/brainrot-downhill-smash
https://github.com/jayjz/brainrot-downhill-smash/blob/main/README.md
https://github.com/jayjz/brainrot-downhill-smash/blob/main/MEMORY.md
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src
https://github.com/jayjz/brainrot-downhill-smash/blob/main/default.project.json
https://github.com/jayjz/brainrot-downhill-smash/blob/main/.gitignore
https://github.com/jayjz/brainrot-downhill-smash/commits/main
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/ServerScriptService
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ServerScriptService/GameManager.lua
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/ServerScriptService/Services
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ServerScriptService/Services/HazardSpawner.lua
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ServerScriptService/Services/HazardCollisionDetector.lua
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/ReplicatedStorage
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/ReplicatedStorage/Modules
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Modules/SlopeGenerator.lua
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Modules/SlopeBuilder.lua
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Modules/RagdollController.lua
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Modules/HazardTypes.lua
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/ReplicatedStorage/Shared
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Shared/Config.lua
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Shared/Types.lua
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/StarterPlayer/StarterPlayerScripts/Controllers
https://github.com/jayjz/brainrot-downhill-smash/commits/main/src
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/StarterPlayer
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ServerScriptService/Services/RagdollService.lua (if present; inferred from structure)
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ServerScriptService/Services/LeaderboardService.lua (inferred)
https://github.com/jayjz/brainrot-downhill-smash/commit/ad49b6266ed734b9d885980a9dd78e15187b4ab6 (fixing AI slop)
https://github.com/jayjz/brainrot-downhill-smash/commit/7641b147f4ed76a96aea48896c899ac991f6e061 (Phase 2 ragdoll)
https://github.com/jayjz/brainrot-downhill-smash/commit/38f5a21acfab2da97f6d26c0161efadaa3504e3a (integration fix)
https://github.com/jayjz/brainrot-downhill-smash/commit/03d6296abd236e7fac2894d91ada7023a57b85e4 (hazards system)
https://github.com/jayjz/brainrot-downhill-smash/commit/9fd562e009f931899a29bd4a95f86d1396058572 (MEMORY.md)
https://github.com/jayjz/brainrot-downhill-smash/commit/435509667e4404e8036a6db42df72fddf82025ec (slope integration)
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/ReplicatedStorage/Modules (modules dir)
https://github.com/jayjz/brainrot-downhill-smash/tree/main/src/ServerScriptService/Services (services dir)
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Modules/HazardTypes.lua
https://github.com/jayjz/brainrot-downhill-smash/graphs/contributors
https://github.com/jayjz/brainrot-downhill-smash/releases
https://github.com/jayjz/brainrot-downhill-smash/issues
https://github.com/jayjz/brainrot-downhill-smash/pulls
https://github.com/jayjz/brainrot-downhill-smash/settings
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/StarterPlayer/StarterPlayerScripts/Controllers/MovementController.lua (inferred core)
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua (inferred)
https://github.com/jayjz/brainrot-downhill-smash/search?q=extension%3Alua&type=code
https://github.com/jayjz/brainrot-downhill-smash/search?l=lua
https://github.com/jayjz/brainrot-downhill-smash/network
https://github.com/jayjz/brainrot-downhill-smash/stargazers
https://github.com/jayjz/brainrot-downhill-smash/forks
https://github.com/jayjz/brainrot-downhill-smash/blob/main/src/ReplicatedStorage/Modules/SlopeBuilder.lua
https://github.com/jayjz/brainrot-downhill-smash/commit/20f1a3484e6138212f08873e271a05a04fdbbd1b (Phase 0 complete)
https://github.com/jayjz/brainrot-downhill-smash/commit/47c78d0f5b504d8574dc2ef96cec4907b171ac6f (initial setup)
