# ROADMAP.md - Brainrot Downhill Smash

High-level project goals and phases.

---

## Vision
Viral meme physics **downhill** chaos runner. Spawn at the top of a steep procedural slope, slide/ragdoll down at high speed, dodge physics-based meme hazards (brainrot toilets, barrels, crates). Reach the goal at the bottom. Clip-worthy tumbles, 30-second core loop, infinite replayability.

**Asset Strategy:** Procedural first, InsertService second. See [ASSETS.md](ASSETS.md).

---

## Phase 1: Make It Playable ✅ COMPLETE
**Goal:** End-to-end playable loop with free/procedural assets

### 1A: Foundation (Complete)
- [x] Procedural slope generation (SlopeGenerator)
- [x] Physical slope building (SlopeBuilder)
- [x] Movement controller (originally climbing-focused, retuned for downhill)
- [x] Dynamic camera with collision avoidance
- [x] Mobile + gamepad support
- [x] Config-driven, --!strict compliant

### 1B: Hazards + Ragdoll (Complete)
- [x] Hazard types with InsertService asset IDs + procedural fallback
- [x] Hazard spawner with object pooling + raycast validation
- [x] Collision detection with knockback
- [x] Ragdoll controller (BallSocketConstraints)
- [x] Client-side ragdoll listener
- [x] ServerMain / ClientMain entry points
- [x] RemoteEvent wiring cleanup
- [x] Config key fixes

### 1C: Playable Loop (In Progress)
- [ ] Auto-start round on server boot
- [ ] Player spawn at top of slope
- [ ] Downhill movement tuning (gravity-assisted, steering)
- [ ] Goal zone detection + scoring
- [ ] Round restart flow
- [ ] Basic UI (health, distance to goal, score)
- [ ] Studio playtest — verify full loop works

**Target:** Fully playable in Studio, fun for 2+ minutes  
**Status:** Foundation complete, playable loop in progress (Step 4)

---

## Phase 2: Juice + Polish
**Goal:** Make it feel good

- [ ] Sound effects (hit, whoosh, goal fanfare, background music)
- [ ] Particle effects on impact
- [ ] Screen shake / slow-mo tuning
- [ ] Speed lines / motion blur at high velocity
- [ ] Camera FOV increase at speed
- [ ] Damage numbers / hit markers
- [ ] Gameplay tuning (knockback, spawn rate, ragdoll recovery, slope steepness)

**Target:** Polished enough for playtesting with friends  
**Estimated:** 3-5 days

---

## Phase 3: Progression + Replayability
**Goal:** Keep players coming back

- [ ] Score multipliers (near-miss, speed bonus)
- [ ] Difficulty progression (spawn rate scales with distance/speed)
- [ ] Multiple slope biomes / themes
- [ ] Leaderboards (fastest time to goal)
- [ ] Daily challenges
- [ ] Cosmetic unlocks

**Target:** Retention hooks in place  
**Estimated:** 1-2 weeks

---

## Phase 4: Social + Multiplayer
**Goal:** Multiplayer chaos, social features

- [ ] 6-8 player servers (simultaneous downhill race)
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
- [ ] Seasonal events
- [ ] Analytics / telemetry
- [ ] Monetization (game passes, cosmetics)

**Target:** Live ops ready, sustainable  
**Estimated:** 2-4 weeks

---

## Success Metrics

| Metric | Phase 1 Target | Launch Target |
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

**Phase:** 1C — Playable Loop  
**Completion:** ~75% (foundation solid, loop wiring in progress)  
**Blockers:** Round auto-start, spawn positioning, downhill movement tuning, goal zone  
**Next milestone:** Playable loop verified in Studio (Step 4)

See [PLAN.md](PLAN.md) for immediate next steps.
