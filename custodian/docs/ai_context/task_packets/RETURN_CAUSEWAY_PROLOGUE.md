# Return Causeway Prologue Level

## Packet Status
- Status: in_progress
- Owner: agent
- Created: 2026-06-10
- Last updated: 2026-06-10

## Task
Implement the Return Causeway prologue level — the player's arrival approach to Sundered Keep — as an authored Godot 4 vertical slice. This level replaces the old "drop into the keep" start with a controlled, cinematic arrival sequence that establishes tone, introduces the Custodian identity, and ends at the existing Sundered Keep front gate entrance.

## Layout Overview
- Footprint: ~96×72 tiles (32×32 px each)
- Orientation: south→north approach (player arrives from south, progresses north toward the keep)
- Terrain: ocean/void surrounds all sides; cliff island with narrow causeway; shore path below

## Route Flow

```
North (y=5)  [→ Transition to Sundered Keep Main Map]
                  ↑
              [Outer Keep Yard]      ~y=8-18
                  ↑   locked gatehouse portcullis
              [Gatehouse Threshold]  ~y=18-30
                  ↑
              [Intact Causeway]      ~y=30-42
                  ↑   broken bridge gap
              [Broken Causeway]      ~y=42-50   ←→  [Shore Path (east)]  ~y=42-50
                  ↑                                          ↑
              [Return Mooring]       ~y=50-60          [Buried Terminal]
                  ↑                                          ↑
              [Arrival Beach]        ~y=60-68          [Shore Access]
                  ↑
South (y=72) [Ocean / Void]
```

### Main Route (Linear)
1. **Arrival Beach** — player materializes / enters from south edge. Small rocky beach, broken mooring post, sea spray.
2. **Return Mooring** — active Custodian return beacon (functional). Brief UI prompt establishes the beacon network.
3. **Broken Causeway** — the main paved causeway is collapsed here. A debris-choked gap blocks direct passage. The player must look for an alternate path.
4. **Intact Causeway** — reached via shore path detour. Walled passage flanked by ocean on both sides. Brazier flickers. Waves crash below.
5. **Gatehouse Threshold** — fortified gatehouse with raised portcullis. Locked. A Custodian-state panel beside the gate reads: "IDENTITY NOT ESTABLISHED — BURIED TERMINAL REQUIRED."
6. **Outer Keep Yard** — small walled yard before the actual keep entrance. Transition point to main Sundered Keep map.

### Optional Route (Buried Terminal)
1. **Shore Access** — branching east from the broken causeway gap. Wet rocks, tidal pools.
2. **Shore Path** — series of rocky ledges at height 0 hugging the cliff base. Exposed to ocean spray.
3. **Buried Terminal** — semi-collapsed structure half-buried in the cliff face. Inside: an austere Custodian interface terminal. Activating it:
   - Plays the first "Custodian identity imprint" sequence
   - Unlocks the gatehouse portcullis
   - Triggers a UI message: "CUSTODIAN IDENTITY ESTABLISHED — GATEHOUSE UNLOCKED"

## Sector Specifications

### Sector 1: Arrival Beach (y=60-68, x=36-54)
- **Elevation**: height 0, walkable
- **Tiles**: `ocean_void_01` surround, beach is `cliff_rock_floor_01` / `cliff_rock_floor_cracked_01` mix
- **Props**: broken mooring post, crate driftwood, sea spray rocks
- **Blockers**: ocean boundaries, cliff edges to north and east
- **Spawn point**: center of beach (x=45, y=64)

### Sector 2: Return Mooring (y=52-60, x=38-52)
- **Elevation**: height 0 (beach level), walkable
- **Tiles**: `main_gate_threshold_stone_01` for mooring pad, causeway floors for path
- **Props**: `return_mooring_floor_*` 3x3 ring, `prop_return_beacon_01`, `prop_return_console_ruined_01`
- **Interaction**: "ACTIVATE RETURN MOORING" — functions as checkpoint save

### Sector 3: Broken Causeway (y=42-52, x=38-50)
- **Elevation**: height 2 (causeway deck), walkable on bridge; height 0 under bridge
- **Tiles**: `entrance_causeway_floor_01` / `entrance_causeway_floor_cracked_01` on deck
- **Gap**: 3-tile gap at (42, 44) to (44, 44) — `entrance_causeway_broken_gap_01` with blockers
- **Edge**: handrail/parapet edges N/S/E/W on walkable tiles
- **Underbridge**: shore path at height 0 underneath the deck

### Sector 4: Shore Path (y=40-52, x=50-72)
- **Elevation**: height 0, walkable (rocky ledge at cliff base)
- **Tiles**: `cliff_rock_floor_cracked_01` 
- **Blockers**: ocean to east and south, cliff face to north
- **Props**: sea spray rocks, tidal pool decor, wet sand

### Sector 5: Buried Terminal (x=62-70, y=40-48)
- **Elevation**: height 0, walkable (interior floor)
- **Structure**: half-buried masonry structure at base of cliff
- **Tiles**: floor = `great_hall_marble_floor_01` (surprise material shift indoors)
- **Props**: `prop_return_console_ruined_01` repurposed as the terminal (or a dedicated terminal prop)
- **Interaction**: "IMPRINT CUSTODIAN IDENTITY" — unlocks gatehouse, plays identity sequence
- **Effect**: overlay glow activates on terminal after imprint

### Sector 6: Intact Causeway (y=30-42, x=38-50)
- **Elevation**: height 2, walkable (except edges which are ledge/drop)
- **Tiles**: `entrance_causeway_floor_01` + cracked variants, full edge railing
- **Walls**: `causeway_keep_parapet_straight_long_01` on both sides (facing E and W)
- **Props**: `causeway_lit_brazier_bowl_01` every 4 tiles, chain anchors
- **Lighting**: brazier flicker sprites, ocean edge foam

### Sector 7: Gatehouse Threshold (y=20-30, x=34-54)
- **Elevation**: height 2 (approaching gate), height 3 (gatehouse interior)
- **Floor**: `main_gate_threshold_stone_01` at threshold, shifts to `cobblestone_floor_01` inside
- **Gate**: locked portcullis prefab at y=22
- **Walls**: `gothic_castle_wall_straight_*` forming gatehouse walls
- **Panel**: Custodian-state panel beside gate, non-interactable until unlocked
- **Props**: torches, chains, fallen masonry

### Sector 8: Outer Keep Yard (y=8-18, x=36-54)
- **Elevation**: height 2, walkable
- **Tiles**: `main_courtyard_flagstone_01`
- **Props**: broken statue, low garden wall, crate stack
- **Blockers**: keep wall to north (transition point only)
- **Transition**: travel gate at y=10 to Sundered Keep main map

### Ocean / Void (all sectors surrounding)
- **Tiles**: `ocean_dark_water_01` scattered
- **Blockers**: Rect2i blockers at all ocean edges

## Separation Layers
1. **Layout Truth** — tile IDs and positions (what is placed)
2. **Elevation Truth** — `ElevationMap` cell data (height, traversal, direction)
3. **Presentation Truth** — sprite ordering, z-indices, depth sort, roof occlusion
4. **Gameplay Truth** — blockers, interactables, objectives, spawns, transitions

## Elevation Map

| Region | Height | Traversal | Notes |
|--------|--------|-----------|-------|
| Beach / Shore Path | 0 | walkable | rocky beach at sea level |
| Return Mooring | 0 | walkable | level with beach |
| Underbridge path | 0 | walkable | shore path under causeway |
| Causeway Deck | 2 | walkable | main causeway surface |
| Shore stairs up | 1→2 | stair | transition from shore to causeway |
| Gatehouse | 3 | walkable | raised gatehouse floor |
| Outer Keep Yard | 2 | walkable | courtyard level |
| Causeway edges | 2 | ledge | drop-off into ocean |
| Buried Terminal | 0 | walkable | at sea level |

## Interactables

| Name | Kind | Function |
|------|------|----------|
| Return Mooring Beacon | `return_mooring` | Checkpoint save, beacon glow toggle |
| Buried Terminal | `buried_terminal` | Establishes Custodian identity, unlocks gate |
| Gatehouse Gate | `gatehouse_gate` | Opens when unlocked (blocker removed) |
| Transition to Keep | `travel_gate` | Exits to Sundered Keep main map |

## Assets Used
All from existing Sundered Keep content paths:
- `res://content/tiles/sundered_keep/entrance/` — causeway floors, edges, broken gaps
- `res://content/tiles/sundered_keep/entrance/causeway_walls/` — parapets, wall faces
- `res://content/tiles/sundered_keep/entrance/props/` — braziers, chains
- `res://content/tiles/sundered_keep/floors/` — stone, cobblestone, flagstone
- `res://content/tiles/sundered_keep/entrance/cliffs/` — cliff rock
- `res://content/runtime/sundered_keep/props/` — return mooring props
- `res://content/tiles/sundered_keep/return_mooring/` — mooring floor tiles
- `res://content/audio/music/return_causeway/return_causeway_01.ogg` — music track

## Acceptance Criteria
- [ ] Player spawns on arrival beach at correct position
- [ ] Return mooring beacon is interactable and saves checkpoint
- [ ] Broken causeway gap blocks direct north passage
- [ ] Shore path is accessible from beach
- [ ] Buried Terminal is reachable via shore path
- [ ] Activating Buried Terminal unlocks gatehouse gate
- [ ] Gatehouse gate opens (animation/blocker removal)
- [ ] Player can reach Outer Keep Yard and transition to main map
- [ ] All tile assets load without missing texture warnings
- [ ] Elevation data is correct for all walkable/safe/blocked cells
- [ ] Music plays on arrival
- [ ] No hardcoded secrets, no lint errors
