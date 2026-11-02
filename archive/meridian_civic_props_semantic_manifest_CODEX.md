# Meridian Civic Props Native Semantic Manifest — Codex Integration

## Authority

Source master:

`custodian/asset_drop/source_work/lower_quarter_region/meridian_civic_props_atlas__master.png`

Extraction inventory:

`custodian/asset_drop/source_work/meridian_civic_props/native_extract/`

Semantic manifest to add:

`custodian/content/metadata/assets/meridian_civic_props_native.semantic.json`

This manifest classifies all **224** native extracted sprites. Every extracted ID 001–224 is covered exactly once.

## Non-negotiable scale rule

The old `meridian_civic_props_atlas_512.png` physical-prop path is retired.

A 32×32 authored cell is a **placement/grid unit**, not a prop canvas. Native extracted dimensions are preserved.

- Physical prop: use source PNG at `scale = Vector2.ONE` unless a reviewed semantic override says otherwise.
- Floor overlay: use native size, centered on its intended floor position.
- Tall props may extend above several authored cells.
- Wide props may span several authored cells.
- Never draw a native physical prop via `draw_texture_rect_region(... Vector2(32,32))`.
- Never derive gameplay collision from alpha.

The Operator's production presentation is approximately 96 px tall; this is a review reference, not a normalization target.

## Runtime families

The 80 fine-grained semantic groups in the JSON collapse into these manageable runtime families:

- `meridian_civic_basin` — 11 variants, IDs [154, 155, 156, 157, 158, 159, 160, 164, 165, 166, 167]
- `meridian_civic_bench` — 4 variants, IDs [65, 66, 67, 68]
- `meridian_civic_container` — 5 variants, IDs [193, 194, 195, 196, 197]
- `meridian_civic_crate` — 8 variants, IDs [185, 186, 187, 188, 189, 190, 191, 202]
- `meridian_civic_debris` — 35 variants, IDs [176, 177, 178, 179, 180, 181, 182, 183, 184, 198, 199, 200, 201, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224]
- `meridian_civic_floor_hardware` — 39 variants, IDs [88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 105, 109, 110, 111, 122, 123, 124, 125, 126, 127, 130, 131, 133, 134, 135, 136, 137, 138, 139, 140, 143, 144, 145, 146, 147, 148, 151, 152, 153]
- `meridian_civic_industrial_module` — 23 variants, IDs [102, 103, 104, 106, 107, 108, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 128, 129, 132, 141, 142, 149, 150]
- `meridian_civic_lighting` — 16 variants, IDs [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]
- `meridian_civic_planter` — 11 variants, IDs [161, 162, 163, 168, 169, 170, 171, 172, 173, 174, 175]
- `meridian_civic_security` — 4 variants, IDs [61, 62, 63, 64]
- `meridian_civic_signage` — 13 variants, IDs [33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 48]
- `meridian_civic_structure` — 16 variants, IDs [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
- `meridian_civic_terminal` — 3 variants, IDs [45, 46, 47]
- `meridian_civic_traffic_control` — 17 variants, IDs [71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 100]
- `meridian_civic_utility` — 12 variants, IDs [49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60]
- `meridian_civic_waste` — 3 variants, IDs [69, 70, 192]
- `meridian_civic_worksite` — 4 variants, IDs [87, 98, 99, 101]

## Required implementation shape

1. Keep `native_extract/sprites/` as immutable source-work output.
2. Copy the JSON manifest into:
   `custodian/content/metadata/assets/meridian_civic_props_native.semantic.json`
3. Do **not** create 224 independent family contracts.
4. Build/extend a generic native-prop presentation layer that resolves:
   `runtime_family + variant_key -> native source texture + metadata`.
5. If Asset V2 requires runtime-owned files, ingest variants grouped by the `runtime_family` field. Preserve each PNG's native dimensions.
6. Placement metadata must consume:
   - `anchor_mode`
   - `native_size`
   - `y_sort`
   - `role`
   - `collision_profile`
7. `collision_profile` is only a design hint. Authored topology remains collision/nav authority.
8. Entries with `review_required=true` are **not** production-approved as-is. IDs 177, 201, and 212 are compound extractions and should be split or explicitly accepted before use.
9. `detail_only` micro-debris stays optional and collisionless.
10. Remove physical-prop usage of the old 32×32 civic props atlas from `MeridianCivicArtPresenter`. The old atlas may remain only for true tile-scale/legacy detail until fully retired.

## High-value Lower Quarter usage

- Lighting: IDs 017–032.
- Wayfinding/signage: 033–048.
- Utility/workplace equipment: 049–064.
- Benches and mundane civic dressing: 065–070.
- Barriers/worksite control: 071–087.
- Floor drains/hatches: 088–097.
- Industrial/service hardware: 098–153.
- Civic basin/fountains: 154–160 and 164–167.
- Planters: 161–163 and 168–175.
- Rubble/debris: 176–184 and 198–224.
- Crates/containers: 185–197.

## Placement acceptance

At gameplay camera scale:
- lamps must read as full-height civic lamp posts beside the Operator;
- benches must read as sit-able furniture rather than one-tile boxes;
- signs/terminals must preserve their source proportions;
- large barriers, planters, fountains, crates and rubble must occupy plausible multi-cell visual footprints;
- floor overlays remain under the Operator and do not Y-sort like standing props;
- wall-mounted cameras do not sit on the floor;
- compound/review-only entries are absent until resolved.

## Validation Codex should add

Add a focused native-prop smoke covering:
- JSON parses;
- exactly 224 entries;
- IDs are unique and contiguous 1..224;
- every `source_file` exists;
- actual PNG dimensions equal `crop_size`;
- no entry has runtime scale normalization to 32×32;
- every entry maps to one runtime family;
- floor overlays use `collision_profile=none` or explicit topology-required handling;
- no `collision_is_authoritative=true`;
- review-required entries cannot be spawned by production placement helpers;
- representative lamp, bench, fountain, planter, cabinet, grate, crate and rubble variants retain native dimensions.

Also add a visual scale-review fixture with the Operator beside:
- one standard lamp,
- one amber lamp,
- one bench,
- one utility cabinet,
- one fountain,
- one planter,
- one large barrier,
- one cargo crate.

Do not accept the pass until those objects read plausibly in world scale.
