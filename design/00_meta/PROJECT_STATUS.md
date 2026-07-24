# CUSTODIAN — Project Status Summary

**Last Updated:** 2026-07-24

## Current Development Stage

**Playable Godot combat slice with runtime procgen contract world + campaign architecture designed**

The active Godot runtime boots into a generated contract context with full 7-system campaign architecture documented:

- PixelPlanets planet contract generation
- Procgen map generation promoted into the live world
- Local in-game terminal with contract/world snapshot and previews
- Wave combat, turrets, supply drops, sprint, melee, and repair loop foundations
- Campaign Flow, Hub, World Transition, Region Generation, and Compound Tile systems fully designed
- Autonomous combat drones (v1 complete)
- Vehicle registry + piloting system (in review)
- Elevation tileset (live, metadata-first)
- Ash-Bell encounter content (Forlorn-Ritualant) spec'd

## Implemented

| Feature | Status | Notes |
|---------|--------|-------|
| Wave spawning | Done | `wave_manager.gd`, lane spawn nodes, fast/heavy variants |
| Enemy director | Done | Threat, budget, lane/objective routing |
| Enemy objectives | Done | Structure-first targeting with player fallback |
| Enemy runtime visuals | Done | Base / fast / heavy variants use 8-direction humanoid sheets |
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
| Camera procgen bounds | Done | Camera derives bounds from `World/ProcGenRuntime` tilemaps |
| Camera snap to player spawn | Done | Camera snaps to procgen player spawn on load |
| Camera group registration | Done | Camera joins "camera" group for game feel hooks |
| Terminal repositioned | Done | Terminal moved to procgen coords |
| Ammo caches repositioned | Done | Caches moved to procgen coords |
| Weapon data system | Done | JSON weapon stats load from `content/weapons/` |
| Autonomous combat drones | Done | v1 complete with 4 modes, squad limits, independent HP |

## In Progress

| Feature | Status | Notes |
|---------|--------|-------|
| Mouse aim validation | Pending | Needs explicit validation against procgen camera handoff |
| Shadow system integration | Pending | Node2D procedural approach, TileMap path aspirational |
| Weapon data factory expansion | Incomplete | Factory reads 10 of 20+ schema fields |
| Power system values alignment | Minor drift | Design says 0.75 damaged efficiency, code uses 0.6 |
| Enemy director budget tuning | Minor drift | Code uses 0.65 budget multiplier vs design's 1.5 |
| Mission state machine | Planned | v0.4.0 milestone — phase enum, transitions, wave binding |
| Free-roam pre-assault | Design | v0.5.0 milestone — traverse, scavenge, power routing |
| Compound sectors as entities | Design | v0.6.0 milestone — COMMAND, POWER, DEFENSE, FABRICATION |
| ARRN relay network | Design | v0.7.0 milestone — 4 relay nodes, SCAN/STABILIZE/SYNC |
| World expansion & Hub | Design | v0.8.0 milestone — campaign flow, world transitions |
| Power & logistics | Design | v1.0 milestone — routing, load, blackout mechanics |
| Vehicle system | Review | v1.1 milestone — first pilotable vehicle, registry |

## Known Issues

| Priority | Issue | Impact |
|----------|-------|--------|
| **HIGH** | Mouse/world aim path still needs explicit validation against procgen camera handoff | Bullets/crosshair may drift if any caller still assumes stale world coordinates |
| **MEDIUM** | Shadow system is only partially coupled to procgen runtime updates | Visual readability can drift from live wall/floor state |
| **MEDIUM** | Weapon data factory reads only 10 of 20+ schema fields | Extended stats (crit, stagger, pellets) unused |
| **LOW** | Power values drift between doc (0.75) and code (0.6) | Tuning-impact only |
| **LOW** | Enemy director budget multiplier drifted (design 1.5, code 0.65) | Pacing was intentionally tuned |

## Not Yet Implemented

| Feature | Priority | Notes |
|---------|----------|-------|
| Named procgen sectors as real gameplay structures | High | Command/power/defense/fabrication should become authoritative spawned structures |
| Full assault loop against compound ingress/sector objectives | High | Current spawns route correctly, but objective semantics are still hybrid |
| Campaign flow state machine | High | Boot → Compound → Hub → Deploy → Mission → Return loop |
| Hub persistent state | High | Offers, knowledge archive, campaign history |
| Save/snapshot persistence | Medium | No campaign persistence yet |
| Fabrication/logistics gameplay | Medium | Economy layer still absent |
| ARRN relay / campaign progression | Medium | Not yet ported into Godot runtime |
| Compound tile system (full) | Low | Phase 1 via SIMPLIFIED_POWER_IN_ROOMS; full 15-type system is aspirational |

## Current Runtime Loop

1. Game boots into `res://scenes/game.tscn`
2. `World/ContractMap` generates a deterministic PixelPlanets contract + procgen map
3. `ContractWorldLoader` promotes the generated map into `World/ProcGenRuntime`
4. Static legacy sector visuals/collisions are disabled for runtime procgen play
5. **Operator is moved to procgen player spawn**
6. **Spawn nodes are projected to map edges** nearest compound ingress points
7. **Terminal, item anchors, and camera are rebound into procgen space**
8. Terminal interactable opens local command UI with:
   - world snapshot
   - contract metadata
   - planet preview
   - map preview
9. Combat loop proceeds with waves, enemies, turrets, supply drops, repair

## Main Risks / Gaps

- Mouse/world aim path still needs validation against the procgen camera handoff
- Compound buildings are currently visual/map-space structures, not yet instantiated as named authoritative sector entities
- Power and sector systems still reflect legacy/static assumptions in places
- Procgen readability is improved, but still needs aesthetic/autotile refinement
- Shadow coupling to dynamic procgen/runtime updates is still incomplete
- Campaign architecture is fully designed but not yet implemented — design-code drift risk grows the longer it stays unimplemented

## Next Priority

1. **FIX: Validate mouse/world aim path** — Confirm all aiming callers resolve correctly against procgen runtime camera state
2. **FIX: Shadow system integration** — Keep shadow overlay authoritative against live procgen wall/floor changes
3. **IMPLEMENT: Mission state machine** — v0.4.0 milestone (GameState phase enum, transitions)
4. **IMPLEMENT: Free-roam pre-assault** — v0.5.0 milestone (traverse, scavenge, fortification)
5. Promote compound pads into real spawned structures (`COMMAND`, `POWER`, `DEFENSE`, etc.)

---

## Milestone Roadmap

**See authoritative roadmap:** [`MASTER_ROADMAP.md`](MASTER_ROADMAP.md)

| Milestone | Target | Status | Focus |
|-----------|--------|--------|-------|
| v0.3.0 | TBD | in_progress | Procgen handoff fixes (mouse aim, shadow) |
| v0.4.0 | TBD | planned | Mission state machine |
| v0.5.0 | TBD | design | Free-roam pre-assault |
| v0.6.0 | TBD | design | Compound sectors as entities |
| v0.7.0 | TBD | design | ARRN relay network |
| v0.8.0 | TBD | design | World expansion & Hub |
| v1.0 | TBD | design | Power & logistics |
| v1.1 | TBD | design | Vehicle system |
| v1.2 | TBD | design | Command Terminal UI |
