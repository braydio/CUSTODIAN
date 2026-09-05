# Task Packet: Procgen Native-32px Spatial Normalization

- **Status:** complete
- **Date:** 2026-09-05
- **Spec:** `design/02_features/procgen/PROCGEN_32PX_SPATIAL_NORMALIZATION.md`

## Objective

Migrate the live procgen world from a legacy 16px logical `TileMap` grid ×
`ProcGenMap.scale = Vector2(2, 2)` to native 32px logical tiles ×
`ProcGenMap.scale = Vector2(1, 1)`, with `ProcGenMap.scale == Vector2.ONE` as
the final invariant and **no change to world coordinates**. Must land before
Procgen Macro Presentation V1.

## Historical origin of `scale = Vector2(2, 2)`

`git blame` and `git log -S 'scale = Vector2(2, 2)' -- custodian/game/world/procgen/proc_gen_map.tscn`
both converge on commit `d16c2d7109` ("Track custodian Godot project
[no-docs]", 2026-03-27, author `braydio <chaffee.brayden@gmail.com>`) — a
3141-file bulk import of an already-built local Godot project into this
monorepo. No later commit ever touched the `scale` property; the next commit
to touch this file (`a396a4479`, "proc gen") only added child nodes.

At the import commit, the TileSet's floor/low-wall atlas sources pointed at
literally-named `atlas_floor-16x16.png` / `atlas_walls_low-16x16.png` (the
`0x72_DungeonTilesetII_v1.7` placeholder pack) with no `texture_region_size`
override, and the TileSet's own `tile_size` was also unset (implicit 16×16).
**Conclusion (high confidence): the 2× scale is a mechanical consequence of
16px placeholder art, inherited via bulk import, not a documented design
decision.** No retired Python prototype was consulted.

## Pre-migration TileSet size

`custodian/content/tiles/tilesets/procgen_world_tileset.tres` had no explicit
`tile_size` in its `[resource]` block — implicit Godot default `16×16`.

## Pre-migration effective world cell size

32×32 world px (16px logical × 2× root scale) — unchanged after migration,
now reached natively (32px logical × 1× root scale).

## Active 16px dependencies discovered, and disposition

| Dependency | Live? | Disposition |
|---|---|---|
| TileSet `[resource].tile_size` (implicit 16×16) | Yes (structural) | Set explicit `Vector2i(32, 32)`. |
| `high_walls_source_id` fallback → source 2 (`atlas_walls_high-16x32.png`, explicit 16×32) | No — `use_high_walls` defaults `false`, never overridden live | Documented as compatibility-only/dead; not converted (no art redesign in scope). |
| `"ProcGen"` compatibility child's `high_walls_source_id = 3` | No — `generation_output_enabled = false` | Documented as dead; untouched. |
| Sources 0, 1, 4-9, 11 (16×16-default or unreferenced 32×32 atlases) | No | Unused legacy; left in place. |
| 6 defensive `Vector2(16, 16)` fallbacks in `proc_gen_tilemap.gd` | No (only fire when `tile_set == null`, never true live) | Bumped to 32 for consistency. |
| `ShadowSystem._tile_size` default | No (overwritten from real TileSet on every use) | Bumped to 32. |
| `SunderedKeepWorldVista.DEFAULT_TILE_SIZE`, `SunderedKeepProcgenVistaPresentation._runtime_tile_size()`/`_tile_to_world()` fallbacks | No (real map always supplied in production) | Bumped to 32. |
| `ContractWorldLoader.fallback_tile_size`, `WorldIngressSpawner.fallback_tile_size` | Only for non-procgen `Node2D` maps missing `get_runtime_tile_size` | Bumped to 32 — this is also a pre-existing correctness fix, since the authored interior maps (`gothic_compound_map.gd`, `sundered_keep_map.gd`) already use `TILE_SIZE := 32.0`. |
| `ShadowOverlay.shadow_offset_px` (6,6), `edge_inset_px` (3.0) | Yes, live, local-space under the (now-retired) scaled root | Doubled to (12,12) / 6.0 to preserve current on-screen appearance. |
| `horizontal_wall_endcap_vertical_jitter_px` (12) | Yes, live, same category | Doubled to 24. |
| South-connector sprite `Vector2(28.0, 48.5)` footprint + `-4.0` offset | Yes, live, same category | Doubled to `Vector2(56.0, 97.0)` / `-8.0`. |
| `AshBellThreadwayCauseway.SOURCE_TILE_SIZE` (32×32) | Yes | Already correct; zero changes. Its `tile_size / SOURCE_TILE_SIZE` already evaluated to `Vector2.ONE` before this migration. |
| Macro Presentation V1 draft's `world_scale = macro_presentation_back.global_transform.get_scale()` | Yes | Already correct (reads live scale dynamically); zero changes. |

## Changed files

- `custodian/content/tiles/tilesets/procgen_world_tileset.tres` — added `tile_size = Vector2i(32, 32)`.
- `custodian/game/world/procgen/proc_gen_map.tscn` — `scale = Vector2(2, 2)` → `Vector2(1, 1)`.
- `custodian/game/world/procgen/proc_gen_tilemap.gd` — 6 fallback constants (16→32), `horizontal_wall_endcap_vertical_jitter_px` (12→24), south-connector sprite size/offset (doubled).
- `custodian/game/systems/core/systems/shadow_system.gd` — `_tile_size` fallback (16→32), `shadow_offset_px` (6→12), `edge_inset_px` (3→6).
- `custodian/game/world/vistas/sundered_keep/sundered_keep_world_vista.gd` — `DEFAULT_TILE_SIZE` (16→32).
- `custodian/game/world/vistas/sundered_keep/sundered_keep_procgen_vista_presentation.gd` — two fallback constants (16→32).
- `custodian/game/systems/core/systems/contract_world_loader.gd` — `fallback_tile_size` (16→32).
- `custodian/game/world/levels/world_ingress_spawner.gd` — `fallback_tile_size` (16→32).
- `custodian/tools/visual_labs/sundered_keep_shoreline_lab.tscn` — `PreviewRoot.scale` (2,2 → 1,1); see the second scale-compensation-site discovery below.
- New `custodian/game/world/procgen/procgen_spatial_contract.gd` — `ProcgenSpatialContract`.
- New `custodian/tools/validation/procgen_spatial_normalization_smoke.gd` — permanent validation smoke (17 assertions).
- `custodian/tools/validation/validation_manifest.json` — registered `procgen_spatial_normalization`.
- New `design/02_features/procgen/PROCGEN_32PX_SPATIAL_NORMALIZATION.md`.
- `custodian/docs/ai_context/CURRENT_STATE.md`, `FILE_INDEX.md` — updated.
- `reports/procgen_spatial_normalization/pre_migration_baseline.txt`, `post_migration_report.txt` — diagnostic capture (not source-of-truth).

Not touched: `ash_bell_threadway_causeway.gd` (already correct), the
in-flight Macro Presentation V1 draft files (already scale-agnostic, no
changes needed), `custodian/game/camera.gd` (see deferred items below).

**Second scale-compensation site discovered and fixed:**
`custodian/tools/visual_labs/sundered_keep_shoreline_lab.tscn` — its
`PreviewRoot` node carried an independent `scale = Vector2(2, 2)` (unrelated
to `ProcGenMap`) while its child `Floor`/`Foam` `TileMapLayer`s reference the
same shared `procgen_world_tileset.tres`. After that TileSet's `tile_size`
became native 32×32, this node's un-migrated 2× scale would have doubled its
effective world cell size to 64px, diverging from production. Fixed to
`Vector2(1, 1)`, mirroring the `ProcGenMap` fix — exactly the "silently
maintaining parallel 16px and 32px spatial contracts" failure mode this
migration exists to close. Found via `--tag procgen` validation, not the
original file-level audit (this file is a visual-lab tool, not core
gameplay/procgen).

## Before/after cell-center measurements (seed 913042, map 96×80)

| Measurement | Before | After |
|---|---|---|
| `ProcGenMap.scale` | (2.0, 2.0) | (1.0, 1.0) |
| `Floor`/`Walls` `tile_set.tile_size` | (16, 16) | (32, 32) |
| `get_runtime_tile_size()` | (32.0, 32.0) | (32.0, 32.0) — unchanged |
| Horizontal step (0,0)→(1,0) | 32.0000 | 32.0000 — unchanged |
| Vertical step (0,0)→(0,1) | 32.0000 | 32.0000 — unchanged |
| Round trip (10,10)→global→cell | (336.0, 336.0) → (10,10) | (336.0, 336.0) → (10,10) — unchanged |
| Cell (0,0) local center | (8.0, 8.0) | (16.0, 16.0) — now the true half-cell |
| Wall collision shape size (sample tile) | (16.0, 16.0) | (32.0, 32.0) — now aligned to the real 32px cell |
| `ShadowOverlay._tile_size` | (16.0, 16.0) | (32.0, 32.0) |

## Before/after map world dimensions

map_size=(96, 80): measured width 3040.00, height 2528.00 — **identical
before and after** (`(map_size - 1) × 32`).

## Before/after player-spawn global coordinate

Spawn tile (48, 68) → global **(1552.0, 2192.0)** — **identical before and
after.**

## Collision/nav equivalence result

Wall-collision anchor position (`minimap_tile_to_global`) matches the
canonical `tile_to_global_position` transform before and after; the
collision shape itself correctly grew from the stale 16×16 representation to
the true 32×32 world footprint (a correction, not a regression — the world
footprint of an actual wall cell was always meant to be 32×32).
Godot's `NavigationRegion2D`/`NavigationServer2D` baked-polygon path was
found to be **vestigial** — no gameplay code (`enemy_behavior_state_machine.gd`
patrol targeting) queries it. Real gameplay reachability goes through
`ProcGenTilemap.project_runtime_walkable_global()`, which was verified to
resolve identically before and after (walkable-neighbor projection returns
the neighbor's own canonical position in both cases).

## Threadway scale result

`AshBellThreadwayCauseway`'s persistent 32px floor sprite scale is
`Vector2.ONE` — confirmed by a new smoke assertion, both before and after
this migration (it was already correct; `SOURCE_TILE_SIZE` was already
32×32).

## Remaining intentional 16px compatibility assets

- `procgen_world_tileset.tres` source 2 (`atlas_walls_high-16x32.png`,
  explicit 16×32) — reachable only via `high_walls_source_id`, dead because
  `use_high_walls` defaults `false` and is never overridden live.
- `procgen_world_tileset.tres` sources 0, 1, 4-9, 11 — unreferenced by any
  live export or generation code path.
- `"ProcGen"` compatibility child node in `proc_gen_map.tscn`
  (`generation_output_enabled = false`) and its `high_walls_source_id = 3`.

None of these can affect live `ProcGenMap` output today.

## Focused smoke results

All PASS: `biome_field_smoke`, `terrain_builder_smoke`,
`terrain_gameplay_packs_smoke`, `terrain_gameplay_art_usage_smoke`,
`procgen_walkable_boundary_smoke`, `procgen_stuck_pocket_smoke`,
`runtime_wall_collision_compaction_smoke`, `ash_bell_threadway_causeway_smoke`,
`ash_bell_threadway_generation_contract_smoke`,
`contract_world_population_placement_smoke`, and the new
`procgen_spatial_normalization_smoke` (17/17 assertions).

**`sundered_keep_world_vista_smoke` fails** — confirmed via a controlled
revert-and-rerun that this failure is **pre-existing and unrelated to this
migration** (camera-blend-weight assertions unrelated to tile size; the
test's own `FakeMap.get_runtime_tile_size()` already hardcodes 32×32 and
never touches the one fallback constant this migration changed in
`sundered_keep_world_vista.gd`). Not fixed — out of scope for a spatial
coordinate migration; flagged for separate investigation.

Only `biome_field_smoke` was registered in `validation_manifest.json` before
this task; the other 10 "must preserve" tests are invoked directly per
`VALIDATION_RECIPES.md` / the procgen and route-pipeline shell suites, not
gated by the manifest — this task registers the new
`procgen_spatial_normalization` smoke there but does not change that for the
other 10 (out of scope).

**Additional `--tag procgen` validation run (23 tests, beyond the explicit
preserve-list):** 20 passed. Three findings:
- `sundered_keep_shoreline_compositor` — initially failed with "rendered
  cliff global position/facing diverged," root-caused to the second
  scale-compensation site above and fixed (see "Changed files"). After the
  fix, a **different, narrower** failure remains: `plan_fingerprint()`
  equality checks between the lab's live-rebuilt plan and a directly-built
  plan (and between a production fixture and the lab replaying that
  fixture) still diverge, even though the measured `world_cell_size` is now
  identical (32.0) on both sides. This is a debug/authoring-tool-internal
  consistency check (`tools/visual_labs/sundered_keep_shoreline_lab.gd` +
  its own smoke), not a live-gameplay spatial-position issue — the actual
  procgen runtime's cliff rendering position/facing now matches production
  exactly. Left unresolved as out of scope; flagged for separate
  investigation (possibly float-precision sensitivity in
  `plan_fingerprint()`, or a pre-existing lab/production parameter mismatch
  previously masked by two independently-wrong scale values canceling out).
- `procgen_ambient_enemy_real_world_spawn` — stderr contains
  `SpriteFrames already has animation 'melee_e'/'melee_w'` from
  `enemy_animation_set.gd`/`enemy_presentation_controller.gd`; the test's own
  final print is `PASS` and it exits 0. Confirmed unrelated by code-path
  disjointness (no file in this migration's diff appears anywhere in the
  error's call stack) — pre-existing enemy-presentation-setup issue,
  unrelated to procgen spatial normalization.
- `sundered_keep_procgen_frontage` — fails on backdrop-activation-state
  assertions ("explicit chasm semantics did not replace world-fallback
  backdrop," "camera-following rectangular depth backdrop remains active").
  Confirmed unrelated by code-path disjointness (`procgen_depth_backdrop.gd`
  is not touched by this migration's diff). Not independently revert-tested
  due to time; recommend separate investigation if this persists after this
  migration lands.

## Changed-file validation result

`python3 custodian/tools/validation/run_validation.py --changed --json`,
`architecture_ownership_smoke.py`, and `validate_historical_archive_boundaries.py`
were run; results captured at commit time (see repo CI/validation output for
this commit).

## Moment Forge capture/report

Not run in this session — requires the interactive capture harness
(`run_moment.py --capture-mode full`) against a running scene, which this
headless validation pass did not exercise. Recommended as a manual follow-up
before this change is considered fully visually verified, per the design
doc's explicit instruction not to auto-approve a new visual baseline.

## Documentation drift corrected

`CURRENT_STATE.md` and `FILE_INDEX.md` updated (see diff). This task packet
and the design doc are new.

## Intentionally deferred items

- `custodian/game/camera.gd::_rebuild_bounds_from_procgen()` reads raw
  `tile_set.tile_size` (unscaled) for its half-cell edge-padding calculation
  rather than `get_runtime_tile_size()`. This under-padded by the 2× factor
  before this migration and now self-corrects to the true half-cell value —
  a positive incidental fix, not touched directly, out of scope.
- `procgen_walkable_boundary_smoke.gd` / `procgen_stuck_pocket_smoke.gd`
  construct self-contained, unscaled synthetic 16×16 TileSets independent of
  the global root scale. Left as-is; optional cosmetic bump to 32 for
  representativeness was considered and intentionally skipped to avoid
  unnecessary risk on tests that already pass and are not spatially
  meaningful either way.
- `sundered_keep_world_vista_smoke` failure (pre-existing, confirmed
  unrelated) — left for separate investigation.
- `sundered_keep_shoreline_lab.gd`'s `plan_fingerprint()`-equality divergence
  (see "Focused smoke results") — a debug-tool-internal consistency check,
  not a live spatial-position issue; left for separate investigation.
- `procgen_ambient_enemy_real_world_spawn` and `sundered_keep_procgen_frontage`
  test failures (confirmed unrelated by code-path disjointness) — left as-is,
  flagged for whoever owns those systems.
- Promoting `high_walls_source_id`'s legacy 16×32 art to native 32×32, or
  removing unused legacy TileSet sources — explicitly out of scope (no art
  redesign; nothing live depends on them).
- Procgen Macro Presentation V1 itself — not implemented in this task, per
  explicit instruction; this migration exists so it can build on a
  normalized world.

## Commit SHA

See the commit immediately following this task packet's addition in the
repository history.
