# 📄 `design/04_architecture/RUNTIME_WORLD_CAMERA_STABILIZATION.md`

# Runtime World & Camera Stabilization

**Project:** CUSTODIAN
**Status:** Required First
**Priority:** Critical
**Blocks:** Hub, World Transition, Region Generation, Campaign Flow
**Runtime Target:** Godot 4.x (`custodian/`)
**Last Updated:** 2026-03-27

---

## 1. Purpose

Stabilize the active Godot runtime so the game operates in one coherent world space after procgen handoff.

This feature exists to solve the current mismatch between:

* generated map space
* player runtime space
* camera bounds
* mouse/world aim space
* navigation/collision space

At present, the runtime already supports contract generation, procgen world promotion, operator repositioning, spawn node redistribution, and some camera refresh support, but the procgen handoff is still incomplete and camera behavior remains broken in live play. The most important known issue is that camera bounds are still derived from legacy sector bounds rather than the promoted procgen map, which causes downstream aim and feel problems.  

This document defines the authoritative runtime contract that must be true before higher-level systems proceed.

---

## 2. Why This Must Happen First

The project is already past the “blank prototype” phase. The active runtime is a playable Godot combat slice with:

* fixed-step simulation
* operator movement
* wave spawning
* turret runtime
* procgen contract map promotion into the active world  

But several active plans now depend on correct procgen-world runtime behavior:

* free-roam pre-assault traversal
* campaign region deployment
* hub-driven mission transitions
* exploration outside the single combat slice
* accurate cursor aiming
* reliable camera feel

If world/camera/aim space is wrong, every later system will be built on false assumptions.

This feature is therefore not polish. It is runtime correctness.

---

## 3. Goals

When this feature is complete, all of the following must be true in live play:

1. The player spawns into the promoted procgen map in the correct location.
2. The camera binds to the promoted procgen world, not legacy sector bounds.
3. Camera limits derive from procgen map bounds every time a new contract world is generated.
4. Mouse aim is correct after camera handoff.
5. Terminal, item anchors, and other important interactables are reachable in procgen space.
6. Navigation, collision, and visible walkable space agree.
7. There is exactly one authoritative runtime world-space model.

---

## 4. Non-Goals

This feature does **not** implement:

* hub campaign flow
* biome regions
* world streaming between multiple large maps
* compound wall construction overhaul
* new combat mechanics
* new animation sets
* new procgen layout logic except where needed to stabilize handoff

If a task does not directly improve runtime world-space correctness, it is out of scope for this doc.

---

## 5. Current Runtime Reality

The current runtime includes a promoted procgen contract world and existing handoff support, but live behavior is still partially wrong.

Repo-grounded current state includes:

* contract generation and procgen world promotion are implemented
* operator and spawn nodes are repositioned into procgen space
* camera procgen support exists
* camera refresh is already called during contract world loading
* wave combat, turrets, sprint, melee, repair, and terminal systems are already present
* camera handoff remains broken in practice
* firing direction can be wrong if camera/world alignment is stale
* only some anchors are reliably repositioned
* camera registration/group wiring is incomplete or inconsistent in some flows   

This doc assumes those systems exist and focuses on making them coherent.

---

## 6. Core Runtime Principle

There must be exactly one authoritative world-space chain:

```plaintext
ProcGenTilemap/LevelData
    -> runtime world bounds
    -> player placement
    -> camera binding
    -> mouse/world input
    -> spawn/anchor placement
    -> navigation/collision queries
```

Nothing in runtime should still depend on hidden legacy sector bounds after procgen promotion.

The promoted procgen world must become the authority for:

* camera limits
* spawn positions
* interactable anchor positions
* world-space aiming
* reachable traversal space

---

## 7. Problem Breakdown

### 7.1 Camera Bounds Are Still Based on Legacy World

This is the highest-priority issue currently called out in project status. Camera bounds are rebuilt from legacy sector structures, which are hidden after procgen promotion, so the camera still behaves as if the old world is active. 

**Impact:**

* camera feels linked elsewhere
* follow behavior feels wrong
* cursor/world relationship drifts
* player perception of space becomes unreliable

---

### 7.2 No Hard Procgen Camera Rebind Contract

Camera support exists and refresh is already called from the contract loader, but the runtime lacks a clearly enforced handoff contract that says:

> “procgen map is now the active world; rebind all dependent systems now.”

Without that contract, reparenting and repositioning may happen, but the camera can remain semantically attached to the wrong world.  

---

### 7.3 Mouse Aim Depends on Correct World-Space Camera State

The operator still relies on `get_global_mouse_position()` for aim/fire, which is fine only if camera transform and bounds are correct after procgen handoff. This specifically needs runtime verification. 

**Impact:**

* bullets fire toward wrong world position
* ranged combat feels broken even when combat logic is fine
* player trust in controls collapses

---

### 7.4 Anchor Repositioning Is Incomplete

Procgen repositioning exists for some runtime entities, but project status notes that only some anchors are properly moved in all cases; terminal, caches, and other important objects can remain in legacy coordinates depending on flow/state. 

**Impact:**

* player sees a generated map but interacts with misplaced gameplay objects
* free-roam prep feels fake
* terminal and loot access become unreliable

---

### 7.5 Navigation, Collision, and Visual World Need Hard Agreement

The active navigation system uses floor tilemap cells as walkability authority and blocks cells occupied by walls tilemap cells. That is good, but after procgen handoff the runtime must guarantee:

* floor tilemap in active world is the current walkability source
* wall tilemap matches visible impassables
* player and enemies use the promoted world tilemaps
* runtime rebuild order is correct

Your current navigation system already builds an `AStar2D` graph from walkable floor cells and excludes wall cells. That means this feature must preserve tilemap authority rather than invent a parallel world-space movement model. 

---

## 8. Required Runtime Contract

After a contract map is generated and promoted:

### 8.1 Active World Contract

The promoted procgen map instance is the active world authority.

### 8.2 Bounds Contract

Camera bounds derive from the promoted map’s used rect / runtime map bounds, not legacy sectors.

### 8.3 Player Contract

The player’s position is snapped into a validated reachable spawn inside the promoted map.

### 8.4 Anchor Contract

All required interactables are re-anchored into reachable procgen coordinates.

### 8.5 Camera Contract

The camera explicitly rebinds to:

* new target
* new world bounds
* new follow position

### 8.6 Input Contract

Mouse aim queries are correct in live play after handoff.

### 8.7 Navigation Contract

Navigation rebuild uses the promoted floor/wall tilemaps as current authority.

---

## 9. Scene/Ownership Model

The runtime should follow a strict ownership model.

### 9.1 Required Scene-Level Conceptual Structure

```plaintext
GameRoot
├── World
│   ├── ProcGenRuntime
│   │   └── ActiveProcGenMap
│   ├── Enemies
│   ├── SpawnNodes
│   └── RuntimeAnchors
├── Operator
├── Camera
├── UI
└── Systems
```

The important part is not the exact tree spelling. The important part is that the procgen map is promoted into a stable runtime container that every dependent system can reference.

---

### 9.2 Ownership Rules

* `ContractWorldLoader` owns promotion and rebinding sequence.
* `Camera` owns follow/bounds behavior only.
* `Operator` owns local input interpretation and combat execution only.
* `NavigationSystem` owns walkability graph rebuilding only.
* The procgen map instance owns level data and tilemap authority.

No system should silently infer authority from hidden legacy sectors after procgen promotion.

---

## 10. Implementation Sequence

This must happen in a strict order.

### Step 1 — Generate contract

The contract system produces:

* planet
* procgen map
* level data

This is already implemented. 

### Step 2 — Promote procgen map into active runtime world

The generated map is reparented into the runtime world container.

### Step 3 — Resolve active tilemap references

Get authoritative references to:

* floor tilemap
* walls tilemap
* level data
* map bounds

### Step 4 — Reposition runtime entities

Move:

* operator
* spawn nodes
* terminal
* caches
* other required anchors

### Step 5 — Rebuild camera bounds

Bounds must be computed from the promoted procgen map.

### Step 6 — Explicitly rebind camera

Camera target + bounds + follow origin must all be reset.

### Step 7 — Rebuild navigation

Navigation graph must be rebuilt against promoted tilemaps.

### Step 8 — Validate aim/input

Verify `get_global_mouse_position()` produces correct world-space aim after handoff.

### Step 9 — Emit runtime-ready state

Only after all the above should the world be considered ready for player control / wave flow.

---

## 11. Detailed Implementation Notes

## 11.1 ContractWorldLoader Responsibilities

This system becomes the hard authority for procgen handoff completion.

### It must:

* receive generated contract payload
* promote the procgen map
* resolve map bounds
* move world anchors
* notify camera
* notify navigation
* optionally notify wave/mission systems that world is ready

### It must not:

* leave camera bound calculation implicit
* rely on hidden scene structures for bounds
* assume child nodes stayed in valid positions after promotion

---

## 11.2 Procgen Bounds Calculation

The runtime needs one reusable function that computes bounds from the actual active map, not assumptions.

Preferred source order:

1. explicit procgen map bounds API if present
2. floor tilemap used rect
3. level data bounds fallback

### Conceptual implementation

```gdscript
func get_active_runtime_bounds() -> Rect2:
    if active_map_instance and active_map_instance.has_method("get_runtime_bounds"):
        return active_map_instance.get_runtime_bounds()

    var floor := get_active_floor_tilemap()
    if floor:
        var used := floor.get_used_rect()
        var pos := floor.to_global(floor.map_to_local(used.position))
        var size := Vector2(used.size.x * 32, used.size.y * 32)
        return Rect2(pos, size)

    return Rect2()
```

Important: this must be derived from the promoted map, not any static sector layout.

---

## 11.3 Camera Rebind Contract

A camera refresh call is not enough by itself unless it explicitly rebinds target and bounds to procgen data.

### Required camera API

```gdscript
func set_runtime_target(target: Node2D) -> void
func set_runtime_bounds(bounds: Rect2) -> void
func snap_to_target() -> void
func rebuild_procgen_limits(bounds: Rect2) -> void
```

The name can differ, but behavior must be explicit.

### On handoff:

* set target to operator
* set bounds to promoted procgen bounds
* snap camera to player spawn once
* then resume smoothed follow

Without the snap, first-frame camera motion can feel detached.

---

## 11.4 Camera Group Registration

Project status specifically notes that some game-feel queries use `get_tree().get_first_node_in_group("camera")`, but camera registration is inconsistent, which can make shake/hit feedback no-op. 

This feature must enforce:

* active runtime camera always joins `camera` group on `_ready()`
* there is exactly one primary gameplay camera active during play

---

## 11.5 Operator Spawn Validation

The operator should not simply use an arbitrary map coordinate. Spawn must be validated.

### Valid spawn rules:

* on a walkable floor cell
* not inside walls
* reachable from nearby traversal space
* near intended entry/courtyard if such data exists
* fallback to `level_data.player_spawn` only if validation fails

This matches the direction already documented in the contract system integration notes. 

---

## 11.6 Runtime Anchor Placement

The following must be explicitly placed in procgen-reachable space:

* command terminal
* ammo/resource caches
* supply/item anchors used during prep
* any mission-critical interaction props

Placement rules:

* walkable tile only
* not wall-locked
* not isolated in inaccessible pockets
* within reasonable reach of player pathing

This is mandatory for free-roam prep to feel real rather than staged. 

---

## 11.7 Navigation Rebuild

The existing navigation system already:

* finds floor tilemap
* checks wall tilemap occupancy
* builds an `AStar2D` graph from walkable cells
* connects cardinal neighbors
* supports rebuilds 

So the correct requirement is not “invent new navigation.”

The correct requirement is:

> after procgen promotion, navigation references must point to the promoted runtime tilemaps, then rebuild must be called once.

### Required post-handoff call sequence

```gdscript
navigation_system.floor_tilemap_path = ...
navigation_system.walls_tilemap_path = ...
navigation_system.rebuild()
```

or equivalent active-node resolution path.

---

## 11.8 Mouse Aim Verification

Because operator aiming still depends on mouse world position, this feature requires an explicit live-play verification pass.

### Required checks:

* cursor directly above player aims up correctly
* cursor at map edges still maps correctly
* camera clamp does not skew aim space
* bullets and hit traces align with visible cursor target

This is a validation requirement, not optional polish.

---

## 12. Required Debug Instrumentation

This feature needs temporary debug tooling so you can prove it works.

### 12.1 Bounds Visualization

Draw current camera/world bounds rectangle in debug mode.

### 12.2 Spawn Markers

Draw:

* player spawn
* terminal anchor
* cache anchors
* corridor spawns

### 12.3 Tilemap Authority Logging

Print current active references:

* floor tilemap node path
* walls tilemap node path
* active map instance name/path
* world bounds rect

### 12.4 Camera Debug

Print:

* camera global position
* camera target
* camera bounds
* current follow mode

### 12.5 Aim Debug

Optional debug ray from player to current mouse world position.

These tools should be removable later, but they are necessary during stabilization.

---

## 13. Failure Cases to Explicitly Guard Against

### 13.1 Legacy Bounds Leak

Camera still clamps to hidden sector world.

### 13.2 Partial Handoff

Player moves in procgen space but camera/input still reference old space.

### 13.3 Anchor Drift

Terminal or caches remain in legacy coordinates.

### 13.4 Nav Desync

Visible floor exists but navigation graph still points to old tilemaps.

### 13.5 First-Frame Camera Drift

Camera starts from old world then slowly lerps toward new target.

### 13.6 False “Feels Bad” Diagnosis

Combat feels bad, but the real issue is stale aim/camera transform.

---

## 14. Acceptance Criteria

This feature is done only when all criteria below are true in live play.

### World Handoff

* [ ] Procgen map is promoted into runtime every run
* [ ] Active world references resolve to promoted map, not legacy sectors

### Camera

* [ ] Camera bounds derive from procgen map
* [ ] Camera snaps correctly to player on handoff
* [ ] Camera follow remains stable after snap
* [ ] Camera is registered in `camera` group

### Operator

* [ ] Operator spawn is walkable and reachable
* [ ] Operator never spawns inside walls or isolated pockets

### Input

* [ ] Mouse aim is correct after handoff
* [ ] Bullet direction matches cursor location visually

### Anchors

* [ ] Terminal is reachable in procgen space
* [ ] Item/cache anchors are reachable in procgen space

### Navigation

* [ ] Navigation rebuild uses current promoted tilemaps
* [ ] AI pathing matches visible traversable space

### Feel

* [ ] World no longer feels “linked elsewhere”
* [ ] The player perceives procgen map as the real active world

---

## 15. Recommended File Targets

These are likely touch points for implementation.

### Existing systems likely to modify

* `custodian/core/systems/contract_world_loader.gd`
* `custodian/scenes/camera.gd`
* `custodian/entities/operator/operator.gd`
* `custodian/core/systems/navigation_system.gd`

### Optional new helper

* `custodian/core/systems/runtime_world_binding.gd`

---

## 16. Implementation Notes for Later Systems

Once this feature is complete, later docs may assume:

* procgen map is authoritative runtime world
* camera can safely rebind on world transitions
* region loading can reuse the same handoff contract
* hub deployment can target stable world-space destinations
* free-roam traversal is real and not faked

This is the foundation that allows Files 2–7 to be implemented sanely.

---

## 17. Exit Condition

This file is complete when you can boot into a generated contract world and all of the following are true in the same session:

* player movement feels local to the generated map
* camera follows the generated world correctly
* cursor aim is accurate
* terminal and caches are reachable
* enemies path through the promoted world correctly

If any one of those fails, this feature is not done.

---

# Progress Tracking

## Previous Files

* [1] Runtime World & Camera Stabilization

## Upcoming Files

* [2] Hub System (Meta Progression)
* [3] World Transition System
* [4] Region Generation System
* [5] Compound Tile System
* [6] Campaign Flow & Game Loop
* [7] Integration Contract (Glue Layer)

