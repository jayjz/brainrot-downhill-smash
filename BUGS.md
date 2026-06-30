# BUGS.md - Brainrot Downhill Smash

Known issues, tracked by priority.

---

## P1 — High Priority (game works but broken)

_None — all P1 blockers fixed._

---

## P2 — Medium Priority (polish / edge cases)

### BUG-004: Asset IDs unverified
**Status:** Open  
**Found:** 2026-06-12

**Description:** Creator Store asset IDs in `HazardTypes.lua` may not exist or may not be what they claim:
- Toilet: `rbxassetid://14094546528`
- Dummy NPC: `rbxassetid://5056319657`
- Wooden Crate: `rbxassetid://17459437262`
- Oil Barrel: `rbxassetid://1309245904`

Sound assets also unverified:
- Hit SFX: `rbxassetid://9114937214`
- Whoosh SFX: `rbxassetid://9118823105`

**Impact:** InsertService load fails → fallback to procedural colored Parts. Game works but looks/sounds boring.

**Fix:** Verify IDs in Studio, find real free assets, or stick with procedural and improve visuals. See [ASSETS.md](ASSETS.md) for verification checklist.

---

### BUG-005: No ragdoll error recovery
**Status:** Open  
**Found:** 2026-06-30

**Description:** If ragdoll fails mid-tumble (constraint creation error, character destroyed, etc.), no fallback. Character could be stuck in broken state.

**Impact:** Player stuck, must respawn.

**Fix:** Add timeout / recovery failsafe, validate constraint creation.

---

### BUG-007: Orphaned HazardHit OnServerEvent handler
**Status:** Open  
**Found:** 2026-06-30

**Description:** After BUG-003 fix, `HazardHit` RemoteEvent is no longer used server→client. `GameManager:_SetupRemoteHandlers` still has an `OnServerEvent` handler for `HazardHit` (client→server) that calls `OnHazardHit`. But `OnHazardHit` does NOT apply damage/knockback — only ragdollCount + `RagdollTriggered` RemoteEvent. So a client firing `HazardHit` to the server triggers a free ragdoll on themselves with no damage.

**Impact:** Exploit path — client can self-ragdoll. Rate-limited (10/sec) and validated, not game-breaking (they ragdoll themselves), but confusing API design.

**Fix:** Either (a) remove the `OnServerEvent` handler entirely — server-authoritative collision detection, clients never report hits, or (b) rename `HazardHit` → `ReportHazardHit` to make client→server direction explicit, and have the handler apply damage/knockback server-side.

---

### BUG-008: Sound effects not wired up
**Status:** Open  
**Found:** 2026-06-30

**Description:** `soundId` fields exist in `HazardTypes.Definitions` but are never played. `RagdollClient:_PlayRagdollEffects()` has a stub with no audio. `HazardCollisionDetector:_OnHazardTouched()` has no sound playback.

**Impact:** Game is silent on hit — hurts game feel significantly.

**Fix:** Add `Sound` instance playback in `RagdollClient:_PlayRagdollEffects()` (play `definition.soundId`) and `HazardCollisionDetector:_OnHazardTouched()`.

---

## Fixed

### BUG-003: Ragdoll event duplication — 2-3 triggers per hit
**Status:** ✅ Fixed in `da65136`  
**Found:** 2026-06-30  
**Fixed:** 2026-06-30

**Description:** `HazardCollisionDetector` fired both `HazardHit` + `RagdollTriggered`, `GameManager:OnHazardHit` fired `RagdollTriggered` again, `RagdollClient` listened to both events → 2-3 duplicate ragdoll triggers per hit.

**Fix:** Callback injection — `collisionDetector:Start(onHazardHit)` breaks circular dependency (GameManager → CollisionDetector). CollisionDetector now calls `onHazardHit(player, hazardId, damage)` after damage/knockback/VFX. GameManager handles ragdollCount + `RagdollTriggered` RemoteEvent + recovery timer. RagdollClient listens to `RagdollTriggered` ONLY. Single source of truth, clean event flow: `CollisionDetector → GameManager:OnHazardHit (callback) → RagdollTriggered → RagdollClient`.

---

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
