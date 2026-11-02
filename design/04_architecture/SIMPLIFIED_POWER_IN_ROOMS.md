# SIMPLIFIED POWER IN ROOMS — Implementation Spec

**Status:** superseded-reference
**Replaces:** Full Compound Tile System (for power delivery only — Phase 1)
**See also:** `COMPOUND_TILE_SYSTEM.md` — Full Phase 2+ target architecture
**Last Updated:** 2026-07-20
**Superseded By:** `design/02_features/infrastructure/COMPOUND_INFRASTRUCTURE_SYSTEM.md`

---

## Overview

> This proposal is retained as historical room-marker research. Do not implement its `power_conduit → PowerNode generator` mapping. A conduit, relay, consumer socket, and generator socket are distinct semantics; the active Compound Infrastructure design uses explicit component registration and reserves authored room markers for typed connection/placement authority.

This spec describes a bounded implementation to add power delivery to procedurally-generated rooms without the overhead of a full compound tile system.

**Design Doctrine:** Reuse existing patterns from room assembly → minimal new code.

---

## Current State (What Exists)

### Room Assembly Pipeline
```
RoomLoader.load_templates_from_directory(dir)
    ↓
LayoutAssembler.generate_layout(seed)
    ↓
Returns: { rooms: [...], connections: [...], markers: [...] }
```

The layout assembler already collects markers and offsets them to world coordinates:
- `turret_mounts` → array of Vector2i
- `enemy_spawns` → array of Vector2i
- `terminal_marker` → single Vector2i (or null)
- `player_spawn` → single Vector2i (or null)

### Power System (Existing)
The `power.gd` system already:
- Finds all nodes in "power_node" group
- Calls `get_power_output()` on each
- Distributes power to sectors by priority

**What's missing:** Power nodes in procgen rooms

---

## Implementation Scope

### What We Need

1. **Marker definition:** Add `power_conduit` marker to room templates
2. **Collection:** Layout assembler already collects markers — just add collection
3. **Spawn:** When placing room, spawn PowerNode actor at marker position
4. **Registration:** Add spawned PowerNodes to "power_node" group for auto-discovery

### What's NOT in Scope (for now)

- Per-tile HP/damage
- Tile registry
- Power routing graph
- Structural damage system (use sector damage instead)

---

## Implementation

### Step 1: Room Template Changes

Add Tiled marker object to room `.tmj` templates:

```json
{
  "name": "power_conduit",
  "type": "power_conduit",
  "x": 192,
  "y": 320,
  "width": 32,
  "height": 32
}
```

Properties (optional):
- `power_output`: float (default: 120.0)
- `conduit_group_id`: string (for routing if needed later)

### Step 2: Room Loader Changes

In `room_loader.gd`, add marker collection (line ~97):

```gdscript
"turret_mounts": _collect_marker_tiles(markers, "turret_mount"),
"power_conduits": _collect_marker_tiles(markers, "power_conduit"),  # ADD
```

### Step 3: Layout Assembler Changes

In `layout_assembler.gd`, offset markers to world (line ~58):

```gdscript
"turret_mounts": _offset_tiles(template.get("turret_mounts", []), world_position),
"power_conduits": _offset_tiles(template.get("power_conduits", []), world_position),  # ADD
```

### Step 4: Room Placement (Where Rooms are Instantiated)

This depends on where rooms are placed in the world. Need to find the call site.

When spawning a room into the world:
1. Iterate `layout.rooms[i].power_conduits`
2. For each conduit position:
   - Spawn `PowerNode.tscn` at (marker.x * 32, marker.y * 32)
   - Add to "power_node" group

### Step 5: Verify Integration

Power system already auto-discovers nodes in "power_node" group:

```gdscript
# In power.gd line 134:
for node in get_tree().get_nodes_in_group("power_node"):
    total += float(node.get_power_output())
```

**No power.gd changes needed.**

---

## Files to Modify

| File | Change |
|------|--------|
| `custodian/game/world/compound/rooms/room_loader.gd` | Add `power_conduits` collection |
| `custodian/game/world/compound/rooms/layout_assembler.gd` | Add `power_conduits` offset |
| `custodian/game/world/compound/rooms/room_graph.gd` | (no change) |
| Room placement code | Iterate room layout, spawn PowerNodes at marker positions |
| Existing `.tmj` templates | Add power_conduit marker objects |

---

## Testing Checklist

- [ ] PowerNode actor exists (`game/actors/sector/power_node.gd` - extends Sector)
- [ ] RoomLoader collects power_conduit markers
- [ ] LayoutAssembler offsets markers to world coordinates
- [ ] Room spawn code creates PowerNode at each conduit position
- [ ] PowerNodes appear in "power_node" group
- [ ] Power.gd sees new nodes in `get_nodes_in_group("power_node")`
- [ ] Power system distributes to new power nodes

## Notes

- PowerNode is defined as `game/actors/sector/power_node.gd` (script class), extends Sector
- Can be instantiated via `sector.tscn` with script override, or by creating a dedicated `.tscn` scene
- Existing code automatically adds to "power_node" group in `_ready()` (line 17-18)

---

## Future Expansion (Not in Scope)

If more complex power routing is needed later:

1. Add `conduit_group_id` to markers
2. Build adjacency from room connections
3. Use Dijkstra's algorithm for pathfinding
4. Add failure states when conduit is destroyed

For now: Direct connection to global power pool — no routing.

---

## Reference

- Existing markers pattern: `turret_mount` → `turret_mounts[]`
- Power system auto-discovery: `get_tree().get_nodes_in_group("power_node")`
- Room offset formula: `world_pos + (tile * TILE_SIZE)` where TILE_SIZE = 32
