# Pre-Task Queue

Dump raw task ideas here. No formatting required — just get it out of your head.

When you're ready to process, run: `bash tools/codex_ingest.sh`

---

Yes—that is the correct destination.

I conflated two different Sundered Keep levels:

* **Wrong:** `ReturnCausewayApproach.tscn`, the unfinished procedural causeway with the invented identity-imprint sequence.
* **Correct:** the large Sundered Keep map built around `sundered_keep_main_overlay.png`, reviewed and collision-authored through `sundered_keep_underlay_collision_mapper.tscn`.

## What that mapper actually represents

The mapper loads:

```text
custodian/scenes/debug/sundered_keep_production_underlay_debug.tscn
```

That scene displays:

```text
custodian/content/masters/sundered_keep/sundered_keep_main_overlay.png
```

and scales it into the `3584×2560` / `112×80` gameplay area. It already includes a real Operator and gameplay camera for collision review.

The mapper-authored data currently includes:

* manually traced capsule collision rails;
* spawn;
* Return Causeway entrance;
* gatehouse key;
* main raising gate;
* level exit;
* two enemy-spawn positions.

That is clearly the substantial, complete-art Sundered Keep level you intended.

## The important current defect

The mapper collision is **not yet production authority**.

The mapper currently writes `UNDERLAY_BOUNDARY_SEGMENTS` into:

```text
custodian/scenes/debug/sundered_keep_production_underlay_debug.gd
```

and the debug scene constructs `MappedUnderlayBounds/UnderlayBoundaryCollision` from those segments.

Meanwhile, the production front-gate route loads:

```text
custodian/game/world/sundered_keep/sundered_keep_map.tscn
```

using:

```text
custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json
```

That production definition uses the same `sundered_keep_main_overlay.png` and the same `112×80` map dimensions.

However, repository documentation explicitly says the mapped rails remain debug-only until deliberately promoted into `SunderedKeepMap`.

So the correct job is:

> Route the Vista directly into `sundered_keep_front_gate`, and promote the collision mapper’s authored data into that production map.

Do **not** route into the mapper `.tscn` itself. It is an editing shell with its own `GameRoot`, Operator, camera, HUD, and mouse-authoring controls.

# Exact Codex correction

```text
Correct the production Sundered Keep route and promote the manually mapped
underlay collision into the actual large Sundered Keep map.

Repository root:

/home/braydenchaffee/Projects/CUSTODIAN

INTENDED LEVEL

The intended post-Vista destination is:

level_id:
sundered_keep_front_gate

scene:
custodian/game/world/sundered_keep/sundered_keep_map.tscn

authored layout:
custodian/content/levels/sundered_keep/
sundered_keep_front_gate_large.json

master artwork:
custodian/content/masters/sundered_keep/
sundered_keep_main_overlay.png

The collision source currently authored through:

custodian/scenes/debug/
sundered_keep_underlay_collision_mapper.tscn

must be promoted into that production level.

The unfinished procedural Return Causeway level is not the intended production
destination.
```

## 1. Correct the route

Modify:

```text
custodian/content/routes/sundered_keep/sundered_keep_route.json
```

Production should use:

```json
{
  "profile_id": "production",
  "entry_edge_id": "enter_vista",
  "enabled_edge_ids": [
    "enter_vista",
    "vista_to_keep_direct",
    "vista_exfil",
    "keep_to_vista_direct",
    "keep_exfil"
  ]
}
```

Add the reverse edge if it does not exist locally:

```json
{
  "edge_id": "keep_to_vista_direct",
  "from_node_id": "front_gate",
  "exit_id": "backtrack",
  "to_node_id": "vista_approach",
  "target_spawn_id": "ReturnTopdown",
  "direction": "back",
  "transition_style": "fade"
}
```

The repository already defines `vista_to_keep_direct`, targeting the correct `front_gate` node.

Keep Return Causeway available only through an isolated debug profile.

Change the Vista exit prompt to:

```text
ENTER SUNDERED KEEP
```

not:

```text
CONTINUE TO RETURN CAUSEWAY
```

## 2. Move mapper data into canonical content

Create:

```text
custodian/content/levels/sundered_keep/
sundered_keep_underlay_collision.json
```

Schema:

```json
{
  "schema": "custodian.sundered_keep.underlay_collision.v1",
  "map_size_pixels": [3584, 2560],
  "rail_radius": 18.0,
  "segments": [],
  "markers": {}
}
```

Migrate the current contents of:

```gdscript
UNDERLAY_BOUNDARY_SEGMENTS
UNDERLAY_AUTHORING_MARKERS
```

from:

```text
custodian/scenes/debug/
sundered_keep_production_underlay_debug.gd
```

into that JSON without changing coordinates.

Use ordinary arrays:

```json
{
  "segments": [
    [[1870.9, 2936.8], [1732.6, 2970.1]],
    [[1732.6, 2970.1], [1658.8, 2960.0]]
  ]
}
```

Marker format:

```json
{
  "markers": {
    "spawn": {
      "kind": "spawn",
      "label": "SPAWN",
      "position": [1808.0, 2448.0]
    },
    "main_gate": {
      "kind": "gate",
      "label": "RAISING GATE",
      "position": [1792.0, 1600.0]
    }
  }
}
```

The exact existing marker coordinates must be preserved.

## 3. Make the mapper edit the JSON

Modify:

```text
custodian/scenes/debug/
sundered_keep_underlay_collision_mapper.gd
```

Replace:

```gdscript
const UNDERLAY_DEBUG_SCRIPT_PATH := (
    "res://scenes/debug/"
    + "sundered_keep_production_underlay_debug.gd"
)
```

with:

```gdscript
const UNDERLAY_COLLISION_DATA_PATH := (
    "res://content/levels/sundered_keep/"
    + "sundered_keep_underlay_collision.json"
)
```

`Enter` / `U` should now serialize:

* current complete segment set;
* current authoring markers;
* rail radius;
* map dimensions;

to the JSON file.

Do not rewrite a GDScript source file anymore.

The mapper remains the visual authoring interface, but its output becomes runtime content rather than debug-script constants.

## 4. Make the debug scene consume canonical data

Modify:

```text
custodian/scenes/debug/
sundered_keep_production_underlay_debug.gd
```

Remove the duplicated hard-coded segment and marker constants after migration.

Load:

```text
res://content/levels/sundered_keep/
sundered_keep_underlay_collision.json
```

and construct the same:

```text
World/MappedUnderlayBounds/UnderlayBoundaryCollision
World/UnderlayAuthoringMarkers
```

This preserves the current collision-review experience while eliminating data duplication.

## 5. Make `SunderedKeepMap` consume the same collision

Modify:

```text
custodian/game/world/sundered_keep/sundered_keep_map.gd
```

Add:

```gdscript
const UNDERLAY_COLLISION_DATA_PATH := (
    "res://content/levels/sundered_keep/"
    + "sundered_keep_underlay_collision.json"
)

const DEFAULT_UNDERLAY_RAIL_RADIUS := 18.0
```

During `_build_from_level_data()`, after the world layers and underlay are created, call:

```gdscript
_build_mapped_underlay_collision()
```

Production hierarchy:

```text
SunderedKeepMap
├── Underlay
├── MappedUnderlayBounds
│   └── UnderlayBoundaryCollision
│       ├── UnderlayBoundarySegment_001
│       ├── UnderlayBoundarySegment_002
│       └── ...
├── GameplayBlockers
├── Exits
└── ...
```

Each segment should use the same capsule construction currently used by the debug scene:

```gdscript
func _add_mapped_boundary_segment(
    parent: StaticBody2D,
    node_name: String,
    a: Vector2,
    b: Vector2,
    radius: float
) -> CollisionShape2D:
    var direction := b - a
    var length := direction.length()

    var rail := CapsuleShape2D.new()
    rail.radius = radius
    rail.height = maxf(
        length + radius * 2.0,
        radius * 2.0
    )

    var shape := CollisionShape2D.new()
    shape.name = node_name
    shape.shape = rail
    shape.position = (a + b) * 0.5

    if length > 0.001:
        shape.rotation = direction.angle() - PI * 0.5

    shape.set_meta("boundary_a", a)
    shape.set_meta("boundary_b", b)
    shape.set_meta("collision_authority", "underlay_mapper")
    parent.add_child(shape)

    return shape
```

That reproduces the reviewed mapper collision exactly.

## 6. Define collision authority correctly

The mapped rails should own:

* permanent exterior walls;
* cliff edges;
* inaccessible artwork masses;
* the broad walkable silhouette;
* permanent route boundaries.

Keep separate gameplay blockers only for:

* closed Main Gate;
* closed Great Hall door;
* blocking props that genuinely need collision;
* encounter barriers;
* temporary state-dependent obstructions.

Do not retain duplicate static rectangular wall blockers beneath a mapped rail. Duplicate collision would recreate invisible-wall problems.

Do not allow the underlay PNG’s alpha to generate collision automatically. The manually mapped segments are the reviewed source of truth.

## 7. Use mapper markers for production placement

Load the canonical marker data in `SunderedKeepMap`.

Initial mappings:

```text
spawn              → EntrySpawn
return_causeway    → Exit_Backtrack / return interaction
gatehouse_key      → Sundered Gate Key pickup
main_gate          → Main Gate mechanism
level_exit         → approved forward progression exit
enemy_spawn_west   → west encounter spawn
enemy_spawn_gate   → gate encounter spawn
```

Where the existing JSON and mapper marker disagree, log the discrepancy and prefer the mapper marker after visual review.

Do not preserve the mapper’s labels or marker diamonds in normal gameplay.

## 8. Do not inherit Return Causeway mechanics

Do not add any of the following to the large underlay map:

```text
IMPRINT CUSTODIAN IDENTITY
Buried Terminal unlock requirement
Return Causeway procedural elevation map
procedural gatehouse layout
procedural shore detour
Return Causeway entry title
```

The correct large map already has its own:

* Sundered Gate Key;
* Main Gate;
* Great Hall;
* Return Mooring;
* encounter and siege state;
* large authored artwork.

## 9. Validation

Update:

```text
custodian/tools/validation/
sundered_keep_underlay_collision_mapper_smoke.gd
```

Require that both the debug scene and production map load the same canonical JSON.

Add production assertions:

```text
SunderedKeepMap/MappedUnderlayBounds exists
UnderlayBoundaryCollision exists
production segment count equals JSON segment count
every segment contains boundary_a and boundary_b metadata
underlay texture is sundered_keep_main_overlay.png
map dimensions are 112×80
EntrySpawn matches the canonical spawn marker
Main Gate matches the canonical main_gate marker
production route enters front_gate, never return_causeway
backtracking returns to Vista Approach
```

Add a collision parity check comparing every debug collision shape against the production shape:

```text
same position
same rotation
same radius
same capsule height
same boundary endpoints
```

## Documentation drift

Update:

```text
design/05_levels/SUNDERED_KEEP_LARGE_FRONT_GATE.md
```

It currently says the mapper rails are debug-only and have not been promoted.

After implementation, it should state:

> `sundered_keep_underlay_collision.json` is the canonical static-boundary source shared by the mapper, debug review scene, and production SunderedKeepMap.

So the final route is:

```text
Vista Approach
→ large underlay-backed Sundered Keep
→ Main Gate / internal Keep progression
```

not:

```text
Vista Approach
→ unfinished procedural Return Causeway
→ large Keep
```
