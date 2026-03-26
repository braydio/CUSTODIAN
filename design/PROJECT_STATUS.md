# CUSTODIAN — Project Status Summary

**Last Updated:** 2026-03-12

## Current Development Stage

**Playable Godot combat slice with runtime procgen contract world**

The active Godot runtime now boots into a generated contract context:

- PixelPlanets planet contract generation
- Procgen map generation promoted into the live world
- Local in-game terminal with contract/world snapshot and previews
- Wave combat, turrets, supply drops, sprint, melee, and repair loop foundations

## Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| Wave spawning | Done | `wave_manager.gd`, lane spawn nodes, fast/heavy variants |
| Enemy director | Done | Threat, budget, lane/objective routing |
| Enemy objectives | Done | Structure-first targeting with player fallback |
| Enemy runtime visuals | Done | Base / fast / heavy variants now use 8-direction humanoid sheets in live wave spawns |
| Turrets | Done | 4 archetypes, powered targeting and firing |
| Player ranged combat | Done | Standard/heavy profiles, ammo, cooldowns |
| Player melee combat | Done | Fast/heavy/combo timing, hit-stop, camera shake |
| Sprint and stamina | Done | `CTRL` sprint, stamina HUD |
| Repair gameplay slice | Done | Hold repair on damaged structures |
| Supply drops | Done | Periodic resource drop loop |
| Local command terminal | Done | In-world interactable, no HTTP dependency |
| Contract planet generation | Done | PixelPlanets integrated into runtime |
| Runtime procgen map loading | Done | Generated map is promoted into active world |
| Terminal previews | Done | Planet render + map preview in terminal |
| Procgen compound zone | Done | Structured base footprint, ingress points, edge spawn projection |
| Runtime wall collision | Done | Explicit wall colliders built from generated wall cells |
| Game feel: hit-stop | Done | Time scale freeze on hit |
| Game feel: screen shake | Done | Camera shake on hit |
| Game feel: knockback | Done | Push enemies on melee hit |
| Game feel: damage flash | Done | White flash on damage |

## In Progress

| Feature | Status | Notes |
|---------|--------|-------|
| Procgen camera handoff | **BROKEN** | Camera still follows legacy sector bounds, not procgen map |
| Compound identity pass | Partial | Compound has sector-like footprints, but named sector roles are not yet instantiated as real entities |
| Procgen layout tuning | Partial | Open/cave variety added, but still needs feel iteration |
| Sector damage integration | Partial | Runtime systems exist; procgen compound and damage semantics still need deeper coupling |
| Animation overhaul integration | Partial | Runtime uses updated attacks/sprint/drone hooks, but animation set is still evolving |

## Known Issues (Procgen Handoff)

| Priority | Issue | Impact |
|----------|-------|--------|
| **HIGH** | Camera bounds rebuilt from `/root/GameRoot/World/Sectors` which are hidden after procgen promotion | Camera feels "linked elsewhere", doesn't follow procgen map |
| **HIGH** | Firing direction uses `get_global_mouse_position()` which is wrong if camera bounds are stale | Bullets fire toward wrong world position |
| **MEDIUM** | Only Operator and SpawnNodes are repositioned to procgen space | Terminal, ammo caches, other anchors remain in legacy coords |
| **MEDIUM** | No explicit camera rebind after contract generation | Camera never snaps to procgen player spawn |
| **LOW** | Game feel scripts query `get_tree().get_first_node_in_group("camera")` but camera never registers to that group | Screen shake is no-op |

## Not Yet Implemented

| Feature | Priority | Notes |
|---------|----------|-------|
| Named procgen sectors as real gameplay structures | High | Command/power/defense/fabrication should become authoritative spawned structures |
| Full assault loop against compound ingress/sector objectives | High | Current spawns route correctly, but objective semantics are still hybrid |
| Save/snapshot persistence | Medium | No campaign persistence yet |
| Fabrication/logistics gameplay | Medium | Economy layer still absent |
| ARRN relay / campaign progression | Medium | Not yet ported into Godot runtime |

## Current Runtime Loop

1. Game boots into `res://scenes/game.tscn`
2. `World/ContractMap` generates a deterministic PixelPlanets contract + procgen map
3. `ContractWorldLoader` promotes the generated map into `World/ProcGenRuntime`
4. Static legacy sector visuals/collisions are disabled for runtime procgen play
5. **Operator is moved to procgen player spawn**
6. **Spawn nodes are projected to map edges** nearest compound ingress points
7. Terminal interactable opens local command UI with:
   - world snapshot
   - contract metadata
   - planet preview
   - map preview
8. Combat loop proceeds with waves, enemies, turrets, supply drops, repair

**NOTE:** The procgen handoff is PARTIAL. Camera, terminal, ammo caches, and other anchors remain in legacy static scene coordinates. Only Operator and SpawnNodes are repositioned.

## Main Risks / Gaps

- Camera still follows old sector bounds, causing aim/bounds issues
- Compound buildings are currently visual/map-space structures, not yet instantiated as named authoritative sector entities.
- Power and sector systems still reflect legacy/static assumptions in places.
- Procgen readability is improved, but still needs aesthetic/autotile refinement.
- Game feel shake doesn't work (camera not in "camera" group)

## Next Priority

1. **FIX: Camera procgen handoff** - Derive bounds from `World/ProcGenRuntime` tilemaps, not `World/Sectors`
2. **FIX: Camera snap to procgen player** - Rebind camera position when ContractWorldLoader finishes
3. **FIX: Move other anchors** - Reposition terminal, ammo caches to procgen coords
4. **FIX: Register camera to group** - Add camera to "camera" group for game feel hooks
5. Promote compound pads into real spawned structures (`COMMAND`, `POWER`, `DEFENSE`, etc.)
6. Bind assault objectives directly to procgen compound ingress/sector targets

---

## Free-Roam Pre-Assault Roadmap

**NEW:** See `design/FREE_ROAM_PRE_ASSAULT_WALKTHROUGH.md` for the complete implementation plan to add free-roam exploration and strategic prep before assault begins.

### Quick Summary
- **Phase 0:** Procgen handoff fixes (camera, firing, group registration)
- **Phase 1:** Mission state machine (CONTRACT_BRIEFING → FREE_ROAM_PREP → ASSAULT_ACTIVE → POST_ASSAULT → EXFIL)
- **Phase 2:** Manual assault trigger via terminal command
- **Phase 3:** Authoritative procgen sectors as interactable entities
- **Phase 4:** Real prep systems (fabrication, fortification, power routing, scavenging)
- **Phase 5:** Terminal interface for all prep commands

**Why this matters:** The current runtime immediately starts wave combat after 15 seconds. This roadmap enables players to traverse the map, prepare defenses, scavenge resources, and CHOOSE when to start the assault.

---

## Operator Animation State Machine

**NEW:** See `design/OPERATOR_ANIMATION_STATE_MACHINE.md` for the complete state transition mapping and missing state implementation plan.

### Current State
- State machine is now connected to the operator attack + locomotion request path; block is live, while reload/interact and broader non-combat states are still pending
- Operator directly controls `AnimatedSprite2D` instead of using state machine
- Existing states: idle, walk, sprint, attack_fast, attack_heavy, attack_dash, equip_weapon, stagger, death

### Missing States (Priority Order)
1. **RELOAD** - High priority, ranged weapons need reload
2. **INTERACT** - High priority, world interaction needs visual
3. **PICKUP** - Medium priority, scavenging needs visual
4. **REPAIR** - Medium priority, repair gameplay exists
5. **CROUCH** - Low priority, tactical option

### Implementation Path
- Phase 1: Wire state machine to operator + create Block/Reload/Interact states
- Phase 2: Create Pickup/Repair/Crouch states
- Phase 3: Polish (victory, emotes)
