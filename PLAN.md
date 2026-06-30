# PLAN.md - Brainrot Downhill Smash

## Project Overview
Meme physics downhill chaos runner. Spawn at the top of a steep procedural slope, slide/ragdoll down, dodge physics-based hazards (brainrot meme objects). Reach the goal at the bottom. Clip-worthy tumbles, 30-second core loop.

**Tech Stack:** Rojo 7.4+, Luau strict mode, R15 characters, DataStoreService leaderboards

**Repo:** https://github.com/jayjz/brainrot-downhill-smash  
**Branch:** `agent/autonomous-downhill-smash`

**Asset Strategy:** Procedural first, InsertService second. See [ASSETS.md](ASSETS.md).

---

## Making the Game Playable (Free Assets)

### Playable Loop
```
Spawn (top of slope)
  ↓
Downhill movement (gravity + steering)
  ↓
Hazards roll/fall toward player
  ↓
Get hit → Ragdoll tumble
  ↓
Recover → Keep sliding
  ↓
Reach Goal (bottom)
  ↓
Score + Restart
```

### Design Principles
- **Procedural first** — Slopes, basic hazards, goal zone all generated in code. Zero external asset dependencies for core loop.
- **InsertService for flair** — Free meme models (toilet, barrel, crate) loaded via InsertService when available, with procedural fallback.
- **Cache aggressively** — InsertService assets cached in `ServerStorage.Assets.Hazards`, cloned for subsequent spawns.
- **Always playable** — If every InsertService call fails, procedural colored Parts keep the game fully functional.

---

## Current Step

### Step 4: Auto-Start Round + Spawn + Goal Zone
**Status:** 📋 Planned  
**Priority:** P0 BLOCKER

**Problem:** Game starts in "Waiting" state, `StartRound()` is never called, no slope exists, players spawn at default Roblox spawn with no game. Game is not playable in Studio.

**Changes:**
1. `GameManager:Init()` — auto-call `StartRound()` after 3 sec if players present, or on first `PlayerAdded`
2. `GameManager:StartRound()` — spawn player(s) at **top of slope** (currently spawns at `(0,10,20)` — bottom/lobby)
3. Create `GoalZone` module — detect when player reaches bottom of slope
   - Simple `Part` with `Touched` event at slope end
   - Fire `PlayerScored` + `CheckpointReached` remotes
   - Teleport player back to top / start next round
4. Slope orientation — verify slope goes **downhill** (player slides down via gravity, not climbing up)
   - Current `SlopeGenerator` builds uphill (increasing Y). May need to invert, OR keep uphill but auto-start at top and let gravity pull player down
   - Simpler: spawn at top (high Y, far Z), goal at bottom (low Y, near Z), gravity does the work
5. Remove stamina-based climbing from `MovementController` OR make it downhill steering
   - Current `MovementController` is built for **climbing uphill** (stamina drain on slopes, reduced climb speed)
   - For downhill: remove stamina drain, increase WalkSpeed on slopes, add steering/braking
   - Minimum viable: disable stamina system entirely, set `WalkSpeed = 24`, let gravity + Humanoid do the work

**Files to modify:**
- `GameManager.lua` — auto-start round, fix spawn position (top of slope)
- `SlopeGenerator.lua` — verify/fix slope direction (downhill)
- `MovementController.lua` — disable stamina drain, tune for downhill movement
- **New:** `ReplicatedStorage/Modules/GoalZone.lua` — goal detection + scoring
- **New:** `ServerScriptService/Services/GoalService.lua` — server-side goal validation

**Risk:** Medium — MovementController was designed for climbing, needs retuning for downhill. Physics may feel floaty/wrong initially.
**Estimated lines:** ~150 new (GoalZone + GoalService), ~50 modified

---

## Backlog

### P0 — Blockers (game not playable without these)

**Step 5: Wire Up Hazard Spawning for Downhill**
- Current `HazardSpawner` spawns hazards **above players** falling down — correct for uphill climb, wrong for downhill race
- For downhill: spawn hazards **ahead of/below player** rolling **uphill toward player**, OR spawn from sides rolling across slope
- Simpler MVP: keep current spawn logic (hazards fall from above), just ensure they spawn ahead on the downhill path
- Verify `HazardSpawner:_GetValidSpawnPosition()` raycast works with inverted slope direction

**Step 6: Basic UI — You Know What's Happening**
- Health bar (top left)
- Distance to goal / height indicator
- Score display
- "GET READY" / "GO!" / "YOU WIN!" messages
- Simple `ScreenGui` in `StarterGui`, no frameworks

### P1 — High Priority (playable but rough)

**Step 7: Tune Downhill Feel**
- WalkSpeed / gravity / friction tuning — should feel fast and chaotic, not floaty
- Knockback force tuning (currently 50 studs/sec — may be too weak/strong for downhill)
- Ragdoll recovery time (currently 3 sec — may be too long when sliding downhill)
- Slope steepness — start at 30°, ramp to 60°+ for chaos
- Camera FOV increase at speed for sense of velocity

**Step 8: Audio Feedback**
- Hit/bonk sound effects — `soundId` fields exist in `HazardTypes`, not wired up (BUG-008)
- Whoosh/impact sounds
- Goal reached fanfare
- Background music loop

### P2 — Medium Priority (polish)

**Step 9: Visual Feedback**
- Particle effects on hazard impact
- Speed lines / motion blur at high velocity
- Damage numbers / hit markers
- Screen shake tuning
- Slow-mo on big hits (`Config.PHYSICS.SLOW_MO_DURATION = 0.5`, not implemented)

**Step 10: Progression & Replayability**
- Multiple slope segments with increasing difficulty
- Score multipliers for near-misses / speed
- Leaderboard (fastest time to goal)
- Round restart flow (auto-restart 5 sec after goal)
- Spectator mode while waiting

**Step 11: Mobile Optimization**
- Test touch controls during ragdoll
- Verify 60 FPS on low-end mobile
- UI scaling for small screens
- Touch steering for downhill movement

---

## Completed Steps

### ✅ Step 3: Ragdoll Event Duplication Fix (`da65136`)
- `HazardCollisionDetector.lua` — callback injection breaks circular dependency, removes duplicate RemoteEvent fires
- `GameManager.lua` — passes `OnHazardHit` callback to `collisionDetector:Start()`
- `RagdollClient.lua` — listens to `RagdollTriggered` ONLY
- **Result:** 1 ragdoll trigger per hit (was 2-3). Fixes BUG-003.

### ✅ Step 2: RemoteEvent + Config Keys (`ccfe057`)
- `default.project.json` — added `RagdollRecovered` RemoteEvent
- `Config.lua` — added 6 missing `PLAYER` keys
- **Result:** MovementController no longer crashes. Fixes BUG-002 + BUG-006.

### ✅ Step 1: Client/Server Entry Points (`7cfa4aa`)
- Created `ServerMain.server.lua` + `ClientMain.client.lua`
- Removed auto-Init() from all controllers
- **Result:** Game runs on startup. Fixes BUG-001.
