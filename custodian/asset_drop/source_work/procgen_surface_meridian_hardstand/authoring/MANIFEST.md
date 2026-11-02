# CUSTODIAN Meridian Hardstand Macro Pack V1

This package contains the **exact 10 generated Meridian hardstand sources** plus a
normalization pass suitable for CUSTODIAN's native-32px, scale-1 procgen presentation system.

## Package identity

- Family: `procgen_surface_meridian_hardstand`
- Asset family schema: `custodian.asset_family.v2`
- Kind: `backdrop`
- Runtime domain: `tiles/procgen_macro/runtime/meridian_hardstand`
- Placement domain: `SURFACE`
- Depth band: `GROUND`
- Native world scale: `1.0`
- Runtime texture scaling: **none**
- Runtime filtering: **nearest**
- Auto-mirroring: **off**
- Runtime collision/navigation from art: **forbidden**

## Pixel contract

Every normalized image is aligned to the CUSTODIAN 32px semantic grid:

- `1024×1024` = `32×32` procgen cells.
- `1024×448` = `32×14` procgen cells.
- `pivot_px = (0,0)`.
- Sprite realization must remain:
  - `centered = false`
  - `offset = -pivot_px`, therefore `(0,0)` for V1
  - `position = Vector2(origin_cell) * Vector2(32,32)`
  - `scale = Vector2.ONE`
  - `texture_filter = NEAREST`
  - `flip_h = false`

A normalized image pixel therefore maps directly to one world pixel. A 32×32 pixel
block maps directly to one semantic procgen cell.

## Normalization performed

1. Preserve the exact generated source in `source_work`.
2. Treat alpha `>=16` as meaningful visual content for crop measurement.
3. Add a 6-source-pixel safety margin.
4. Expand the crop rectangle to the target aspect ratio. **No anisotropic stretching.**
5. Downsample with premultiplied-alpha Lanczos.
6. Snap alpha `<=7` to `0` and alpha `>=248` to `255`; preserve all intermediate alpha.
7. No rotation, mirroring, recoloring, repainting, or generative modification.

Exact source bboxes, crop rectangles, hashes, and normalized content bboxes are in
`manifest.json`.

## Assets

| # | State | Canvas | Grid | Overlay cells | Reveal probes | Weight | Use |
|---:|---|---:|---:|---:|---:|---:|---|
| 1 | `meridian_hardstand_plaza_irregular_01` | 1024×1024 | 32×32 | 982 | 8 | 10 | Large general-purpose civic/industrial plaza macro |
| 2 | `meridian_hardstand_service_plaza_01` | 1024×1024 | 32×32 | 954 | 8 | 7 | Industrial service plaza / landing court |
| 3 | `meridian_hardstand_corner_01` | 1024×1024 | 32×32 | 1003 | 8 | 8 | Hardstand corner / boundary-breaking composition |
| 4 | `meridian_hardstand_service_strip_01` | 1024×448 | 32×14 | 448 | 8 | 9 | Linear industrial service strip / apron edge |
| 5 | `meridian_hardstand_maintenance_hatch_01` | 1024×1024 | 32×32 | 954 | 8 | 6 | Maintenance/service pad with central hatch |
| 6 | `meridian_hardstand_landing_pad_square_01` | 1024×1024 | 32×32 | 985 | 8 | 4 | Large square landing/service pad |
| 7 | `meridian_hardstand_landing_pad_octagonal_01` | 1024×1024 | 32×32 | 888 | 8 | 2 | Rare hero octagonal industrial landing pad |
| 8 | `meridian_hardstand_grate_service_01` | 1024×1024 | 32×32 | 976 | 8 | 5 | Dense service/grate hardstand around infrastructure |
| 9 | `meridian_hardstand_ruined_transition_01` | 1024×1024 | 32×32 | 880 | 8 | 8 | Ruined constructed-to-natural transition |
| 10 | `meridian_ruined_roadway_01` | 1024×1024 | 32×32 | 926 | 8 | 10 | Large ruined-roadway macro |

## Explicit procgen use

### Region extraction

Add material-backed connected regions from `_surface_material_by_cell`:

- `hardened_civic` -> `hardened_civic_floor`
- `hardened_industrial` -> `hardened_industrial_floor`
- `ruined_road` -> `ruined_road_floor`

Additionally derive `hardstand_natural_boundary` from constructed material cells with
a 4-neighbor in `natural_soft`, `natural_rock`, or `wet_ground`.

These region kinds are presentation regions only. They do not change gameplay semantics.

### Candidate validation

For every hardstand macro candidate:

1. All explicit `walkable_overlay_cells` must be inside map bounds.
2. All must already be existing walkable floor.
3. All must reject protected, required, reserved, and ingress-clearance claims.
4. Intact hardstand states must match their `required_surface_materials`.
5. `meridian_ruined_roadway_01` must fit `ruined_road`.
6. `meridian_hardstand_ruined_transition_01` must anchor on
   `hardstand_natural_boundary`.
7. Never derive gameplay collision or walkability from texture alpha.
8. Never rotate or mirror these images at runtime.

The profile JSON files under `profile_recommendations/` contain explicit per-cell authoring
arrays. The current macro placer uses the **first semantic cell as its local core position**,
so each `walkable_overlay_cells` array deliberately puts `anchor_cell_local` first.

### Mask policy

The mask arrays are an **offline authoring aid**, not runtime image analysis. They were
created once from normalized visible coverage and conservatively expanded one 4-neighbor cell.
Commit them as explicit profile data. Runtime must never recalculate them from PNG alpha.

V1 intentionally uses no `solid_mask_cells`. The art remains presentation-only walkable
hardstand. If a curb/perimeter is later judged gameplay-blocking, add solid mask cells only
where existing terrain is already `wall`, `blocked`, `ledge`, or `drop`. Do not add collision
because the picture looks raised.

### Streaming

Use each profile's 8 distributed `reveal_probe_cells`. A macro remains hidden until all probes
are painted/revealed. This avoids a 1024px composition appearing while only its center is loaded.

### Dressing clearance

- Intact plazas/pads/service compositions: `claims_dressing_clearance = true`.
- Ruined transition and ruined roadway: `false`, so natural encroachment may remain.

### Cadence / budget

These assets are large. Recommended:
- no more than **2 Meridian hardstand macro stamps per generated map**;
- hero pads (`landing_pad_square`, `landing_pad_octagonal`, `maintenance_hatch`,
  `grate_service`) no more than **1 each**;
- do not let the family consume the existing Rocky Upland SURFACE allowance.

Preferred planner policy: add a family sub-cap for
`procgen_surface_meridian_hardstand = 2`, and only raise total SURFACE capacity enough to
preserve the existing Rocky Upland capacity.

## Repo handoff

### Source work

`custodian/asset_drop/source_work/procgen_surface_meridian_hardstand/`

These are the exact generated masters, renamed semantically with `_source.png`.

### V2 inbox

`custodian/asset_drop/inbox/procgen_surface_meridian_hardstand/`

These are the normalized production-ready images.

### Family contract target

`custodian/content/metadata/assets/families/procgen_surface_meridian_hardstand.asset.json`

A recommended contract is included at the package root as
`procgen_surface_meridian_hardstand.asset.json`.

### Expected runtime

`custodian/content/tiles/procgen_macro/runtime/meridian_hardstand/`

Asset Pipeline V2 owns the final runtime copy/naming.

## Important live-system relationship

This pack is **not** a replacement for the existing 32px
`meridian_hardened_floor` base/transition/detail atlases.

The intended stack is:

1. `SurfaceMaterialOverlay` paints continuous 32px hardstand underfoot.
2. These large macro textures add authored plazas, pads, strips, roadway remnants, and
   ruined transitions.
3. Gameplay authority remains the existing floor/wall/traversal/navigation data.

