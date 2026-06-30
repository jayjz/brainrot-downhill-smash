# PROGRESS.md - Brainrot Downhill Smash

Chronological development log.

---

## 2026-06-12

### `fef883e` — Phase 2 systems integrated into GameManager
**Date:** 2026-06-12 ~17:20 UTC

**What was done:**
- Integrated `HazardSpawner` into `GameManager:StartRound()` / `EndRound()`
- Integrated `HazardCollisionDetector` into `GameManager:StartRound()` / `EndRound()`
- Created `RagdollClient.lua` — client-side ragdoll listener (195 lines)
- Enhanced `HazardSpawner` with raycast-based surface detection
- Added InsertService integration for loading Creator Store assets
- Added visual feedback (trails, colors) to hazards

**Impact:** Core gameplay loop is technically functional — hazards spawn, collisions work, ragdoll triggers. Not tested in Studio.

---

### `03d215e` — Fixed Rojo serve
**Date:** 2026-06-12

**What was done:** Rojo configuration fixes

---

### `ad49b62` — Fixing AI slop
**Date:** 2026-06-12

**What was done:** Code cleanup pass

---

### `c6a6fa3` — Add project documentation
**Date:** 2026-06-12

**What was done:**
- Initial README.md with project vision, tech stack, roadmap
- Established Phase 1/2/3/4/5 structure

---

## 2026-06-30

### `7cfa4aa` — Step 1: Client/Server entry points
**Date:** 2026-06-30

**What was done:**
- Created `ServerMain.server.lua` — server entry point, requires GameManager, calls Init() with error handling, cleanup on BindToClose
- Created `ClientMain.client.lua` — client entry point, requires MovementController, CameraController, RagdollClient in order with error handling
- Removed auto-Init() calls from `GameManager.lua`, `MovementController.lua`, `CameraController.lua`, `RagdollClient.lua`
- Added `GameManager:Destroy()` for proper cleanup

**Impact:** Game now actually runs on startup. Controllers initialize via explicit entry points instead of ModuleScript side effects. Fixes BUG-001.

---

### `ccfe057` — Step 2: RemoteEvent + Config keys
**Date:** 2026-06-30

**What was done:**
- `default.project.json` — added `RagdollRecovered` RemoteEvent (fixes BUG-002)
- `Config.lua` — added 6 missing `PLAYER` keys:
  - `SPRINT_SPEED = 24`
  - `CLIMB_SPEED_STEEP = 8`
  - `JUMP_COOLDOWN = 0.5`
  - `STAMINA_MAX = 100`
  - `STAMINA_DRAIN_RATE = 15`
  - `STAMINA_REGEN_RATE = 25`

**Impact:** MovementController will no longer crash on first frame with nil Config values. Ragdoll recovery signal can now fire correctly. Unblocks playtesting. Fixes BUG-002 + BUG-006.

---

### `da65136` — Step 3: Ragdoll event duplication fix
**Date:** 2026-06-30

**What was done:**
- `HazardCollisionDetector.lua` — added `onHazardHit` callback param to `Start()`
  - Removed `HazardHit:FireClient` call
  - Removed `RagdollTriggered:FireClient` call
  - Invokes `onHazardHit(player, hazardId, damage)` callback after damage/knockback/VFX
  - Clears callback in `Stop()`
- `GameManager.lua` — `StartRound()` now passes `OnHazardHit` callback to `collisionDetector:Start()`
  - Callback injection breaks circular dependency (GameManager → CollisionDetector)
- `RagdollClient.lua` — removed `HazardHit` OnClientEvent listener
  - Now listens to `RagdollTriggered` ONLY

**Impact:** Removes 2 duplicate ragdoll trigger paths per hit. Single source of truth: `CollisionDetector → GameManager:OnHazardHit (callback) → RagdollTriggered → RagdollClient`. CollisionDetector owns physics (damage, knockback), GameManager owns game state (ragdollCount) + client signaling. Fixes BUG-003.

---

### `TBD` — Pivot to downhill + free asset strategy
**Date:** 2026-06-30

**What was done:**
- Created `ASSETS.md` — asset strategy (procedural first, InsertService second), free asset inventory, verification checklist
- Rewrote `PLAN.md` — new "Making the Game Playable (Free Assets)" section, Step 4 redefined as auto-start round + spawn + goal zone + downhill movement tuning
- Rewrote `ROADMAP.md` — Phase 1 redefined as "Make It Playable", uphill→downhill pivot, asset strategy integrated
- Updated `BUGS.md` — added BUG-008 (sound effects not wired up), updated BUG-004 asset IDs to match current `HazardTypes.lua`
- Updated `REVIEW.md` — added pivot notes

**Impact:** Project direction clarified — downhill chaos runner (not uphill climber), procedural assets primary, InsertService secondary with fallback. Control files aligned with playable-loop goal.

---

## Phase 1 — Make It Playable 🟡 IN PROGRESS

| Module | Status | Notes |
|--------|--------|-------|
| SlopeGenerator.lua | ✅ | Procedural math, trig-based — may need downhill direction fix |
| SlopeBuilder.lua | ✅ | Physical wedge generation |
| MovementController.lua | ⚠️ | Climbing-focused, needs downhill retuning |
| CameraController.lua | ✅ | Dynamic camera, collision avoidance |
| Config.lua | ✅ | Frozen tables, zero magic numbers |
| Types.lua | ✅ | Luau strict mode exports |
| GameManager.lua | ⚠️ | Round management works, needs auto-start + spawn positioning |
| HazardTypes.lua | ✅ | 4 hazard types, InsertService IDs + procedural fallback |
| HazardSpawner.lua | ✅ | Spawn logic, pooling, raycast validation |
| HazardCollisionDetector.lua | ✅ | Touched events, knockback, GameManager callback |
| RagdollController.lua | ✅ | BallSocketConstraint ragdoll, momentum preservation |
| RagdollClient.lua | ✅ | Client listener, recovery logic, single event source |
| ServerMain.server.lua | ✅ | Entry point, error handling |
| ClientMain.client.lua | ✅ | Entry point, error handling |

**Missing for playable loop:**
- Auto-start round on server boot
- Player spawn at top of slope (currently spawns at default position)
- Goal zone at bottom of slope
- Downhill movement tuning (remove stamina drain, increase speed)
- Basic UI (health, distance to goal, score)

**Total:** ~1,800 lines of production code, ~400 lines of docs

---

## Planned

See [PLAN.md](PLAN.md) for upcoming steps.
