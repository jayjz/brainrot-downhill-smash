# ROADMAP.md - Brainrot Downhill Smash

High-level project goals and phases.

---

## Vision
Viral meme physics chaos runner that beats "Climb to Steal Brainrot". Climb an increasingly steep slope while dodging viral meme hazards with full ragdoll physics. Clip-worthy tumbles, 30-second core loop, infinite replayability.

---

## Phase 1: Slope + Movement ✅ COMPLETE
**Goal:** Playable climbing with stamina system

- [x] Procedural slope generation (SlopeGenerator)
- [x] Physical slope building (SlopeBuilder)
- [x] Climbing movement controller with stamina
- [x] Dynamic camera with collision avoidance
- [x] Mobile + gamepad support
- [x] Config-driven, --!strict compliant

**Status:** Shipped, code reviewed, approved

---

## Phase 2: Hazards + Ragdoll 🟡 IN PROGRESS
**Goal:** Full playable game loop — climb, get hit, ragdoll, recover

- [x] Hazard types defined with asset IDs
- [x] Hazard spawner with object pooling
- [x] Collision detection with knockback
- [x] Ragdoll controller (BallSocketConstraints)
- [x] Client-side ragdoll listener
- [ ] Entry point scripts (ServerMain / ClientMain) ← **BLOCKED**
- [ ] RemoteEvent wiring cleanup ← **BLOCKED**
- [ ] Studio playtest — verify full loop ← **BLOCKED**
- [ ] Gameplay tuning (knockback, spawn rate, recovery time)

**Target:** Fully playable, fun for 2+ minutes straight  
**Estimated:** 1-2 days (after blockers fixed)

---

## Phase 3: Juice + Progression
**Goal:** Make it feel good, add progression hooks

- [ ] Basic UI (health bar, score, stamina, height)
- [ ] Sound effects (hit, whoosh, background music)
- [ ] Particle effects on impact
- [ ] Screen shake / slow-mo tuning
- [ ] Score multipliers for checkpoints
- [ ] Difficulty progression (spawn rate scales with height)
- [ ] Game over / restart flow

**Target:** Polished enough for playtesting with friends  
**Estimated:** 3-5 days

---

## Phase 4: Social + Multiplayer
**Goal:** Multiplayer chaos, social features

- [ ] 6-8 player servers
- [ ] Leaderboards (DataStoreService)
- [ ] Spectator mode
- [ ] Emotes / reactions
- [ ] Friend invites
- [ ] Replay highlights / clip sharing

**Target:** Viral-ready, stream-friendly  
**Estimated:** 1-2 weeks

---

## Phase 5: Launch + Live Ops
**Goal:** Ship to Roblox, retain players

- [ ] Performance optimization (target 60 FPS on low-end mobile)
- [ ] Anti-cheat hardening
- [ ] Shop / cosmetic system
- [ ] Daily challenges
- [ ] Seasonal events
- [ ] Analytics / telemetry
- [ ] Monetization (game passes, cosmetics)

**Target:** Live ops ready, sustainable  
**Estimated:** 2-4 weeks

---

## Success Metrics

| Metric | Phase 2 Target | Launch Target |
|--------|---------------|---------------|
| Playable loop | ✅ Yes | ✅ Yes |
| Fun for 2+ min | TBD | ✅ Yes |
| 60 FPS mobile | TBD | ✅ Yes |
| 0 console errors | TBD | ✅ Yes |
| Player retention (D1) | N/A | 30%+ |
| Avg session length | N/A | 5+ min |
| Viral clip rate | N/A | 1 clip / 10 players |

---

## Current Status

**Phase:** 2 — Hazards + Ragdoll  
**Completion:** ~75% (systems exist, integration broken)  
**Blockers:** Missing entry points, event wiring cleanup, no Studio test  
**Next milestone:** Playable loop verified in Studio

See [PLAN.md](PLAN.md) for immediate next steps.
