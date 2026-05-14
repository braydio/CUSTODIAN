# INDOOR / OUTDOOR PROCGEN REGIONS

## Packet Status

- Status: complete
- Owner: agent
- Agent/session: Codex 2026-05-05
- Created: 2026-05-05
- Last updated: 2026-05-05

## Task

Add the first region-aware procgen slice so one section of the generated tactical map can become a constructed interior complex while the rest of the map remains natural/exterior procgen.

The first implementation target is a deterministic rectangular interior region with hallway/room carving, indoor/outdoor transition openings, region metadata, and spawn filters that keep outdoor-only dressing from appearing inside the constructed area.

## Outcome

When complete, generated contract maps can contain:

- Natural/exterior regions using the existing cave/ruin/naturesque generation.
- One reserved indoor complex region, initially near or attached to the existing compound footprint.
- Hallway/room/bay-style carved interior space inside that region.
- Doorway/threshold connections between exterior and interior.
- Region metadata that downstream systems can query before spawning foliage, ruin props, ambient critters, or future objectives.

This first slice is not a full Edgar/template-room replacement. It is a runtime extension to the current `ProcGenTilemap` path that keeps one map, one navigation space, and one deterministic contract seed.

## Authority

- Root routing: `AGENTS.md`
- Local routing: `custodian/AGENTS.md`
- Active design/spec docs:
  - `design/03_architecture/REGION_GENERATION_SYSTEM.md`
  - `design/03_architecture/COMPOUND_TILE_SYSTEM.md`
  - `design/02_features/pixel_planet/PIXEL_PLANET_CONTRACT_SYSTEM.md`
- Active runtime/docs files:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/custodian_contract_map.gd`
  - `custodian/game/world/procgen/proc_gen_map.tscn`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
- Historical reference only:
  - `python-sim/game/`
  - `python-sim/design/*` except locked doctrine references routed through root guidance

## Work Surface

- Files or folders changed:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/ui/hud/ui.gd`
  - `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`
  - `custodian/docs/ai_context/CURRENT_STATE.md`
  - `custodian/docs/ai_context/FILE_INDEX.md`
  - `custodian/docs/ai_context/task_packets/README.md`
  - `custodian/docs/ai_context/task_packets/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`
- Files or folders expected to be read but not changed:
  - `design/03_architecture/REGION_GENERATION_SYSTEM.md`
  - `design/03_architecture/COMPOUND_TILE_SYSTEM.md`
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`
  - `custodian/content/tiles/tilesets/procgen_world_tileset.tres`
- Out-of-scope areas:
  - New production art generation.
  - Separate interior scene loading.
  - Save/load persistence for generated region metadata.
  - Full template-room/Edgar integration.
  - Combat/objective placement inside interior regions beyond keeping spawn filters sensible.

## Constraints

- Determinism concerns:
  - Region placement, hallway carving, room/bay carving, thresholds, and metadata must derive from the existing procgen seed/profile path.
  - Avoid global RNG calls in generation logic.
- Simulation/UI boundary concerns:
  - Region metadata belongs to world generation/runtime query state, not HUD or terminal presentation.
  - Visual tile choices must not become gameplay authority unless explicitly mirrored into wall/floor state.
- Asset requirements:
  - First slice may reuse existing floor/wall tile sources.
  - If dedicated interior tiles are missing, use current floor/wall sources with region metadata ready for later tile-family swap.
- Compatibility or migration concerns:
  - Preserve current natural procgen path outside the reserved interior region.
  - Preserve navigation, runtime wall collision, destructible wall health, streaming reveal, foliage, ruin props, and Shrumb spawning.
  - Keep collision stable: indoor walls remain normal wall cells; indoor floors remain normal floor cells.
- Clarifying questions or assumptions:
  - Assumption: first indoor complex can be rectangular and attached near the compound, not a separate map.
  - Assumption: "passages" means playable hallway/room layout, not only decorative wall passage art.
  - Assumption: warehouse/military flavor can start as layout grammar and metadata before final tile art exists.

## Implementation Plan

1. Add exported controls for indoor region generation: enable flag, region size range, room count, hallway width, entrance count, and debug logging.
2. Add internal region metadata dictionaries/arrays keyed by tile: region type, indoor/outdoor, hallway, room, doorway/threshold.
3. During `_fill_tilemaps`, reserve and carve one constructed interior region after natural generation and before wall visual/collision capture.
4. Build a deterministic hallway spine with branch rooms and one larger bay inside the region.
5. Carve exterior threshold openings that connect interior floors to adjacent exterior floors.
6. Update foliage/ruin prop filters to reject indoor region tiles by default.
7. Expose lightweight query helpers such as `get_region_type_at_tile()` and `is_indoor_tile()`.
8. Update docs and packet notes, then run Godot headless validation.

## Acceptance

- Runtime behavior:
  - Generated maps include a visible constructed region with hallway-like traversal and attached rooms/bays.
  - Exterior/natural generation still surrounds the interior region.
  - The player can navigate through indoor/outdoor thresholds.
  - Foliage and ruin prop scatter do not appear inside indoor floor/room/hallway tiles unless explicitly allowed later.
  - Existing compound generation remains functional.
- Documentation:
  - Task packet stays current.
  - Active design/procgen note describes the first slice and deferred work.
  - AI context state/index mention region-aware indoor/outdoor procgen if implemented.
- Path/reference validation:
  - New docs are indexed in `FILE_INDEX.md` and task packet README if added.
  - No stale paths are introduced.
- Manual validation:
  - Recommended follow-up: boot the game and visually inspect one generated contract map for interior region, thresholds, foliage exclusion, and navigation.
- Automated/headless validation:
  - Run `godot --headless --path custodian --quit`.
  - Existing TileSet/resource leak warnings are known; new parse errors, missing resources, or broken script loads are blockers.

## Drift Review

- Does `custodian/docs/ai_context/CURRENT_STATE.md` need an update? Updated.
- Does `custodian/docs/ai_context/CONTEXT.md` need an update? Probably no unless workflow/authority changes.
- Does `custodian/docs/ai_context/FILE_INDEX.md` need an update? Updated.
- Does `custodian/AGENTS.md` need an update? No.
- Do any design docs need an update? Added `design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md`.

## Completion Notes

- Implemented:
  - Added constructed interior region exports to `ProcGenTilemap`.
  - Added deterministic region stamping after compound generation.
  - Added central hallway, side rooms, warehouse bay, and threshold carving.
  - Added per-tile region metadata and query helpers.
  - Added `interior_region_rect`, `interior_rooms`, `interior_thresholds`, and `region_tiles` to level data.
  - Blocked foliage and ruin prop placement on indoor tiles.
  - Repaired a pre-existing `ui.gd` first-line parse split from `e` + `xtends CanvasLayer` back to `extends CanvasLayer` because it blocked validation.
- Validated:
  - `godot --headless --path custodian --quit`
  - Result: completed without new script load errors. Existing object/resource leak warnings remain.
- Deferred:
  - Dedicated interior tile art/families.
  - Multiple interior regions.
  - Template-authored room layouts.
  - Objective/enemy spawn semantics inside interiors.
  - Separate indoor lighting/occlusion rules.

## Next Steps

- Next action: visually inspect a generated map in editor/play mode and tune region placement, size, hallway width, and tile families.
- Best starting files:
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`
  - `custodian/game/world/procgen/proc_gen_map.tscn`
- Required context:
  - Existing compound region build/carve methods.
  - Existing foliage and ruin prop spawn filters.
  - Runtime wall collision and streaming reveal order.
- Validation to run:
  - `godot --headless --path custodian --quit`
  - Manual Godot boot for visual confirmation.
- Blockers or open questions:
  - Visual distinction will be limited until dedicated interior tile families are assigned.
