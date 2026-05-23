# Main Map Roads And Speed Surfaces

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-21
- Created: 2026-05-21
- Last updated: 2026-05-21

## Task

Add deterministic main-map road/path generation, keep road areas mostly clear of trees, move vehicles to a parking-like road apron, and apply surface speed boosts for walking and stronger boosts for driving.

## Outcome

The generated contract map exposes a readable but modest road network outside the gothic compound, vehicles spawn near a parking zone on that road network, foliage avoids road/parking cells, and operator/vehicle movement speed increases while on road/path tiles.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs: `design/02_features/procgen/STARTER_MAP_PROCGEN.md`, `design/02_features/vehicles/VEHICLES.md`
- Active runtime/docs files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`, `custodian/game/actors/operator/operator.gd`, `custodian/game/actors/base/vehicle_base.gd`
- Historical reference only: `python-sim/`

## Work Surface

- Files or folders expected to change: procgen tilemap, contract world loader, operator movement, vehicle movement, active AI context docs, procgen design note.
- Files or folders expected to be read but not changed: scene wiring, validation recipes.
- Out-of-scope areas: production road art, vehicle combat/damage polish, gothic compound connected-map generator.

## Constraints

- Determinism concerns: Road, parking, and speed-surface decisions must derive from existing tile hash/seed state.
- Simulation/UI boundary concerns: Movement speed changes stay in actor/controller code and query procgen metadata; HUD/UI remains unchanged.
- Asset requirements: No new production art required; road/path visuals use generated `Sprite2D` stamps from `res://content/tiles/roads_paths/runtime/roads/` and `res://content/tiles/roads_paths/runtime/paths/`, with source sheets and `Pathways.json` preserved under `res://content/tiles/roads_paths/source/`.
- Compatibility or migration concerns: Keep existing `soft_path` semantics and level-data consumers working.
- Clarifying questions or assumptions: Treat “main map” as the generated contract map, and “not super pretty like gothic compound” as a functional road/path pass using current tile visuals.

## Implementation Plan

1. Add a deterministic main-road/parking-zone pass to `ProcGenTilemap` and expose road/parking cells in level data.
2. Exclude road/parking surfaces from foliage and provide movement-surface multiplier queries.
3. Move vehicle placement to parking cells first, then fall back to existing compound placement.
4. Apply road/path multipliers to operator and occupied vehicle movement.
5. Update design/context docs and run feasible Godot validation.

## Acceptance

- Runtime behavior: Main generated map has a connected road/path with a parking apron; vehicle starts on/near the apron; road/path surfaces boost movement.
- Documentation: Design and AI context mention the new road/speed-surface slice.
- Path/reference validation: Changed paths remain canonical under `custodian/`.
- Manual validation: Headless scene/script check where feasible.
- Automated/headless validation: Run Godot check or smoke validation command if available.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Yes.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? No.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Yes.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Yes.

## Completion Notes

- Implemented: Deterministic connected main road carving, post-carve road graph repair for required anchors, parking-zone stamping, split `roads_paths/runtime/roads/road_piece_manifest.game32.json` and `roads_paths/runtime/paths/path_piece_manifest.game32.json` loading, connection-bitmask road-piece sprite decals over default procgen floor cells, generated footpath/degraded-transition decals for `soft_path` routes, a long walled main-map connector road from the chosen compound ingress, deterministic connector elevation/ramp metadata and visuals after TerrainBuilder, post-wall/terrain-builder road walkability enforcement, foliage exclusion, level-data road/parking exports, vehicle parking placement, road/path movement multipliers for the operator and occupied vehicles, and a TileMapLayer no-TileSet fallback for portal/minimap tile-to-world conversion.
- Validated: `godot --headless --path custodian --quit` completed after the resized road-piece, footpath, graph-repair, and walled connector update; terrain connectivity stayed true and navigation rebuilt. `git diff --check` passed.
- Deferred: Richer parking props/signage remain future polish.

## Next Steps

- Next action: Visual playtest the generated road/parking feel and the walled compound connector in the editor.
- Best starting files: `custodian/game/world/procgen/proc_gen_tilemap.gd`, `custodian/game/systems/core/systems/contract_world_loader.gd`
- Required context: active procgen level data and vehicle placement.
- Validation to run: `godot --headless --path custodian --quit`
- Blockers or open questions: None.
