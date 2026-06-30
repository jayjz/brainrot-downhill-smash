# BUGS.md - Brainrot Downhill Smash

Known issues, tracked by priority.

---

## P1 — High Priority (game works but broken)

### BUG-003: Ragdoll event duplication — 2-3 triggers per hit
**Status:** Open  
**Found:** 2026-06-30

**Description:**
- `HazardCollisionDetector:_OnHazardTouched` fires BOTH `HazardHit` AND `RagdollTriggered` remotes
- `GameManager:OnHazardHit` ALSO fires `RagdollTriggered`
- `RagdollClient` listens to BOTH `HazardHit` AND `RagdollTriggered`, calls `TriggerRagdoll` on both

**Impact:** 2-3 duplicate ragdoll triggers per hit. Currently guarded by `isRagdolled` flag so it "works", but brittle and messy.

**Fix:** Single source of truth — CollisionDetector → HazardHit only, GameManager → RagdollTriggered only, RagdollClient listens to RagdollTriggered only.  
**Planned:** PLAN.md Step 3

---

## P2 — Medium Priority (polish / edge cases)

### BUG-004: Asset IDs unverified
**Status:** Open  
**Found:** 2026-06-12

**Description:** Creator Store asset IDs in `HazardTypes.lua` may not exist or may not be what they claim:
- SkibidiToilet: `rbxassetid://7046677542`
- OhioRizzler: `rbxassetid://8659481403`

**Impact:** InsertService load fails → fallback to procedural colored parts. Game works but looks boring.

**Fix:** Verify IDs in Studio, find real free assets, or stick with procedural and improve visuals.

---

### BUG-005: No ragdoll error recovery
**Status:** Open  
**Found:** 2026-06-30

**Description:** If ragdoll fails mid-tumble (constraint creation error, character destroyed, etc.), no fallback. Character could be stuck in broken state.

**Impact:** Player stuck, must respawn.

**Fix:** Add timeout / recovery failsafe, validate constraint creation.

---

## Fixed

### BUG-006: MovementController Config keys missing
**Status:** ✅ Fixed in `ccfe057`  
**Found:** 2026-06-30  
**Fixed:** 2026-06-30

**Description:** `MovementController.lua` referenced 6 Config keys that didn't exist.

**Fix:** Added `SPRINT_SPEED`, `CLIMB_SPEED_STEEP`, `JUMP_COOLDOWN`, `STAMINA_MAX`, `STAMINA_DRAIN_RATE`, `STAMINA_REGEN_RATE` to `Config.PLAYER`.

---

### BUG-002: Missing RemoteEvent — RagdollRecovered
**Status:** ✅ Fixed in `ccfe057`  
**Found:** 2026-06-30  
**Fixed:** 2026-06-30

**Description:** `RagdollRecovered` defined in `Config.REMOTES` but missing from `default.project.json`.

**Fix:** Added `"RagdollRecovered": { "$className": "RemoteEvent" }` to project config.

---

### BUG-001: No entry point scripts — game does nothing on startup
**Status:** ✅ Fixed in `7cfa4aa`  
**Found:** 2026-06-30  
**Fixed:** 2026-06-30

**Description:** All controllers are ModuleScripts with auto-Init(), but nothing requires them.

**Fix:** Added `ServerMain.server.lua` + `ClientMain.client.lua` entry points. Removed auto-Init() from GameManager and all 3 client controllers. Added `GameManager:Destroy()`.
