# ASSETS.md - Brainrot Downhill Smash

Asset strategy: procedural first, InsertService second, free models last.

---

## Procedural Assets (Primary — No External Dependencies)

These are generated in-code, zero load time, always available.

| Asset | Method | Used For |
|-------|--------|----------|
| Slope wedges | `WedgePart` | Downhill track surface |
| Hazard spheres | `Part.Shape = Ball` | Rolling hazards (barrels, boulders) |
| Hazard cubes | `Part` | Sliding/blocking hazards (crates) |
| Hazard cylinders | `Part.Shape = Cylinder` | Rolling log hazards |
| Goal platform | `Part` + `SurfaceGui` | Finish line / goal zone |
| Checkpoint rings | `Part` (torus via CSG or simple ring) | Progress markers |
| Particle FX | `ParticleEmitter` | Impact dust, speed trails |
| Decals/UI | `SurfaceGui` + `TextLabel` | In-world signs, distance markers |

**Status:** ✅ Slope wedges, hazard spheres/cubes already implemented in `SlopeBuilder.lua` + `HazardSpawner.lua`

---

## InsertService Assets (Secondary — Cached)

Loaded via `InsertService:LoadAsset()`, cached in `ServerStorage.Assets.Hazards` for reuse.

| Asset | Asset ID | Type | Status |
|-------|----------|------|--------|
| Toilet | `rbxassetid://14094546528` | Hazard model | ⚠️ Unverified |
| Dummy NPC | `rbxassetid://5056319657` | Hazard model | ⚠️ Unverified |
| Wooden Crate | `rbxassetid://17459437262` | Hazard model | ⚠️ Unverified |
| Oil Barrel | `rbxassetid://1309245904` | Hazard model | ⚠️ Unverified |

**Fallback:** If InsertService fails (timeout, asset deleted, rate limit), `HazardSpawner:_CreateHazardInstance()` falls back to procedural `Part` with matching `size`/`mass`/`color`.

**Performance:** Assets are cached in `ServerStorage.Assets.Hazards` on first load. Subsequent spawns clone from cache — no InsertService hit.

---

## Free Sound Assets

| Sound | Asset ID | Used For | Status |
|-------|----------|----------|--------|
| Bonk/Hit SFX | `rbxassetid://9114937214` | Hazard impact | ⚠️ Unverified |
| Whoosh SFX | `rbxassetid://9118823105` | Hazard spawn / near miss | ⚠️ Unverified |

**Note:** Sound playback is defined in hazard definitions but not currently wired up in `RagdollClient.lua`. See BUG-008.

---

## Asset Loading Strategy

1. **Try cache first** — `ServerStorage.Assets.Hazards:FindFirstChild(hazardName)`
2. **Try InsertService** — `InsertService:LoadAsset(assetId)` → cache result → clone for use
3. **Fallback to procedural** — Create `Part` with `definition.size`, random color, `SmoothPlastic` material

This ensures the game **always works** even if all InsertService calls fail. Procedural fallback is the safety net.

---

## Asset Verification Checklist

Before shipping, verify in Studio:

- [ ] Toilet `14094546528` — loads, correct size (~4×5.5×4 studs), has PrimaryPart
- [ ] Dummy NPC `5056319657` — loads, ~2.5×6×2.5 studs
- [ ] Wooden Crate `17459437262` — loads, ~3×3×3 studs
- [ ] Oil Barrel `1309245904` — loads, ~3×4×3 studs
- [ ] Hit SFX `9114937214` — plays correctly
- [ ] Whoosh SFX `9118823105` — plays correctly
- [ ] Procedural fallback works (block InsertService in Studio, verify colored Parts spawn)

If any asset ID is invalid → find replacement on Creator Store OR remove assetId from `HazardTypes.lua` → automatic procedural fallback.

---

## Known Issues

### BUG-004: Asset IDs unverified
Free model asset IDs in `HazardTypes.lua` have never been tested in Studio. May be deleted, private, or wrong size.

**Mitigation:** Procedural fallback ensures game is always playable.

### BUG-008: Sound effects not wired up
`soundId` fields exist in `HazardTypes.Definitions` but are never played. `RagdollClient:TriggerRagdoll()` has a `_PlayRagdollEffects()` stub with no audio.

**Fix:** Add `Sound` instance playback in `RagdollClient:_PlayRagdollEffects()` and `HazardCollisionDetector:_OnHazardTouched()`.
