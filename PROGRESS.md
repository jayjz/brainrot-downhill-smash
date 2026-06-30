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

## Phase 1 — Complete ✅

| Module | Lines | Status |
|--------|-------|--------|
| SlopeGenerator.lua | 127 | ✅ Procedural math, trig-based |
| SlopeBuilder.lua | 162 | ✅ Physical wedge generation |
| MovementController.lua | 384 | ✅ Climbing physics, stamina, mobile+gamepad |
| CameraController.lua | 217 | ✅ Dynamic camera, collision avoidance |
| Config.lua | ~70 | ✅ Frozen tables, zero magic numbers |
| Types.lua | ~40 | ✅ Luau strict mode exports |
| GameManager.lua | 297 | ✅ Round management, rate limiting |

**Total:** ~1,600 lines of production code

---

## Phase 2 — In Progress 🟡

| Module | Status |
|--------|--------|
| HazardTypes.lua | ✅ 4 hazard types with asset IDs |
| HazardSpawner.lua | ✅ Spawn logic, pooling, raycast validation |
| HazardCollisionDetector.lua | ✅ Touched events, knockback, highlights |
| RagdollController.lua | ✅ BallSocketConstraint ragdoll, momentum preservation |
| RagdollClient.lua | ✅ Client listener, recovery logic |

**Blockers:**
- No entry point scripts — game does nothing on startup
- Missing `RagdollRecovered` RemoteEvent in project config
- Ragdoll event duplication (2-3 triggers per hit)
- Never tested in Studio

---

## Planned

See [PLAN.md](PLAN.md) for upcoming steps.
