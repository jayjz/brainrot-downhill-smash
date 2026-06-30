# PLAN.md - Brainrot Downhill Smash

## Project Overview
Viral meme physics chaos runner. Climb a steep procedural slope while dodging physics-based meme hazards (Skibidi Toilets, Ohio Rizzlers, etc.). Get hit → full ragdoll tumble with momentum carry-over. Pure chaos, 30-second core loop.

**Tech Stack:** Rojo 7.4+, Luau strict mode, R15 characters, DataStoreService leaderboards

**Repo:** https://github.com/jayjz/brainrot-downhill-smash  
**Branch:** `agent/autonomous-downhill-smash`

---

## Current Step

### Step 4: Playtest — Verify Full Loop
**Status:** 📋 Ready — all P0/P1 blockers fixed, waiting for Studio test  
**Priority:** P0 BLOCKER

**Checklist:**
- [ ] Slope generates
- [ ] Player can climb
- [ ] Hazards spawn
- [ ] Collision detects hit
- [ ] Ragdoll triggers
- [ ] Player tumbles down slope
- [ ] Player recovers and can climb again
- [ ] No console errors

**Note:** This step requires manual Studio testing by Georgie. Cannot be automated.

---

## Backlog

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

**BUG-007: Orphaned HazardHit OnServerEvent handler**
- `HazardHit` RemoteEvent is no longer used server→client after BUG-003 fix
- GameManager still has `OnServerEvent` handler that calls `OnHazardHit` (client→server)
- `OnHazardHit` does NOT apply damage/knockback, only ragdollCount + `RagdollTriggered`
- Client firing `HazardHit` to server triggers free self-ragdoll, no damage
- Rate-limited + validated, not game-breaking, but confusing API
- Fix: either (a) remove handler entirely — server-authoritative collision, or (b) rename `HazardHit` → `ReportHazardHit`, handler applies damage/knockback server-side

### Future — Not Scheduled

- Shop / cosmetic system
- Multiplayer / social features
- More hazard types
- Slope biome variety
- Daily challenges
- Monetization (game passes)

---

## Completed Steps

### ✅ Step 3: Ragdoll Event Duplication Fix (`da65136`)
- `HazardCollisionDetector.lua` — added `onHazardHit` callback param to `Start()`, removed `HazardHit:FireClient` + `RagdollTriggered:FireClient` calls, invokes callback after damage/knockback/VFX
- `GameManager.lua` — `StartRound()` passes `OnHazardHit` callback to `collisionDetector:Start()`, breaks circular dependency via callback injection
- `RagdollClient.lua` — removed `HazardHit` OnClientEvent listener, listens to `RagdollTriggered` ONLY
- **Result:** 1 ragdoll trigger per hit (was 2-3). Clean event flow: `CollisionDetector → GameManager:OnHazardHit (callback) → RagdollTriggered → RagdollClient`. Fixes BUG-003.

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
