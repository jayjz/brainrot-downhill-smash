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

## Review History

| Date | Scope | Verdict |
|------|-------|---------|
| 2026-06-30 | Step 1: Client/Server entry points (`7cfa4aa`) | ✅ Approved |
| 2026-06-30 | Full Phase 2 integration audit | Blocked — missing entry points |
