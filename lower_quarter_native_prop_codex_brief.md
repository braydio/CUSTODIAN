# CUSTODIAN — Lower Quarter Native Prop Full Authored Placement Pass

Repository: `/home/braydenchaffee/Projects/CUSTODIAN`
Godot project: `custodian/`

## Authority files supplied with this task

Copy these into the repo before implementation:

- semantic inventory -> `custodian/content/metadata/assets/meridian_civic_props_native.semantic.json`
- exact authored placements -> `custodian/game/world/levels/authored/ash_bell/common/lower_quarter_native_prop_placements.json`

The placement JSON is AUTHORITATIVE. Do not move, substitute, omit, randomize, or add placements without reporting a blocked asset/coordinate and stopping that placement. It contains 258 exact instances using 180 unique extracted source IDs and covers all 77 non-review semantic families. The only semantic families deliberately excluded are `compound_rubble_prop` (177), `compound_salvage` (201), and `compound_masonry` (212), because the semantic manifest marks them `review_required=true`.

## Current renderer diagnosis

`MeridianCivicArtPresenter` remains a CanvasItem draw pass. It collects authored walkable cells and draws one 32x32 floor atlas region per walkable cell. Wall bands are also draw-time presentation. The legacy `_draw_prop()` path still routes through the 512x512 32px prop atlas and therefore must no longer be used for PHYSICAL native props.

Do NOT rewrite floor or wall tiling in this task.

Native physical props must be instantiated nodes/resources at native scale. Floor hardware may also be instantiated from native sprites where called out by the placement manifest, but remains collisionless unless authored topology separately says otherwise.

## Existing reusable prop contract

Prefer the existing `ProceduralProp`/`PropDefinition` contact-anchor model rather than inventing a competing anchor/collision system. The existing design contract already defines:

- root Node2D = floor/contact anchor
- sprite positioned from authored anchor offset
- collision authored separately from visuals
- player-relative depth sorting for tall props
- no alpha-derived collision

For this authored route, do NOT use scatter/random generation. Use the exact placement manifest only.

## Source extraction

Source inventory is the native extraction from:
`custodian/asset_drop/source_work/lower_quarter_region/meridian_civic_props_atlas__master.png`

Extraction settings are locked:
- alpha threshold 10
- 4-connected components
- minimum component area 100 px
- 3 px transparent crop padding
- no resizing

The semantic manifest maps each `source_id` to an exact extracted PNG, semantic family, runtime family, variant key, native size, contact anchor, role and collision hint.

## Asset V2 family normalization

Asset V2 family canvas is fixed. Do not resize a variant to fit the family canvas. PAD with transparent pixels while preserving the extracted sprite's pixel scale and contact anchor.

Use these exact runtime-family canvases:

| runtime family | canvas |
|---|---:|
| meridian_civic_structure | 80x96 |
| meridian_civic_lighting | 64x96 |
| meridian_civic_signage | 80x112 |
| meridian_civic_terminal | 64x96 |
| meridian_civic_utility | 80x96 |
| meridian_civic_security | 64x96 |
| meridian_civic_bench | 144x80 |
| meridian_civic_waste | 48x80 |
| meridian_civic_traffic_control | 176x160 |
| meridian_civic_worksite | 64x160 |
| meridian_civic_floor_hardware | 96x96 |
| meridian_civic_industrial_module | 128x160 |
| meridian_civic_basin | 96x96 |
| meridian_civic_planter | 144x96 |
| meridian_civic_debris | 160x96 |
| meridian_civic_crate | 96x80 |
| meridian_civic_container | 80x80 |

For `floor_contact` variants, align the manifest's `extract_anchor_px` to the family canvas bottom-center contact target. For `floor_center`, align visual center to canvas center. For `wall_mount`, preserve the manifest mount anchor and use placement offset from the exact placement manifest.

Nearest-neighbor only. Integer scale 1.0 only. No rotation except explicit `rotation_quarters` in placement data; currently all placements are 0 and must remain 0.

Create/patch Asset V2 contracts with one state/variant per semantic `variant_key` using `layout=copy`. Ingest through Asset V2; never copy runtime PNGs directly into `content/`.

After ingest, resolve canonical runtime paths from `asset_catalog.generated.json` at implementation time and generate a static runtime catalog/resource. Runtime gameplay must not parse the asset catalog JSON.

## Runtime native prop layer

Create a reusable authored-only native prop layer, suggested path:

`custodian/game/world/levels/authored/ash_bell/common/lower_quarter_native_prop_layer_2d.gd`

Responsibilities:
1. accept `map_origin`, `cell_size=32`, level id, exact placement records
2. resolve each record's `source_id` against the generated native-prop runtime catalog
3. instantiate one Node2D/ProceduralProp root per record
4. root world position is EXACTLY:
   `map_origin + Vector2(cell.x * 32 + 16, cell.y * 32 + 16) + offset_px`
5. place the sprite from its semantic anchor; never stretch it into a cell
6. keep scale `Vector2.ONE`
7. Y-sort physical/tall props using existing prop depth contract
8. floor overlays sit below actor sprites and above base floor
9. wall-mounted cameras use their exact placement offset and no collision
10. expose debug snapshot: placement_id, source_id, resolved texture, root world position, native size, anchor, role

Do not place native physical props through `MeridianCivicArtPresenter._draw_prop()`.

Remove/suppress legacy `_draw_prop()` calls for any category now represented in `lower_quarter_native_prop_placements.json`. Floor and wall atlas rendering stays in the presenter.

## Exact coordinate convention

The placement file uses authored cell anchors.

Lower Quarter:
- map origin `Vector2(-2048, -1536)`
- world anchor = `Vector2(-2032 + 32*x, -1520 + 32*y) + offset_px`

West Gate Works:
- map origin `Vector2(-1024, -768)`
- world anchor = `Vector2(-1008 + 32*x, -752 + 32*y) + offset_px`

Station IX:
- map origin `Vector2(-1024, -896)`
- world anchor = `Vector2(-1008 + 32*x, -880 + 32*y) + offset_px`

The JSON includes the expected world anchor for every record. Assert the calculated result equals the stored `world_anchor` exactly. Fail validation if not.

## Exact placement counts

- Lower Quarter: 112 exact instances
- West Gate Works: 64 exact instances
- Station IX: 82 exact instances
- Total: 258 exact instances
- Unique extracted variants used: 180
- Semantic families represented: 77 / 80
- Excluded review-only families: exactly 3 (`177`, `201`, `212` families)

No runtime RNG. No deterministic hash choice. No alternate variant selection. The source ID in the placement record is the variant.

## Coordinate safety

Every supplied anchor cell was checked against the current authored walkable-region union for its level. No supplied placement anchors collide exactly with these required interaction/spawn cells:

Lower Quarter:
- Spawn_FromWorld `(64,87)`
- Exit_ReturnWorld `(64,91)`
- Exit_WestGateWorks `(6,43)`
- Exit_StationIX `(74,65)`
- evac_annunciator `(39,58)`
- gate_pressure_relay `(22,42)`
- station_ix_transit_interlock `(89,21)`

West Gate Works:
- spawn `(55,24)`
- backtrack `(58,24)`
- gate motor relay `(12,24)`

Station IX:
- spawn `(32,50)`
- backtrack `(32,53)`
- Assembly A `(24,33)`
- Assembly B `(40,33)`
- Assembly C `(32,18)`

Do not move a prop simply because its native visual overlaps an adjacent cell. Native sprites are expected to visually span multiple authored cells.

## Collision rule for this pass

Visual placement is exact; collision remains separately authored.

- `floor_overlay`, `wall_mounted_prop`, `micro_debris`: no collision.
- direct-collapse debris in Lower Quarter: visual only; existing `DirectPersonnelCollapse` remains collision authority.
- props whose manifest collision is `optional_*`: default visual only for this pass unless they are positioned on a perimeter and collision can be proven not to narrow a required route.
- benches, planters, fountains, large crates, barriers, industrial racks/modules: add authored simple footprints only after checking the exact placement against the authored navigation provider. Never use sprite alpha or full sprite bounds.
- if collision is enabled, register the footprint with the authored navigation provider and assert all required route paths remain reachable.

The exact visual placement MUST NOT be moved to solve collision. Adjust/disable the separate collision footprint instead.

## Required scene integration

Add `NativePropRoot` under `PropsRoot` in:
- lower_quarter.tscn
- west_gate_works.tscn
- station_ix.tscn

Each level configures the native prop layer with its own exact level id and map origin, then loads only that level's placement records.

## Validation

Add `lower_quarter_native_prop_placement_smoke.gd` and validate:

1. placement JSON has exactly 258 records
2. counts are exactly 112 / 64 / 82 by level
3. all 258 `placement_id` values unique globally
4. all `source_id` resolve to the semantic manifest and ingested runtime texture
5. exactly 180 unique source IDs are used
6. exactly 77 semantic families represented
7. review-required IDs 177, 201, 212 are absent
8. every native texture renders at scale 1.0
9. calculated world anchor equals placement JSON `world_anchor`
10. no physical prop is rendered through the legacy 32x32 `_draw_prop` path
11. floor overlays have no collision
12. wall-mounted cameras have no collision
13. required spawn/exit/relay/assembly cells remain unobstructed
14. authored navigation paths still exist for all required route segments
15. screenshot fixture shows Operator beside: lamp 17, bench 67, terminal 45, barrier 78, fountain 155, planter 168, crate 186, rack 118, rubble 178; their scale must be native and visually believable

## Visual acceptance

Capture Lower Quarter Arrival, Direct Collapse, Arcade, Market, Basin, Wrong Street, Answers Court, Station Approach; West Gate Entry/Pressure Pit/Closure Chamber; Station IX Intake/West Records/Sync Plant/East Records/Answer Chamber.

Reject the pass if it still reads as large empty tiled fields with a few isolated lamps/benches. The point of this pass is to use the already-approved native kit as environmental composition.

## Documentation drift

Update active Lower Quarter/Station IX docs to state:
- physical Meridian props are native extracted sprites, not 32px atlas cells
- floor/wall atlases remain 32px tiling presentation
- exact authored native placements live in `lower_quarter_native_prop_placements.json`
- source semantic inventory lives in `meridian_civic_props_native.semantic.json`
- collision is separately authored and never inferred from prop pixels

If CURRENT_STATE or the second-pass task packet still implies the 512 prop atlas is production authority for physical props, correct it.

## Completion report

Report:
- 17 runtime families created/updated
- family canvases used
- number of variants ingested per family
- exact placement counts per level
- unique source IDs used
- semantic family coverage
- excluded review-only entries
- collision footprints enabled/disabled and why
- validation results
- screenshot review
- docs drift fixed
- scoped git status
- commit SHA

Do not push.
