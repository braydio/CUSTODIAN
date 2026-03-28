# Runtime World & Camera Stabilization — Specification

**Project:** CUSTODIAN
**Status:** In Progress
**Feature:** Runtime World & Camera Stabilization
**Last Updated:** 2026-03-27

---

## 1. Purpose

Stabilize the active Godot runtime so the game operates in one coherent world space after procgen handoff. This solves the current mismatch between generated map space, player runtime space, camera bounds, mouse/world aim space, and navigation/collision space.

---

## 2. Why This Must Happen First

The project has a playable Godot combat slice with fixed-step simulation, operator movement, wave spawning, turret runtime, procgen contract map promotion, but:
- Camera bounds still derive from legacy sector bounds (hidden after procgen promotion)
- Camera handoff is broken in practice
- Firing direction can be wrong if camera/world alignment is stale
- Only some anchors are reliably repositioned

This blocks: free-roam pre-assault, campaign region deployment, hub-driven mission transitions, exploration, accurate cursor aiming, reliable camera feel.

---

## 3. Goals

When complete, all of the following must be true in live play:

1. Player spawns into promoted procgen map in correct location
2. Camera binds to promoted procgen world, not legacy sector bounds
3. Camera limits derive from procgen map bounds every time new contract world is generated
4. Mouse aim is correct after camera handoff
5. Terminal, item anchors, and interactables are reachable in procgen space
6. Navigation, collision, and visible walkable space agree
7. Exactly one authoritative runtime world-space model

---

## 4. Non-Goals

This feature does NOT implement:
- Hub campaign flow
- Biome regions
- World streaming between multiple large maps
- Compound wall construction overhaul
- New combat mechanics
- New animation sets
- New procgen layout logic (except where needed for handoff)

---

## 5. Current Runtime Reality

### Already Implemented
- Contract generation and procgen world promotion (`ContractWorldLoader`)
- Operator and spawn nodes repositioned into procgen space
- Camera has `set_runtime_map()` method
- Camera refresh called from contract loader
- Wave combat, turrets, sprint, melee, repair, terminal systems present

### Known Issues (From Analysis)
- Camera `_rebuild_bounds()` falls back to legacy sector bounds if procgen fails
- No explicit camera snap to player spawn on handoff
- Navigation tilemap references resolved via auto-discovery, not explicit binding
- Camera group registration present but may be inconsistent in some flows

---

## 6. Core Runtime Principle

There must be exactly one authoritative world-space chain:

```
ProcGenTilemap/LevelData
    -> runtime world bounds
    -> player placement
    -> camera binding
    -> mouse/world input
    -> spawn/anchor placement
    -> navigation/collision queries
```

Nothing in runtime should depend on hidden legacy sector bounds after procgen promotion.

---

## 7. Required Runtime Contracts

### 7.1 Active World Contract
Promoted procgen map instance is the active world authority.

### 7.2 Bounds Contract
Camera bounds derive from promoted map's used rect / runtime map bounds, not legacy sectors.

### 7.3 Player Contract
Player's position snapped into validated reachable spawn inside promoted map.

### 7.4 Anchor Contract
All required interactables re-anchored into reachable procgen coordinates.

### 7.5 Camera Contract
Camera explicitly rebinds to: new target, new world bounds, new follow position.

### 7.6 Input Contract
Mouse aim queries correct in live play after handoff.

### 7.7 Navigation Contract
Navigation rebuild uses promoted floor/wall tilemaps as current authority.

---

## 8. Failure Cases to Guard Against

| Case | Description |
|------|-------------|
| Legacy Bounds Leak | Camera still clamps to hidden sector world |
| Partial Handoff | Player moves in procgen space but camera/input still reference old space |
| Anchor Drift | Terminal or caches remain in legacy coordinates |
| Nav Desync | Visible floor exists but navigation graph still points to old tilemaps |
| First-Frame Camera Drift | Camera starts from old world then slowly lerps toward new target |
| False "Feels Bad" Diagnosis | Combat feels bad, but real issue is stale aim/camera transform |

---

## 9. Acceptance Criteria

### World Handoff
- [ ] Procgen map is promoted into runtime every run
- [ ] Active world references resolve to promoted map, not legacy sectors

### Camera
- [ ] Camera bounds derive from procgen map
- [ ] Camera snaps correctly to player on handoff
- [ ] Camera follow remains stable after snap
- [ ] Camera registered in "camera" group

### Operator
- [ ] Operator spawn is walkable and reachable
- [ ] Operator never spawns inside walls or isolated pockets

### Input
- [ ] Mouse aim is correct after handoff
- [ ] Bullet direction matches cursor location visually

### Anchors
- [ ] Terminal reachable in procgen space
- [ ] Item/cache anchors reachable in procgen space

### Navigation
- [ ] Navigation rebuild uses current promoted tilemaps
- [ ] AI pathing matches visible traversable space

### Feel
- [ ] World no longer feels "linked elsewhere"
- [ ] Player perceives procgen map as real active world

---

## 10. Files Likely to Modify

| File | Current State | Change Needed |
|------|---------------|---------------|
| `custodian/core/systems/contract_world_loader.gd` | Promotes map, repositions entities, calls camera refresh | Add explicit camera snap call, add navigation rebuild call |
| `custodian/scenes/camera.gd` | Has `set_runtime_map()`, falls back to legacy bounds | Force procgen bounds, add explicit snap_to_spawn() |
| `custodian/core/systems/navigation_system.gd` | Auto-finds tilemaps, has rebuild() | Receive explicit tilemap references after handoff |

---

## 11. Exit Condition

This feature is complete when you boot into a generated contract world and ALL of the following are true in the same session:
- Player movement feels local to the generated map
- Camera follows the generated world correctly
- Cursor aim is accurate
- Terminal and caches are reachable
- Enemies path through the promoted world correctly

If any one fails, this feature is NOT done.
