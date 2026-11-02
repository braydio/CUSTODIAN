The front approach currently reads like a debug runway plus a flat gate strip. Codex should rebuild it as a **storm-battered causeway → outer barbican → item-gated portcullis → courtyard reveal**. Since this is active Godot runtime work, keep it under `custodian/` and update the active docs/AI context if the runtime layout changes.

You are working in `/home/braydenchaffee/Projects/CUSTODIAN`.

Implement a cleaner, more interesting Sundered Keep front entrance and causeway.

Primary file to inspect first:

- `custodian/game/world/sundered_keep/sundered_keep_map.gd`

Relevant content roots:

- `custodian/content/runtime/sundered_keep/`
- `custodian/content/tiles/sundered_keep/`
- `custodian/content/props/sundered_keep/`
- `custodian/content/tiles/sundered_keep/return_mooring/`
- `custodian/content/props/sundered_keep/return_mooring/`

Current problem:
The lower/front part of the Sundered Keep map visually reads as a flat debug runway. The player stands below a wide gray strip, the causeway is too plain, the front gate is not visually clean, and the entrance does not feel like a storm-battered gothic ocean keep. Rework this area into a proper playable entrance sequence.

High-level goal:
Create a strong first-read level entrance:
`ocean void / storm water → broken stone causeway → outer landing → gatehouse/barbican → item-gated main portcullis → courtyard`

Do not add new gameplay systems unless necessary. Reuse existing Sundered Keep assets first.

Required visual changes:

1. Remove the flat gray-looking entrance apron / runway feel.
2. Replace the straight plain bridge with an irregular broken stone causeway.
3. Add visible ocean/void on both sides of the causeway.
4. Add cliff/foam/rock transition tiles so the bridge does not float in empty black.
5. Add a proper gatehouse silhouette:
   - left gatehouse tower/mass
   - right gatehouse tower/mass
   - central portcullis threshold
   - short side walls/parapets
   - torches or beacon props if available

6. Make the front gate narrower and more readable as a choke point.
7. Keep the player spawn outside the gate on the approach, not inside the courtyard.
8. Keep the return mooring reachable before or near the gate.
9. Keep the Sundered Gate Key / winch area reachable before the closed portcullis.
10. Do not use giant world text like `OPEN MAIN GATE (G)` as permanent map decoration. Interaction text should come from HUD/prompt logic only.

Suggested entrance structure:

```text
                  COURTYARD
        wall wall PORTCULLIS wall wall
        tower       gate       tower
        tower    threshold     tower
             outer gate landing
          broken stone causeway
              narrow bridge
          broken stone causeway
                player spawn
```

Tile-space design target:
If keeping the current map size, rebuild the lower/front sector roughly around these anchors:

- Player spawn / entrance start: bottom center, about `(32, 43)` or current equivalent.
- Causeway width: mostly 3 tiles wide, widening to 5 tiles near the gate.
- Causeway length: 8–12 tiles from spawn to gate landing.
- Outer landing: about 9×5 tiles.
- Gatehouse total width: about 17–21 tiles.
- Central portcullis gap: 3–4 tiles wide.
- Left/right towers: each around 5×6 or 6×7 tiles.
- Return mooring alcove: one side of gatehouse, not on the center path.
- Key/winch alcove: opposite side of gatehouse or tucked into one tower.

Specific layout beats:

1. Spawn Beat
   - Player begins on a small broken approach platform.
   - Platform should be safe and readable.
   - Use stone/causeway floor, not generic gray fill.
   - Ocean/void should be visible around it.

2. Causeway Beat
   - Causeway should be irregular, not rectangular.
   - Make it mostly 3 tiles wide.
   - Add broken side chunks, missing corners, cracked floor variants.
   - Use debris props sparingly.
   - Add at least two small side bulges/landings so it does not look like a hallway.

3. Outer Landing Beat
   - Widen the path before the gate.
   - Add low cover, broken carts/crates, fallen masonry.
   - This can be a small pre-gate combat pocket.
   - Keep the direct line to the portcullis obvious.

4. Gatehouse Beat
   - Build a real gatehouse facade.
   - Left and right masses should frame the portcullis.
   - Use walls/parapets/towers to create an architectural silhouette.
   - The portcullis should sit exactly in the center.
   - Closed gate must visually and physically block movement.
   - Open gate must visibly clear the path and remove collision.

5. Side Alcove: Return Mooring
   - Place the return mooring in a small side alcove before the locked gate.
   - Use the 3×3 mooring floor layout:
     `NW N NE / W C E / SW S SE`
   - Add beacon and/or ruined console.
   - It should look like a safe Custodian recall point, not a debug exit.
   - The center tile is the interaction target.

6. Side Alcove: Key / Winch
   - Add a separate winch/key alcove before the closed portcullis.
   - Player should be able to acquire `sundered_gate_key` or operate the winch/key object before opening the gate.
   - Use `prop_gate_winch_01` if available.
   - If no key art exists, use a small interactable marker or winch prop and keep the temporary key state local.

7. Courtyard Reveal
   - After gate opens, the player should enter the courtyard through a clear choke.
   - Avoid dumping the player immediately into a huge empty rectangle.
   - Add a short threshold corridor or two-tile vestibule after the gate.

Implementation requirements:

- Keep existing map build deterministic.
- Prefer helper functions over more ad hoc placement inside one giant build method.
- Add or refactor helpers such as:
  - `_build_front_causeway() -> void`
  - `_build_gatehouse_front() -> void`
  - `_build_outer_gate_landing() -> void`
  - `_build_gatehouse_side_alcoves() -> void`
  - `_build_return_mooring(origin_tile: Vector2i) -> void`
  - `_build_gate_key_or_winch(tile: Vector2i) -> void`
  - `_set_main_gate_open(open: bool) -> void`
  - `_clear_main_gate_blockers() -> void`
  - `_add_main_gate_blockers() -> void`

Gate behavior requirements:

- Main gate starts closed.
- Closed gate blocks movement.
- Player without key sees a HUD/interact prompt saying it requires `Sundered Gate Key`.
- Player can acquire the key or activate a key/winch object before the gate.
- Player with key can open the gate.
- Opening gate swaps closed/open portcullis visuals and removes collision blockers.
- The gate must stay open after opening during the current map session.

Collision requirements:

- The causeway edges should be clear fall/ocean hazards.
- Do not create invisible blockers on the causeway.
- Do not allow walking off the bridge unless that is already handled as a fall/ocean hazard.
- Closed portcullis blockers should cover the exact threshold.
- Return mooring floor must be walkable.
- Beacon/console may block if they visually occupy space.
- Gatehouse walls/towers should block movement.

Visual hierarchy rules:

- Causeway floor: readable but broken.
- Ocean/void: dark, clearly non-walkable.
- Foam/cliff edge: transition between stone and ocean.
- Gatehouse: strongest visual silhouette in the lower map.
- Portcullis: central interactable gate.
- Return mooring: cyan Custodian-tech accent, visually different from stone.
- Key/winch alcove: smaller but readable objective.

Do not:

- Do not leave giant permanent white text over the gate.
- Do not use one large rectangular gray platform.
- Do not make the causeway wider than the gatehouse.
- Do not surround the causeway with random isolated square water tiles.
- Do not add new art dependencies unless existing assets are insufficient.
- Do not break the existing return-to-main-map behavior.
- Do not modify legacy Python runtime.

Optional but recommended:
Add a debug/build summary print after map construction:

- floors placed
- walls placed
- props placed
- blockers placed
- interactables placed
- main gate open/closed
- gate key pickup created
- return mooring created

Validation:
Run:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian
godot --headless --script res://tools/validation/sundered_keep_asset_smoke.gd
```

Also manually check in-game:

- Player spawns on the exterior approach.
- Causeway looks broken, narrow, and storm-battered.
- Ocean/void frames the causeway cleanly.
- Gatehouse looks like a proper front gate.
- Main gate starts closed.
- Player cannot pass through the closed gate.
- Player can reach return mooring before the gate.
- Player can reach key/winch before the gate.
- Player can open the gate after acquiring/activating the required item.
- Gate collision is removed after opening.
- Courtyard route is readable after gate opens.

Docs:
If this changes runtime layout/behavior, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `custodian/docs/ai_context/CONTEXT.md`

Mention:

- Sundered Keep front approach was rebuilt as a storm causeway and gatehouse entrance.
- Main gate is item-gated/openable.
- Return Mooring and key/winch are reachable before the gate.
- Front entrance now uses a proper causeway/barbican layout instead of a flat debug runway.

After Codex does this, the screenshot should read as **a dangerous bridge into a fortress**, not a broad gray staging platform.

ADDENDUM:

Got the repomix. You do **not** need another command yet. Based on the uploaded context, Codex should treat the current Sundered Keep as **already partially implemented**, not greenfield: it already has `sundered_keep_map.gd`, `SunderedKeepInteractable`, a local `sundered_gate_key`, openable main gate, Great Hall door, Return Mooring, and smoke coverage. The current map is still authored/hard-coded at `80×56`, so the next task is specifically to **convert/extend this into a larger data-driven layout**, not redo the whole system from scratch.

The available asset context is good too: entrance/gatehouse assets now exist, including causeway floor/cracked floor, broken gap, gatehouse floors, portcullis shadow, and gatehouse broken wall modules. The Return Mooring module is also already formalized as a `5×5` footprint with a `3×3` floor layout and center interaction tile.

Use this Codex prompt:

You are working in `/home/braydenchaffee/Projects/CUSTODIAN`.

Implement the next Sundered Keep pass: convert the current authored Sundered Keep front-gate section into a larger, data-driven tilemap-driven layout.

Current state from repo context:

- `custodian/game/world/sundered_keep/sundered_keep_map.gd` already exists.
- It is currently a connected Godot destination map.
- It currently uses `MAP_SIZE_TILES := Vector2i(80, 56)`.
- It already has local `sundered_gate_key` support.
- It already has Return Mooring behavior.
- It already has an openable/collision-gated Main Gate.
- It already has an openable Great Hall door.
- It already has `SunderedKeepInteractable`.
- It already has `sundered_keep_layout_smoke.gd` validating mooring, key pickup, closed-gate blocker, blocked no-key gate interaction, Great Hall door blocker, and blocker removal after gate/door opening.
- It already has entrance/gatehouse assets and Return Mooring assets.

Do not reimplement those features from scratch. Preserve and migrate them.

Primary goal:
Replace the current 80×56 hard-coded layout with a larger, data-driven Sundered Keep front-gate level definition that builds:

`storm ocean → broken approach platform → long irregular causeway → outer landing → barbican/gatehouse → item-gated main portcullis → vestibule → irregular courtyard → Great Hall approach / rampart branches`

Target map size:
Preferred:

```gdscript
Vector2i(112, 80)
```

Fallback only if needed:

```gdscript
Vector2i(96, 72)
```

The larger size must come from level data, not a hard-coded constant inside `sundered_keep_map.gd`.

Core implementation direction:
Create a data-driven level source file:

```text
custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json
```

Then refactor `sundered_keep_map.gd` so it loads/builds from this JSON instead of directly encoding all geometry in hard-coded methods.

Do not remove working interaction logic. Instead:

- Keep `_handle_sundered_interaction`.
- Keep `_grant_sundered_gate_key`.
- Keep `_try_open_main_gate`.
- Keep `_set_main_gate_open`.
- Keep `_try_open_great_hall_door`.
- Keep `return_to_main`.
- Keep debug state methods if already used by tests.
- Rewire them to data-created nodes/blockers where needed.

Recommended new or refactored files:

```text
custodian/content/levels/sundered_keep/sundered_keep_front_gate_large.json
custodian/game/world/sundered_keep/sundered_keep_tilemap_loader.gd
custodian/tools/validation/sundered_keep_large_layout_smoke.gd
design/20_levels/in_progress/SUNDERED_KEEP_LARGE_FRONT_GATE.md
```

If a generic level/tilemap loader already exists under `custodian/game/world/tilemaps/`, use it. If not, create a small focused loader for Sundered Keep first. Do not overengineer a full editor.

Important existing files to inspect before changing:

```text
custodian/game/world/sundered_keep/sundered_keep_map.gd
custodian/game/world/sundered_keep/sundered_keep_interactable.gd
custodian/tools/validation/sundered_keep_layout_smoke.gd
custodian/content/runtime/sundered_keep/sundered_keep_game32_assets.gd
custodian/content/metadata/game32/sundered_keep_entrance_gatehouse.game32.json
custodian/content/metadata/game32/return_mooring.game32.json
custodian/content/levels/sundered_keep/sundered_keep_assets.json
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/CONTEXT.md
```

Asset notes:
Use these existing entrance/gatehouse assets if they resolve:

```text
entrance_causeway_floor_01
entrance_causeway_floor_cracked_01
entrance_causeway_broken_gap_01
entrance_causeway_edge_n
entrance_causeway_edge_e
entrance_causeway_edge_w
entrance_causeway_shadow_01
main_gate_threshold_wet_01
gatehouse_floor_dark_01
gatehouse_floor_murder_hole_01
main_gate_portcullis_shadow_01
gatehouse_wall_broken_left_01
gatehouse_wall_broken_right_01
```

Before using diagonal or south entrance edge IDs, verify they actually exist. The docs mention diagonal causeway edge overlays, but the included manifest/directory context clearly shows at least `n/e/w`; do not assume `ne/nw/se/sw/s` exists unless the file/catalog confirms it. If missing, use existing cliff/ocean/foam tiles instead.

Return Mooring assets already exist:

```text
return_mooring_floor_center_01
return_mooring_floor_ring_n
return_mooring_floor_ring_e
return_mooring_floor_ring_s
return_mooring_floor_ring_w
return_mooring_floor_corner_ne
return_mooring_floor_corner_nw
return_mooring_floor_corner_se
return_mooring_floor_corner_sw
return_mooring_glow_overlay_01
return_mooring_active_overlay_01
return_mooring_prompt_marker_01
prop_return_beacon_01
prop_return_console_ruined_01
```

Return Mooring module behavior:

- Preserve the current Return Mooring interaction.
- The module footprint is 5×5.
- The actual pad is 3×3.
- The center tile is the interaction target.
- Place it before or beside the locked gate, not on player spawn.
- It must be reachable before the gate opens.

Main Gate behavior:

- Preserve the existing item-gated Main Gate behavior.
- Required item id: `sundered_gate_key`.
- Display name: `Sundered Gate Key`.
- Gate starts closed.
- Gate blocks movement.
- Player without key cannot open gate.
- Player with key can open gate.
- Opening gate swaps closed/open visual and removes the portcullis blocker.
- Gate remains open for the current connected-map session.
- Do not replace the working local inventory fallback unless a better inventory API is already available.

Great Hall door behavior:

- Preserve the existing closed/open Great Hall door and blocker behavior.
- It should remain a later progression gate after courtyard/gatehouse.

Data-driven schema:
Add a compact schema to `sundered_keep_front_gate_large.json`.

Minimum required top-level shape:

```json
{
  "schema": "custodian.sundered_keep.level_tilemap.v1",
  "level_id": "sundered_keep_front_gate_large",
  "display_name": "Sundered Keep - Front Gate",
  "tile_size": 32,
  "map_size_tiles": [112, 80],
  "camera_bounds_tiles": [0, 0, 112, 80],
  "start_tile": [56, 76],
  "return_gate_tile": [42, 58],
  "main_gate_tile": [56, 50],
  "great_hall_door_tile": [56, 30],
  "layers": [
    "TerrainBase",
    "TerrainEdges",
    "FloorDetail",
    "WallsLow",
    "WallsHigh",
    "PropsStatic",
    "PropsBlocking",
    "Traversal",
    "Interactables",
    "Hazards",
    "Overlays",
    "Effects",
    "WorldUI",
    "Collision"
  ],
  "ops": [],
  "interactables": [],
  "blockers": [],
  "markers": []
}
```

Supported operation types:

1. `fill_rect`

```json
{
  "op": "fill_rect",
  "layer": "TerrainBase",
  "asset_id": "ocean_void_01",
  "rect": [0, 0, 112, 80]
}
```

2. `fill_weighted_rect`

```json
{
  "op": "fill_weighted_rect",
  "layer": "TerrainBase",
  "rect": [35, 54, 43, 12],
  "seed": 1701,
  "choices": [
    ["main_courtyard_flagstone_01", 70],
    ["main_courtyard_flagstone_cracked_01", 20],
    ["main_courtyard_flagstone_wet_01", 10]
  ]
}
```

3. `paint_cells`

```json
{
  "op": "paint_cells",
  "layer": "TerrainBase",
  "asset_id": "entrance_causeway_floor_01",
  "cells": [
    [56, 75],
    [56, 74],
    [55, 74],
    [57, 74]
  ]
}
```

4. `stamp_prop`

```json
{
  "op": "stamp_prop",
  "layer": "PropsBlocking",
  "asset_id": "prop_gate_winch_01",
  "tile": [73, 55],
  "anchor": "bottom_center",
  "blocks_movement": true
}
```

5. `stamp_module`

```json
{
  "op": "stamp_module",
  "module_id": "return_mooring_3x3_01",
  "origin": [39, 56]
}
```

6. `stamp_wall`

```json
{
  "op": "stamp_wall",
  "layer": "WallsHigh",
  "asset_id": "gatehouse_wall_broken_left_01",
  "tile": [44, 51],
  "anchor": "bottom_center",
  "blocks_movement": true,
  "footprint": [2, 1]
}
```

7. `blocker_rect`

```json
{
  "id": "main_portcullis_blocker",
  "op": "blocker_rect",
  "rect": [54, 50, 4, 2],
  "enabled_when": "main_gate_closed"
}
```

8. `interactable`

```json
{
  "id": "main_gate_interaction",
  "op": "interactable",
  "kind": "main_gate",
  "tile": [56, 51],
  "prompt": "OPEN MAIN GATE",
  "distance": 96
}
```

9. `marker`

```json
{
  "id": "player_spawn",
  "op": "marker",
  "kind": "spawn",
  "tile": [56, 76]
}
```

Runtime loader requirements:

- Load JSON once during map build.
- Create configured layers if missing.
- Resolve `asset_id` through the existing Sundered Keep asset catalog and direct tile/prop domain fallback paths.
- Preserve current `_add_sprite` anchoring behavior:
  - floors / mooring floors / overlays: top-left grid placement
  - walls / props / tall sprites: bottom-center base-tile placement

- Add blockers through the existing blocker creation path.
- Add interactables through existing `SunderedKeepInteractable`.
- Track stats:
  - floors
  - edges
  - walls
  - props
  - blockers
  - interactables
  - modules
  - missing_assets

- Print a build summary.

Build summary target:

```text
[SunderedKeepDataTilemap] Built sundered_keep_front_gate_large
  map_size_tiles=112x80
  floors=...
  edges=...
  walls=...
  props=...
  blockers=...
  interactables=...
  modules=...
  missing_assets=0
  return_mooring=true
  key_pickup=true
  main_gate_open=false
```

Map design: required 112×80 layout
Coordinate plan:

1. Ocean / void background

- Fill full map with `ocean_void_01` or dark ocean/void.
- Avoid random isolated square water noise in the play area.
- Ocean/void should frame the island.

2. Broken approach platform

- Center around `[56, 75]`.
- Irregular footprint roughly 9×6.
- Player spawn at `[56, 76]`.
- Use `entrance_causeway_floor_01`, `entrance_causeway_floor_cracked_01`, and edge tiles where available.
- This is the safe start island.
- It should not be a flat gray rectangle.

3. Long broken causeway

- Runs from about `y=72` to `y=60`.
- Mostly 3 tiles wide.
- Widen to 5 tiles at two damaged landings:
  - west bulge around `[50, 67]`
  - east bulge around `[62, 63]`

- Add broken gaps on the sides, but never block the main route completely.
- Use:
  - `entrance_causeway_floor_01`
  - `entrance_causeway_floor_cracked_01`
  - `entrance_causeway_broken_gap_01`
  - `entrance_causeway_edge_e`
  - `entrance_causeway_edge_w`
  - `entrance_causeway_edge_n`
  - `entrance_causeway_shadow_01`

- If edge_s/diagonal edge assets do not exist, use cliff/ocean/foam assets instead.

4. Outer gate landing

- Center around `[56, 58]`.
- Irregular footprint about 25×11.
- This is the pre-gate combat pocket.
- Keep the direct central line to the gate readable.
- Add cover using:
  - `prop_gate_barricade_01`
  - `prop_broken_cart_01`
  - `prop_crate_stack_wet_01`
  - `prop_barrel_wet_01`
  - `prop_fallen_masonry_01`
  - `prop_low_garden_wall_01`

- Do not overcrowd; preserve lanes.

5. Return Mooring alcove

- Place west/southwest of the gate, reachable before the portcullis.
- Suggested 5×5 origin: `[39, 56]`.
- Use `stamp_module` for `return_mooring_3x3_01`.
- Add beacon and console if module stamping does not place them automatically.
- Add interactable:
  - kind: `return_mooring`
  - tile: center of mooring module
  - prompt: `RETURN MOORING`

- This must replace any permanent world text return prompt.

6. Key / winch alcove

- Place east/southeast of the gate, reachable before the portcullis.
- Suggested position: `[73, 56]`.
- Use `prop_gate_winch_01` if available.
- Add interactable:
  - kind: `sundered_gate_key`
  - prompt: `SUNDERED GATE KEY`
  - tile: near winch/key prop

- It grants local/global `sundered_gate_key`.
- This must be reachable before the gate opens.

7. Gatehouse / barbican

- Gate centered near `[56, 50]`.
- Total footprint roughly x=38..74, y=47..59.
- Left tower/mass roughly x=38..48, y=48..59.
- Right tower/mass roughly x=64..74, y=48..59.
- Central portcullis gap x=54..57, y=50..51.
- Use `gatehouse_floor_dark_01` and `gatehouse_floor_murder_hole_01` inside.
- Use `main_gate_threshold_stone_01` and `main_gate_threshold_wet_01` at the threshold.
- Use `main_gate_portcullis_closed` and `main_gate_portcullis_open`.
- Use `main_gate_portcullis_shadow_01`.
- Use `gatehouse_wall_broken_left_01` and `gatehouse_wall_broken_right_01` as large side silhouettes.
- Add side walls/parapets with existing gothic/rampart wall assets.
- The gatehouse should read as the strongest architecture in the lower map.

8. Main portcullis blocker

- Create blocker rect `[54, 50, 4, 2]`, or adapt to exact visual footprint.
- It must exist while gate is closed.
- It must be removed/disabled after `_set_main_gate_open(true)`.

9. Post-gate vestibule

- Small transitional chamber y=44..49, x=50..62.
- Makes the gate feel thick/architectural.
- Use gatehouse/threshold floors.
- Add side blockers/walls to prevent slipping around gate.
- No random huge text.

10. Irregular courtyard

- Center around `[56, 36]`.
- Rough footprint about 46×23.
- Must be irregular, not a perfect rectangle.
- Main route enters from south through vestibule.
- Add central loop around a fountain/statue/rubble anchor.
- Add side cuts/collapses on west/east.
- Use weighted courtyard floors:
  - `main_courtyard_flagstone_01`
  - `main_courtyard_flagstone_02`
  - `main_courtyard_flagstone_cracked_01`
  - `main_courtyard_flagstone_wet_01`
  - `main_courtyard_flagstone_mossy_01`

- Add props:
  - `prop_courtyard_fountain_broken_01`
  - `prop_gothic_statue_broken_01`
  - `prop_gothic_statue_intact_01`
  - `prop_fallen_masonry_01`
  - `prop_broken_cart_01`
  - `prop_crate_stack_wet_01`
  - `prop_barrel_wet_01`
  - `prop_low_garden_wall_01`

- Preserve at least three routes:
  - central route from gate
  - west service/cliff path
  - east rampart path

11. West cliff service path

- Rough corridor x=22..38, y=42..64.
- Narrow, irregular, and exposed.
- Connects outer landing to west courtyard.
- Use cliff rock and cracked floor.
- Add ocean/void or cliff edges beside it.
- This gives a flank route and breaks the symmetry.

12. East rampart path

- Rough corridor x=76..92, y=34..60.
- Use rampart walkway and parapet/broken gap assets.
- Connects outer landing/gatehouse side toward east courtyard/Great Hall.
- Add a choke point and collapsed edge.
- Must be walkable but risky-looking.

13. Great Hall front / north route

- Include the front/lower half of the Great Hall around x=38..74, y=10..26.
- Courtyard leads into it through a blocked/openable Great Hall door near `[56, 27]` or chosen equivalent.
- Use:
  - `great_hall_marble_floor_01`
  - `great_hall_marble_floor_cracked_01`
  - `great_hall_carpet_runner_vertical_01`
  - `great_hall_carpet_runner_horizontal_01`
  - `prop_banquet_table_long_01`
  - `prop_banquet_table_broken_01`
  - `prop_great_hall_column_01`
  - `prop_brazier_iron_01`
  - `prop_throne_ruined_01`

- Keep the Great Hall door closed initially if current behavior expects that.
- Preserve Great Hall blocker validation semantics, but update smoke coordinates to match new layout.

14. Traversal stubs

- Keep upper/lower/hatch traversal markers.
- Suggested:
  - upper stair near east rampart / Great Hall side
  - lower stair near west service path
  - hatch near courtyard southwest or Great Hall threshold

- These can remain stubs but must read visually.

Important visual rules:

- No giant permanent world text like `OPEN MAIN GATE (G)`.
- Use interactable prompts through the existing prompt system only.
- The entrance must not look like a gray runway.
- The gatehouse must not be a pasted wall strip; it needs side masses, threshold depth, and a central gate.
- Ocean/void must frame the island.
- Cliff/causeway edges should explain why the player cannot walk off.
- Use large wall sprites sparingly and deliberately.
- Avoid excessive repeating wall modules.

Validation updates:
Update existing `sundered_keep_layout_smoke.gd` or add a new `sundered_keep_large_layout_smoke.gd`.

New validation should not assume old 80×56 coordinates. It should load the level data and validate markers/interactables by ID where possible.

Required validation:

- JSON loads.
- Map size is at least 96×72.
- Player spawn marker exists.
- Return Mooring marker/module exists.
- `sundered_gate_key` pickup/interactable exists.
- Main Gate interactable exists.
- Main portcullis blocker exists at closed start.
- Main Gate starts closed.
- Great Hall door starts closed if retained.
- Spawn tile is not blocked.
- Return Mooring is reachable before gate opens.
- Key/winch is reachable before gate opens.
- Direct route from spawn to courtyard is blocked before gate opens.
- After `_grant_sundered_gate_key()` and `_try_open_main_gate()`, portcullis blocker is removed.
- After gate opens, route from spawn to courtyard is reachable.
- Great Hall door opens and removes its blocker if retained.
- Missing Sprite2D textures count is zero.
- Missing asset IDs count is zero or explicitly whitelisted with warning.

Run:

```bash
cd /home/braydenchaffee/Projects/CUSTODIAN/custodian
godot --headless --script res://tools/validation/sundered_keep_asset_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_layout_smoke.gd
godot --headless --script res://tools/validation/sundered_keep_large_layout_smoke.gd
```

Docs to update:

```text
custodian/docs/ai_context/CURRENT_STATE.md
custodian/docs/ai_context/FILE_INDEX.md
custodian/docs/ai_context/CONTEXT.md
design/20_levels/in_progress/SUNDERED_KEEP_LARGE_FRONT_GATE.md
```

Document:

- `sundered_keep_front_gate_large.json` is the new data source.
- Sundered Keep map size changed to 112×80 or chosen fallback.
- Front gate layout is now data-driven.
- Existing key-gated portcullis behavior was preserved.
- Return Mooring behavior was preserved and placed before the gate.
- Great Hall door behavior was preserved.
- Entrance/gatehouse asset manifest exists at `custodian/content/metadata/game32/sundered_keep_entrance_gatehouse.game32.json`.
- Return Mooring metadata exists at `custodian/content/metadata/game32/return_mooring.game32.json`.
- Validation commands.

Acceptance criteria:

- Sundered Keep starts on a proper broken exterior approach, not a flat gray runway.
- Map is at least 96×72, preferred 112×80.
- Layout is built from `sundered_keep_front_gate_large.json`.
- Current gate/key/mooring/Great Hall interactions still work.
- Player cannot pass main gate before key.
- Player can reach return mooring before gate.
- Player can reach key/winch before gate.
- Gate opens after key and removes collision.
- Courtyard route opens after gate.
- The map has readable outer landing, gatehouse, courtyard, west service path, east rampart path, and Great Hall approach.
- No permanent giant interaction text remains in normal world art.
- Existing asset smoke passes.
- Updated or new layout smoke passes.
- Active docs are updated.
- No legacy Python runtime changes.

One important drift note for Codex: the AI context says the Sundered Keep causeway edge overlays include cardinal and diagonal borders, but the included current manifest only proves `entrance_causeway_edge_n/e/w` plus other entrance tiles. Codex should verify asset IDs before using `edge_s/ne/nw/se/sw`, and either skip missing IDs or substitute cliff/ocean/foam tiles.
