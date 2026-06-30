# PLAN.md - Brainrot Downhill Smash

## Project Overview
Viral meme physics chaos runner. Climb a steep procedural slope while dodging physics-based meme hazards (Skibidi Toilets, Ohio Rizzlers, etc.). Get hit → full ragdoll tumble with momentum carry-over. Pure chaos, 30-second core loop.

**Tech Stack:** Rojo 7.4+, Luau strict mode, R15 characters, DataStoreService leaderboards

**Repo:** https://github.com/jayjz/brainrot-downhill-smash  
**Branch:** `agent/autonomous-downhill-smash`

---

## Current Step

### Step 3: Fix Ragdoll Event Duplication
**Status:** 📋 Planned — awaiting approval  
**Priority:** P1

**Problem:**
- CollisionDetector fires BOTH `HazardHit` + `RagdollTriggered`
- GameManager:OnHazardHit ALSO fires `RagdollTriggered`
- RagdollClient listens to BOTH events
- Result: 2-3 duplicate ragdoll triggers per hit (guarded by isRagdolled flag, works but messy)

**Changes:**
- `HazardCollisionDetector.lua` — remove `RagdollTriggered` fire, keep `HazardHit` only (server-side damage + knockback)
- `RagdollClient.lua` — remove `HazardHit` listener, keep `RagdollTriggered` listener only
- GameManager:OnHazardHit — unchanged, remains single source of truth for firing `RagdollTriggered` to client

**Risk:** Low — event wiring only, no logic changes  
**Estimated lines:** ~15 removed

---

## Backlog

### P0 — Blockers

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

### ✅ Step 2: RemoteEvent + Config Keys (`ccfe057`)
- `default.project.json` — added `RagdollRecovered` RemoteEvent
- `Config.lua` — added 6 missing `PLAYER` keys: `SPRINT_SPEED`, `CLIMB_SPEED_STEEP`, `JUMP_COOLDOWN`, `STAMINA_MAX`, `STAMINA_DRAIN_RATE`, `STAMINA_REGEN_RATE`
- **Result:** MovementController no longer crashes on first frame. Ragdoll recovery signal can fire correctly. Fixes BUG-002 + BUG-006.

### ✅ Step 1: Client/Server Entry Points (`7cfa4aa`)
- Created `ServerMain.server.lua` — requires GameManager, calls Init() with error handling, cleanup on BindToClose
- Created `ClientMain.client.lua` — requires MovementController, CameraController, RagdollClient in order with error handling
- Removed auto-Init() from GameManager, MovementController, CameraController, RagdollClient
- Added `GameManager:Destroy()` for proper cleanup
- **Result:** Game now runs on startup. Fixes BUG-001.
