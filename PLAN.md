# PLAN.md - Brainrot Downhill Smash

## Project Overview
Viral meme physics chaos runner. Climb a steep procedural slope while dodging physics-based meme hazards (Skibidi Toilets, Ohio Rizzlers, etc.). Get hit → full ragdoll tumble with momentum carry-over. Pure chaos, 30-second core loop.

**Tech Stack:** Rojo 7.4+, Luau strict mode, R15 characters, DataStoreService leaderboards

**Repo:** https://github.com/jayjz/brainrot-downhill-smash  
**Branch:** `agent/autonomous-downhill-smash`

---

## Current Step

### Step 2: Fix Missing RemoteEvent + Config Keys
**Status:** 📋 Planned — awaiting approval  
**Priority:** P0 BLOCKER

**Problem:**
1. `RagdollRecovered` is in `Config.REMOTES` but missing from `default.project.json` → `GameManager:OnHazardHit` gets nil remote
2. `MovementController.lua` references 6 Config keys that don't exist → runtime nil errors block playtesting:
   - `STAMINA_MAX`, `SPRINT_SPEED`, `CLIMB_SPEED_STEEP`, `STAMINA_DRAIN_RATE`, `STAMINA_REGEN_RATE`, `JUMP_COOLDOWN`

**Changes:**
- `default.project.json` — add `"RagdollRecovered": { "$className": "RemoteEvent" }`
- `Config.lua` — add missing `PLAYER` keys with sensible defaults

**Risk:** Low — config only, no logic changes  
**Estimated lines:** ~10

---

## Backlog

### P0 — Blockers

**Step 3: Fix Ragdoll Event Duplication**
- CollisionDetector fires BOTH `HazardHit` + `RagdollTriggered`
- GameManager:OnHazardHit ALSO fires `RagdollTriggered`
- RagdollClient listens to BOTH events
- Result: 2-3 duplicate ragdoll triggers per hit (guarded by isRagdolled flag, works but messy)
- Fix: Single source of truth — CollisionDetector → HazardHit only, GameManager → RagdollTriggered only, RagdollClient listens to RagdollTriggered only

**Step 4: Playtest — Verify Full Loop**
- Slope generates ✓
- Player can climb ?
- Hazards spawn ?
- Collision detects hit ?
- Ragdoll triggers ?
- Player tumbles down slope ?
- Player recovers and can climb again ?
- No console errors ?

### P1 — High Priority

**Step 5: Tune Gameplay Values**
- Knockback force (currently 50 studs/sec)
- Hazard spawn rate (currently 2/sec)
- Ragdoll recovery time (currently 3 sec)
- Slope steepness progression

**Step 6: Basic UI**
- Health bar
- Score display
- Stamina bar
- Height/distance indicator

**Step 7: Audio Feedback**
- Hit/bonk sound effects (asset IDs in Config but not played)
- Whoosh/impact sounds
- Background music loop

### P2 — Medium Priority

**Step 8: Visual Feedback**
- Particle effects on hazard impact
- Damage numbers / hit markers
- Slow-mo effect on hit (Config.PHYSICS.SLOW_MO_DURATION = 0.5, not implemented)
- Screen shake tuning

**Step 9: Progression System**
- Hazards spawn faster as player climbs higher
- Score multipliers for checkpoints
- Game over when player falls off slope
- Leaderboard integration

**Step 10: Mobile Optimization**
- Test touch controls during ragdoll
- Verify 60 FPS on low-end mobile
- UI scaling for small screens

### Future — Not Scheduled

- Shop / cosmetic system
- Multiplayer / social features
- More hazard types
- Slope biome variety
- Daily challenges
- Monetization (game passes)

---

## Completed Steps

### ✅ Step 1: Client/Server Entry Points (`7cfa4aa`)
- Created `ServerMain.server.lua` — requires GameManager, calls Init() with error handling, cleanup on BindToClose
- Created `ClientMain.client.lua` — requires MovementController, CameraController, RagdollClient in order with error handling
- Removed auto-Init() from GameManager, MovementController, CameraController, RagdollClient
- Added `GameManager:Destroy()` for proper cleanup
- **Result:** Game now runs on startup. Fixes BUG-001.
