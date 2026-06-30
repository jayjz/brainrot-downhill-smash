# REVIEW.md - Brainrot Downhill Smash

Self-review log for major changes.

---

## 2026-06-30 — Phase 2 Integration Audit

**Scope:** Full codebase review — server modules, client controllers, config, project setup

### What Was Good
- **Config-driven design** — Zero magic numbers, frozen tables, easy to tune
- **Type safety** — `--!strict` everywhere, proper Luau exports in Types.lua
- **Performance-first** — Object pooling in HazardSpawner, single raycast for slope detection
- **Mobile-first** — ContextActionService in MovementController from day 1, gamepad support included
- **Security** — GameManager has RemoteEvent rate limiting (10 events/sec) + type validation on all remotes
- **Ragdoll physics** — BallSocketConstraints with proper momentum preservation, not the naive Humanoid:ChangeState approach

### What Could Be Improved
- **No entry points** — All controllers are ModuleScripts with auto-Init(), nothing requires them. Game does nothing on startup. Need `ServerMain.server.lua` + `ClientMain.client.lua`
- **Event architecture is messy** — Ragdoll triggers fire 2-3 times per hit across CollisionDetector → GameManager → RagdollClient. Guarded by isRagdolled flag so it "works", but should have single source of truth
- **Missing RemoteEvent** — `RagdollRecovered` in Config but not in `default.project.json`. Will nil-error at runtime.
- **No Studio testing** — Integration is theoretical. Code looks correct but untested.
- **Asset IDs unverified** — Creator Store IDs in HazardTypes.lua may not exist / may not be what they claim
- **No error recovery** — If ragdoll fails mid-tumble, character could be stuck in broken state

### Risks
- **High — Untested integration:** Untested code often has bugs. Full loop (spawn → climb → hit → ragdoll → recover) has never been verified in-engine.
- **Medium — Asset loading:** InsertService calls can fail / timeout. Fallback to procedural parts works but looks boring.
- **Low — Event duplication:** Currently guarded by isRagdolled flag, but brittle. One refactor away from double-ragdoll bugs.

### Verdict
**Phase 1 (Slope + Movement):** ✅ Approved — solid foundation  
**Phase 2 (Hazards + Ragdoll):** ⏸️ Blocked — systems exist but don't run, needs entry points + event cleanup + Studio test

### Next Steps
1. Add ServerMain / ClientMain entry points (PLAN.md Step 1)
2. Fix missing RagdollRecovered RemoteEvent (Step 2)
3. Clean up ragdoll event duplication (Step 3)
4. Playtest full loop in Studio (Step 4)
5. Tune gameplay values based on feel (Step 5)

---

## 2026-06-30 — Step 1: Client/Server Entry Points

**Scope:** `7cfa4aa` — ServerMain.server.lua + ClientMain.client.lua + removed auto-Init from 4 modules

### What Was Good
- **Clean separation** — Entry points own bootstrap/error handling, modules own logic, no side effects on require
- **Error handling** — Both ServerMain and ClientMain wrap Init() calls in pcall, log failures per-controller
- **Proper cleanup** — Added `GameManager:Destroy()` with BindToClose hook on server
- **Init ordering** — ClientMain initializes Movement → Camera → Ragdoll in logical dependency order
- **Minimal change** — Only removed auto-Init calls, no logic changes, low risk

### What Could Be Improved
- **MovementController has Config key mismatches** — References `Config.PLAYER.STAMINA_MAX`, `SPRINT_SPEED`, `CLIMB_SPEED_STEEP`, `STAMINA_DRAIN_RATE`, `STAMINA_REGEN_RATE`, `JUMP_COOLDOWN` which don't exist in Config.lua. Will crash at runtime. Not introduced by this commit, pre-existing bug.
- **No controller Destroy() methods** — ClientMain can init but not clean up controllers. OK for Phase 2, add later.
- **Init is not idempotent** — Calling Init() twice would double-connect events. Client controllers guard against this (MovementController doesn't, others unclear). Low risk since ClientMain only calls once.

### Risks
- **Medium — Config key mismatch crash:** MovementController will error on first frame when accessing nil Config values. Blocks playtesting. Should be fixed before Step 2 or as part of Step 4 playtest prep.
- **Low — Double Init:** If someone manually requires a controller module, it won't auto-init (correct now), but if ClientMain runs twice (respawn edge case?) events could double-connect.

### Verdict
✅ **Approved** — Entry points are clean, error handling is solid, separation of concerns is correct. The Config mismatch is pre-existing and out of scope for Step 1.

### Next Steps
Step 2: Fix missing RagdollRecovered RemoteEvent (BUG-002) — 1-line JSON change, 2 min.

---

## 2026-06-30 — Step 2: RemoteEvent + Config Keys

**Scope:** `ccfe057` — default.project.json + Config.lua — 2 files, +9 lines

### What Was Good
- **Minimal change** — 1 RemoteEvent added to project config, 6 Config keys added with sensible defaults, zero logic changes
- **Config values match audit notes** — Stamina drain/regen rates match the Phase 1 validation log in MEMORY.md (drain 15/sec = 6.67s to empty, regen 25/sec = 4s to full)
- **Centralized config** — All 6 missing keys added to `Config.PLAYER` in one place, no scattered magic numbers
- **Fixes 2 P0 blockers in one commit** — BUG-002 (RemoteEvent) + BUG-006 (Config keys) both resolved

### What Could Be Improved
- Nothing — this was a pure config fix, no logic to critique. Values are reasonable defaults that can be tuned during playtesting (Step 5).

### Risks
- **None.** Config-only changes, values match existing code expectations, no logic modified.

### Verdict
✅ **Approved** — Fixes 2 P0 blockers with minimal, correct changes. Playtesting is now unblocked once BUG-003 (event duplication) is cleaned up.

### Next Steps
Step 3: Fix ragdoll event duplication (BUG-003) — remove duplicate event fires, single source of truth. Then Step 4: Playtest full loop in Studio.

---

## 2026-06-30 — Step 3: Ragdoll Event Duplication Fix

**Scope:** `da65136` — HazardCollisionDetector + GameManager + RagdollClient — 3 files, +36 / -22 lines

### What Was Good
- **Callback injection breaks circular dependency cleanly** — GameManager requires HazardCollisionDetector, so CollisionDetector cannot require GameManager. Passing `OnHazardHit` as a callback to `Start()` solves this without a global event bus, BindableEvent, or module restructuring. pcall-wrapped with error logging.
- **Clean separation of concerns** — CollisionDetector owns physics (damage, knockback, VFX), GameManager owns game state (ragdollCount) + client signaling (RagdollTriggered/RagdollRecovered), RagdollClient owns presentation (ragdoll FX, recovery)
- **Single source of truth** — Before: 2-3 ragdoll triggers per hit across 3 modules. After: 1 trigger per hit, clean flow: `CollisionDetector → GameManager:OnHazardHit (callback) → RagdollTriggered → RagdollClient`
- **Proper cleanup** — `onHazardHit` callback is nil'd in `Stop()`, no dangling references
- **Defensive error handling** — Callback invocation is pcall-wrapped, warns on failure instead of crashing the collision handler

### What Could Be Improved
- **`HazardHit` RemoteEvent is now orphaned** — CollisionDetector no longer fires `HazardHit:FireClient`, RagdollClient no longer listens to it. GameManager still has an `OnServerEvent` handler for `HazardHit` (client→server exploit/report path) that calls `OnHazardHit` — but `OnHazardHit` does NOT apply damage/knockback, only ragdollCount + RagdollTriggered. So a client firing `HazardHit` to the server triggers a free ragdoll on themselves with no damage. Rate-limited (10/sec) and validated, so not game-breaking, but the RemoteEvent is now confusingly named / repurposed. Should either: (a) remove the OnServerEvent handler entirely (server-authoritative collision detection, clients never report hits), or (b) rename `HazardHit` → `ReportHazardHit` to make client→server direction explicit, and have the handler apply damage/knockback server-side. P1 cleanup, not blocking.
- **No client-side prediction** — Ragdoll triggers after server round-trip (CollisionDetector → GameManager → RagdollTriggered → client). ~50-100ms latency before ragdoll FX starts. Acceptable for Phase 2, consider client-side prediction in Phase 3 polish.

### Risks
- **Low — Callback not set:** If `collisionDetector:Start()` is called without the callback argument, `onHazardHit` is nil, hit detection still works (damage + knockback + VFX), but ragdoll never triggers (no `RagdollTriggered` RemoteEvent fired, no recovery timer). GameManager passes the callback correctly in `StartRound()`, so this only happens if someone calls `Start()` manually without args. Acceptable — callback is optional by design, CollisionDetector degrades gracefully.
- **Low — Stale callback after round end:** Callback is cleared in `Stop()`, which is called by `GameManager:EndRound()`. No leak risk.

### Verdict
✅ **Approved** — Callback injection is the right pattern for breaking the circular dependency. Event flow is now clean, single source of truth, proper separation of concerns. The orphaned `HazardHit` OnServerEvent handler is tech debt but not blocking — flag for cleanup in Phase 3.

### Next Steps
Step 4: Playtest full loop in Studio — verify slope generates, player can climb, hazards spawn, collision detects hit, ragdoll triggers, player tumbles, recovers, can climb again, no console errors.

---

## Review History

| Date | Scope | Verdict |
|------|-------|---------|
| 2026-06-30 | Step 3: Ragdoll event duplication (`da65136`) | ✅ Approved |
| 2026-06-30 | Step 2: RemoteEvent + Config keys (`ccfe057`) | ✅ Approved |
| 2026-06-30 | Step 1: Client/Server entry points (`7cfa4aa`) | ✅ Approved |
| 2026-06-30 | Full Phase 2 integration audit | Blocked — missing entry points |
