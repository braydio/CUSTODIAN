# CUSTODIAN Development Roadmap

**Last Updated:** 2026-03-27

---

## Milestones

### Milestone 1: Procgen Handoff ✅ DONE (Partially Broken)
**Target:** 2026-03-15 | **Status:** ⚠️ IN PROGRESS

| Feature | Status | Notes |
|---------|--------|-------|
| Contract planet generation | ✅ Complete | PixelPlanets integrated |
| Procgen map promotion | ✅ Complete | Runtime loads generated map |
| Operator repositioning | ✅ Complete | Moved to procgen spawn |
| Spawn node projection | ✅ Complete | Edge spawns aligned |
| Terminal in-world UI | ✅ Complete | Local command interface |
| Camera procgen bounds | ❌ BROKEN | Still uses legacy sector bounds |
| Mouse aim correction | ❌ BROKEN | Wrong world position |
| Game feel hooks | ❌ BROKEN | Camera not in "camera" group |

**Blockers:**
- Camera limits rebuilt from `/root/GameRoot/World/Sectors` (hidden after procgen)
- Firing uses stale `get_global_mouse_position()`
- Terminal, ammo caches not repositioned

---

### Milestone 2: Mission State Machine 📋 PLANNED
**Target:** 2026-04-01 | **Status:** 📋 PLANNED

| Feature | Status | Notes |
|---------|--------|-------|
| GameState phase enum | 📋 Planned | CONTRACT_BRIEFING → etc. |
| Phase transition logic | 📋 Planned | State machine implementation |
| WaveManager phase binding | 📋 Planned | Only run during ASSAULT_ACTIVE |
| Phase UI indicators | 📋 Planned | HUD shows current phase |

---

### Milestone 3: Free-Roam Pre-Assault 🧠 DESIGN
**Target:** 2026-04-15 | **Status:** 🧠 DESIGN

| Feature | Status | Notes |
|---------|--------|-------|
| Traverse procgen compound | 🧠 Design | Player movement in map |
| Scavenge gameplay | 🧠 Design | Pick up resources/items |
| Power routing mechanics | 🧠 Design | Connect structures |
| Fortification system | 🧠 Design | Place defenses |
| Terminal prep commands | 🧠 Design | In-terminal interactions |
| Manual assault trigger | 🧠 Design | Player starts waves |

**Doc:** `02_features/free_roam/implementation.md`

---

### Milestone 4: Compound Sectors as Entities 🧠 DESIGN
**Target:** 2026-04-30 | **Status:** 🧠 DESIGN

| Feature | Status | Notes |
|---------|--------|-------|
| COMMAND sector spawn | 🧠 Design | Command center entity |
| POWER sector spawn | 🧠 Design | Power generator entity |
| DEFENSE sector spawn | 🧠 Design | Defense structure entity |
| FABRICATION sector spawn | 🧠 Design | Factory entity |
| Sector damage integration | 🧠 Design | Full damage system coupling |

---

### Milestone 5: ARRN (Relay Network) 🧠 DESIGN
**Target:** 2026-04-15 | **Status:** 🧠 DESIGN

| Feature | Status | Notes |
|---------|--------|-------|
| ARRN Manager & data model | 🧠 Design | Autoload + relay state |
| Relay entities in world | 🧠 Design | 4 relays (N/S/Archive/Gateway) |
| SCAN RELAYS command | 🧠 Design | Terminal integration |
| STABILIZE RELAY task | 🧠 Design | Field interaction |
| SYNC & knowledge progression | 🧠 Design | Command center sync |
| Tick/decay system | 🧠 Design | Assault-aware decay |
| Benefit activation | 🧠 Design | 7 knowledge unlocks |

**Doc:** `02_features/arrn/implementation.md`

---

### Milestone 6: World Expansion & The Hub 🧠 DESIGN
**Target:** 2026-05-30 | **Status:** 🧠 DESIGN

| Feature | Status | Notes |
|---------|--------|-------|
| World Manager system | 🧠 Design | Multi-world transitions |
| Hub data structures | 🧠 Design | Campaign state |
| Scenario generation | 🧠 Design | Deterministic missions |
| Terminal Hub UI | 🧠 Design | Campaign selection |
| Tile-based compound | 🧠 Design | Wall tile entities |
| Power conduit walls | 🧠 Design | Power routing |
| Region world generation | 🧠 Design | Biome-based levels |

**Doc:** `02_features/world_expansion/implementation.md`

| Feature | Status | Notes |
|---------|--------|-------|
| ARRN Manager & data model | 🧠 Design | Autoload + relay state |
| Relay entities in world | 🧠 Design | 4 relays (N/S/Archive/Gateway) |
| SCAN RELAYS command | 🧠 Design | Terminal integration |
| STABILIZE RELAY task | 🧠 Design | Field interaction |
| SYNC & knowledge progression | 🧠 Design | Command center sync |
| Tick/decay system | 🧠 Design | Assault-aware decay |
| Benefit activation | 🧠 Design | 7 knowledge unlocks |

**Doc:** `02_features/arrn/implementation.md`

---

### Milestone 6: Animation & Polish 🎨 IN PROGRESS
**Target:** 2026-03-30 | **Status:** 🎨 IN PROGRESS

| Feature | Status | Notes |
|---------|--------|-------|
| Reload state | 🎨 In Progress | Ranged weapon reload |
| Interact state | 🎨 In Progress | World interaction visual |
| Pickup state | 🎨 In Progress | Scavenging visual |
| Repair state | 🎨 Planned | Repair gameplay visual |
| Crouch state | 🎨 Planned | Tactical option |
| Shadow system | 🎨 In Progress | Implementation underway |

**Docs:**
- `02_features/operator/implementation.md`
- `02_features/shadow/implementation.md`

---

### Milestone 7: Power & Logistics Systems 🧠 DESIGN
**Target:** 2026-05-15 | **Status:** 🧠 DESIGN

| Feature | Status | Notes |
|---------|--------|-------|
| Power generation | 🧠 Design | Sector-based power |
| Power routing | 🧠 Design | Structure connections |
| Load management | 🧠 Design | Power distribution |
| Blackout mechanics | 🧠 Design | Low power consequences |
| Logistics economy | 🧠 Design | Resource flow |
| Fabrication system | 🧠 Design | Craft/blueprints |

---

### Milestone 8: Save System 💾 BACKLOG
**Target:** TBD | **Status:** 💾 BACKLOG

| Feature | Status | Notes |
|---------|--------|-------|
| Campaign persistence | 💾 Backlog | Save/load game state |
| Contract history | 💾 Backlog | Track completed contracts |
| Player progress | 💾 Backlog | XP, unlocks, upgrades |

---

### Milestone 7: Economy & Logistics 💰 BACKLOG
**Target:** TBD | **Status:** 💰 BACKLOG

| Feature | Status | Notes |
|---------|--------|-------|
| Resource economy | 💰 Backlog | Credits, materials |
| Fabrication system | 💰 Backlog | Build/craft items |
| Supply chain | 💰 Backlog | Resource gathering |
| Market/trade | 💰 Backlog | Buy/sell system |

---

## Completed Milestones

| Milestone | Completed | Notes |
|-----------|-----------|-------|
| Wave spawning system | 2026-03-08 | Lane spawns, variants |
| Enemy director | 2026-03-08 | Threat, budget, routing |
| Turret system | 2026-03-06 | 4 archetypes, targeting |
| Player ranged combat | 2026-03-10 | Ammo, cooldowns |
| Player melee combat | 2026-03-12 | Timing, hit-stop |
| Sprint & stamina | 2026-03-10 | Stamina HUD |
| Repair gameplay | 2026-03-07 | Hold repair |
| Supply drops | 2026-03-11 | Resource drops |
| Contract world loader | 2026-03-14 | Procgen promotion |
| Runtime wall collision | 2026-03-15 | Explicit colliders |

---

## Upcoming Releases

```
v0.3.0 - Procgen Handoff Fixes
  └── Release date: TBD (blocking: camera fixes)

v0.4.0 - Mission Flow
  └── Release date: TBD (depends on v0.3.0)

v0.5.0 - Free-Roam Beta
  └── Release date: TBD (depends on v0.4.0)
```

---

## Dependencies

```
v0.3.0 (Procgen Fixes)
├── Camera bounds from procgen
├── Camera snap to player
├── Reposition anchors
└── Camera group registration
    │
    └──▶ v0.4.0 (Mission Flow)
        ├── Phase state machine
        ├── WaveManager binding
        └── Phase UI
            │
            └──▶ v0.5.0 (Free-Roam)
                ├── Traverse map
                ├── Scavenge
                ├── Power routing
                └── Manual trigger
```

---

*See `TRACKING.md` for sprint-level task tracking.*
