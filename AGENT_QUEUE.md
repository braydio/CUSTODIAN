# CODEX (Or AI Agent Assistant):

    Review the following analysis and expected blockers to the current procedurally generated map. Implement fixes per below and determine actual runtime issues to fix or improve.

# ANALYSIS START

The wall you are describing is the **sealed outer boundary of the generated map**. It is supposed to have no openings. The camera clamp is calculated from the same procgen map dimensions, so both the camera and the wall define the finite playable contract area.

That means **anything positioned beyond that wall is permanently unreachable**. You should not add a hole to the perimeter; you should move misplaced world content inside it.

### Which objects should be inside

The dynamically generated resources are selected from actual procgen `floor_cells`, checked for walkability, and filtered against compound, road, parking, and excluded-region tiles. Those should always be inside the outer boundary.

The loader also explicitly places:

- Operator
- spawn nodes
- command terminal
- vehicles
- existing item anchors
- tutorial resource nodes
- expedition resource nodes
- relays
- registered level ingresses

using generated map data.

### Which objects are probably outside

The suspicious ones are the scene-authored world objects that are **not included in that placement sequence**, especially:

```text
World/AmbientHostileCampEast
World/AmbientHostileCampWest
World/FieldFabricatorMk1
```

I do not see `ContractWorldLoader` assigning generated tiles to the camps or Field Fabricator. Unless another script moves them—which the live paths do not indicate—they retain their old `game.tscn` coordinates while the newly generated map uses its own tile-derived world coordinates.

So yes: **those legacy nodes can be sitting outside the completely sealed procgen perimeter**.

The camps compound the problem because they do not spawn enemies until the Operator comes within `1200px` of their anchor. An off-map camp will therefore exist silently and never activate.

### The sectors are a different case

The old ARCHIVE/POWER/DEFENSE/STORAGE sector nodes are positioned using generated compound-building rectangles, but their legacy floors, walls, and collision shells are then intentionally hidden or disabled. They may exist as state/compatibility nodes without appearing as actual buildings.

So the current outcomes are likely:

| Content                    | Current result                              |
| -------------------------- | ------------------------------------------- |
| Generated resources        | Inside outer wall                           |
| Terminal                   | Inside compound                             |
| Vehicles                   | Inside compound/parking                     |
| Registered level ingresses | Inside generated map                        |
| Ambient camps              | Likely retaining obsolete off-map positions |
| Field Fabricator           | Likely retaining obsolete off-map position  |
| Legacy sector structures   | Positioned, then visually suppressed        |

## Correct fix

Keep the outer perimeter sealed. Add contract-relative placement for the missing world population.

In:

```text
custodian/game/systems/core/systems/contract_world_loader.gd
```

add:

```gdscript
_position_ambient_enemy_camps(level_data, map_instance)
_position_field_fabricator(level_data, map_instance)
```

The camp placement contract should require:

```text
valid walkable floor cell
inside map bounds with a 3–5 tile perimeter inset
outside compound_rect
reachable from the Operator spawn
not on roads, parking zones, ingress footprints, ramps, holes, or cliffs
35–70 tiles from spawn
at least 24 tiles between camps
```

The Field Fabricator should use:

```text
compound interior or parking-zone walkable tile
at least 5 tiles from Operator spawn
at least 3 tiles from CommandTerminal
reachable without crossing walls
```

Add one validation smoke that checks every gameplay-relevant direct `World` node:

```text
is inside the map rectangle
is inside the sealed perimeter
occupies a walkable or explicitly valid structure tile
is reachable from player_spawn where applicable
reports its selected tile and world position
```

Suggested path:

```text
custodian/tools/validation/contract_world_population_placement_smoke.gd
```

So your interpretation is correct: **the sealed perimeter is not trapping properly placed generated content; it is exposing that some legacy world objects were never migrated into the procgen placement contract.**
