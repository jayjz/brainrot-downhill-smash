# BUGS.md - Brainrot Downhill Smash

Known issues, tracked by priority.

---

## P0 — Blockers (game doesn't work)

### BUG-001: No entry point scripts — game does nothing on startup
**Status:** Open  
**Found:** 2026-06-30

**Description:** All controllers are ModuleScripts with auto-Init(), but nothing requires them.
- Server: `GameManager.lua` calls `Init()` at module load, nobody requires it
- Client: `MovementController`, `CameraController`, `RagdollClient` all auto-Init(), nobody requires them

**Impact:** Game does literally nothing in Studio unless files are manually required.

**Fix:** Add `ServerMain.server.lua` + `ClientMain.client.lua` entry points.  
**Planned:** PLAN.md Step 1

---

### BUG-002: Missing RemoteEvent — RagdollRecovered
**Status:** Open  
**Found:** 2026-06-30

**Description:** `RagdollRecovered` is defined in `Config.REMOTES` but missing from `default.project.json` RemoteEvents folder.

**Impact:** `GameManager:OnHazardHit:179` calls `remotes:FindFirstChild(Config.REMOTES.RAGDOLL_RECOVERED)` → returns nil → `FireClient` fails silently (guarded by `if recoverRemote` check, so no crash, but recovery signal never fires).

**Fix:** Add `"RagdollRecovered": { "$className": "RemoteEvent" }` to `default.project.json`.  
**Planned:** PLAN.md Step 2

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

_None yet — project is pre-playtest._
