# Edgar.Godot Room Template System

**Project:** CUSTODIAN
**Status:** Implementation
**Created:** 2026-03-24
**Depends On:** Edgar.Godot or Edgar.GDExtension

---

## Overview

Augment the existing procedural map generation with handcrafted Tiled room templates. This provides:
- Designer-controlled room layouts
- Guaranteed connectivity via door matching
- More interesting/intentional level design
- Hybrid generation: some rooms ProcGen, some Edgar-selected

## Architecture

```
custodian/
├── procgen/
│   ├── proc_gen_tilemap.gd      # Existing ProcGen (keep)
│   ├── custodian_contract_map.gd # Existing contract (keep)
│   └── edgar/
│       ├── room_loader.gd       # NEW: Loads Tiled rooms
│       ├── room_graph.gd        # NEW: Room connectivity rules
│       └── layout_assembler.gd  # NEW: Stitches rooms into world
└── rooms/                       # NEW: Tiled room templates
    ├── templates/
    │   ├── command_post.tmj
    │   ├── hangar_large.tmj
    │   ├── hangar_small.tmj
    │   ├── corridor_h.tmj
    │   ├── corridor_v.tmj
    │   ├── storage.tmj
    │   └── landing_pad.tmj
    └── graphs/
        └── default_graph.edgar-graph
```

## Room Template Specification

### Door Properties (Tiled Custom Properties)

Each room template defines doors as custom properties:

| Property | Type | Example |
|----------|------|---------|
| `doors_north` | string | `[{"x": 8, "width": 4}]` |
| `doors_south` | string | `[{"x": 8, "width": 4}]` |
| `doors_east` | string | `[{"y": 6, "height": 3}]` |
| `doors_west` | string | `[{"y": 6, "height": 3}]` |
| `room_type` | string | `command_post`, `hangar`, `corridor` |
| `min_players` | int | 1 |
| `max_players` | int | 4 |

### Room Dimensions

- Base tile size: 32x32
- Standard rooms: 10x10 to 20x15 tiles
- Corridors: 4-6 tiles wide

## Room Graph Definition

JSON-based graph defining room connectivity:

```json
{
  "graph_name": "default_compound",
  "rooms": {
    "command_post": {
      "templates": ["command_post"],
      "required": true,
      "min_count": 1,
      "max_count": 1,
      "default_spawn": true
    },
    "hangar": {
      "templates": ["hangar_large", "hangar_small"],
      "required": false,
      "min_count": 2,
      "max_count": 4
    },
    "corridor": {
      "templates": ["corridor_h", "corridor_v"],
      "required": false,
      "min_count": 3,
      "max_count": 8
    },
    "storage": {
      "templates": ["storage"],
      "required": false,
      "min_count": 1,
      "max_count": 2
    },
    "landing_pad": {
      "templates": ["landing_pad"],
      "required": false,
      "min_count": 1,
      "max_count": 2
    }
  },
  "connections": [
    {"from": "command_post", "to": "hangar", "direction": "any"},
    {"from": "command_post", "to": "corridor", "direction": "any"},
    {"from": "hangar", "to": "corridor", "direction": "any"},
    {"from": "corridor", "to": "storage", "direction": "any"},
    {"from": "corridor", "to": "landing_pad", "direction": "any"}
  ],
  "seed_overrides": {}
}
```

## Integration with CustodianContractMap

### Mode Selection

```gdscript
enum MapGenerationMode {
    PROCGEN_ONLY,    # Existing algorithm
    EDGAR_ONLY,     # Room templates only
    HYBRID          # Mix of both
}

@export var generation_mode: MapGenerationMode = MapGenerationMode.HYBRID
@export var edgar_weight: float = 0.5  # 50% Edgar rooms in hybrid
```

### Generation Flow

1. Load room templates from `rooms/templates/`
2. Load room graph from `rooms/graphs/`
3. If Edgar mode: run Edgar layout generation
4. If Hybrid mode: split rooms 50/50 between ProcGen and Edgar
5. Apply room positions to world
6. Run existing entity placement (spawn nodes, terminal, etc.)

## Room Instance Placement

Rooms are placed on a grid with 1-tile spacing:

```
Room A (20x15)     [spacing]     Room B (15x10)
                                   |
         +---------------------+   |
         |                     |---+
         |                     |   
         +---------------------+   
```

### Coordinate Mapping

```gdscript
func _place_room(room_data: Dictionary, grid_pos: Vector2i) -> void:
    var room_offset := Vector2(grid_pos) * TILE_SIZE
    var room_instance = room_data.template.instantiate()
    room_instance.position = room_offset
    world_root.add_child(room_instance)
```

## Door Connection Logic

Doors must match when connecting rooms:

1. North door of Room A connects to South door of Room B
2. Door widths must be compatible (±1 tile tolerance)
3. If no door exists, wall is sealed

```gdscript
func _can_connect(door_a: Dictionary, door_b: Dictionary) -> bool:
    var width_a = door_a.get("width", 1)
    var width_b = door_b.get("width", 1)
    return abs(width_a - width_b) <= 1
```

## Entity Placement Within Rooms

After room placement, existing systems place entities:

| Entity | Placement Logic |
|--------|-----------------|
| Operator | Default spawn point in command_post |
| Spawn Nodes | Per-room spawn_data or evenly distributed |
| Terminal | command_post room only |
| Turrets | Per-room turret_anchors layer |
| Loot | Per-room loot_spawn points |

## Seed & Determinism

- Master seed from contract
- Edgar uses seed for room selection + door assignment
- Layout is fully deterministic given same seed

## Error Handling

- If room graph is unsatisfiable: fallback to ProcGen-only
- If template is missing: skip and log warning
- If door mismatch: seal with wall tiles

## Future Enhancements

- Room templates with multiple variations (rotate, flip)
- Room-specific enemy spawn tables
- Dynamic room unlocking based on gameplay
- Room themes (damaged, abandoned, pristine)

---

## Implementation Tasks

- [ ] Install Edgar.Godot or Edgar.GDExtension
- [ ] Create `custodian/rooms/templates/` directory
- [ ] Create sample room templates in Tiled
- [ ] Create room graph JSON
- [ ] Implement room_loader.gd
- [ ] Implement layout_assembler.gd
- [ ] Add mode selection to CustodianContractMap
- [ ] Wire hybrid generation flow
