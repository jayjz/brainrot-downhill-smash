# Brainrot Downhill Smash

**A viral meme physics chaos runner that beats "Climb to Steal Brainrot"**

> *"Climb the steepest slope in Roblox while dodging Skibidi Toilets, Ohio rizzlers, and viral brainrot hazards. One hit = full ragdoll tumble with momentum carry-over. Pure chaos."*

## 🎮 Core Loop (< 30 seconds)
1. Spawn at bottom of massive procedural slope
2. Climb upward as gradient steepens (30° → 80°+)
3. Dodge procedurally spawned meme hazards (physics props)
4. Reach checkpoints for score multipliers
5. Get hit? Full ragdoll physics tumble downhill
6. Recover and climb again or wipe out

## 🏗️ Tech Stack
- **Rojo 7.4+** - External code sync
- **Luau** with strict typing
- **R15** characters with custom ragdoll
- **StreamingEnabled** for performance
- **DataStoreService** for leaderboards

## 📁 Project Structure
```
src/
├── ServerScriptService/
│   ├── GameManager.server.lua
│   ├── Services/
│   │   ├── RagdollService.lua
│   │   ├── HazardSpawner.lua
│   │   └── LeaderboardService.lua
├── ReplicatedStorage/
│   ├── Modules/
│   │   ├── SlopeGenerator.lua
│   │   ├── RagdollController.lua
│   │   └── HazardTypes.lua
│   └── Shared/
│       ├── Config.lua
│       └── Types.lua
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── Controllers/
```

## 🚀 Setup
```bash
# Install Rojo
cargo install rojo

# Start sync server
rojo serve

# Open in Roblox Studio and connect to localhost:34872
```

## 🎯 Current Phase: 0 - Project Setup
- [x] Rojo config
- [x] Folder structure
- [ ] Core modules scaffold
- [ ] Git initialization

## 📊 Roadmap
- **Phase 1**: Procedural slope + movement
- **Phase 2**: Hazards + ragdoll physics
- **Phase 3**: Scoring, UI, shop
- **Phase 4**: Multiplayer + social
- **Phase 5**: Optimization + launch

---
**Version:** 0.1.0-alpha | **Status:** Active Development
