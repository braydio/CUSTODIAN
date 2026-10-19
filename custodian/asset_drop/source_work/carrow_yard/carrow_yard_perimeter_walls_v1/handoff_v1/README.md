# CUSTODIAN — Carrow Yard Walkway Perimeter / Projection-Locked Handoff V1

**Status:** Camera/geometry prototype complete; detailed art candidates isolated; **NOT YET Asset Pipeline V2-verified or runtime-ready**.

This package contains two complementary outputs:

1. High-detail source candidates from one coherent concept sheet (`source_work/`) with real RGBA backgrounds removed. These retain the agreed Carrow appearance but do **not** pass a pixel-perfect connection test yet.
2. Exact shared geometry and orthographic camera reference (`reference/geometry_proof/`), including independently loadable GLB models and 2D transparent render proofs. Those lock module geometry and allow E-W/N-S/corner to be re-rendered without camera drift. VTK procedural textures are placeholder/donor material, not a finished art bake.

## Source work

`custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/`

Source files: `wall_walkway_ew_source.png`, `wall_walkway_ns_source.png`, `wall_walkway_corner_source.png`.

## Runtime intake gate

Proposed after review: `custodian/asset_drop/inbox/carrow_yard_perimeter_walls_v1/wall_walkway_ew.png` etc. Inbox is deliberately empty, because the production-state size and pixel-seam geometry require final alignment, frame-safe export and live runtime comparison. Do not ingest these unapproved source candidates automatically.

Family contract intended path: `custodian/content/metadata/assets/families/carrow_yard_perimeter_walls_v1.asset.json`. The family currently must be checked for existence/ownership first; live Asset V2 is authoritative.

## Geometry lock

Orthographic 60° elevation / 18° yaw, 32px game grid; four-tile/128px clear elevated walking area; six-tile total cross-section; 16 tile standard straight runs. Render proof pixel density 45px/tile is preview density, **not a 32px game-to-screen registration guarantee**. All 3 models derive from identical `wall_rect` construction, but shared corner profiles still need explicit raster overlap/seam QA.

To regenerate geometry proofs (requires `vtk`, `Pillow`, `numpy`, `trimesh`):

```bash
python tools/render_camera_locked_geometry.py
```

Environment overrides: `CARROW_SOURCE_PNG=...` and `CARROW_OUTPUT_DIR=...`.

Review `MANIFEST.json`, `CODEX_IMPLEMENTATION.md`, `CAMERA_GEOMETRY_PREVIEW.jpg`, and render outputs. Preserve all originals. Do not reuse preview JPEG as art.

## Known remaining issues

- Human approval of 60°/18° compared with actual Operator/game camera.
- Detailed art must be UV-reprojected/painted onto shared mesh surfaces without changing geometry.
- Both straight ends must be open/flush and genuinely stitchable under the runtime pivot, not merely alike visually.
- Elevated walkway is an authored second navigation surface, not produced by PNG alpha or 3D GLB alone.
- Ground shadows and floors are not baked into the proposed wall assets.
- Project doc `design/05_levels/CARROW_YARD_INTERIOR_SCALE_AND_LAYOUT_V2.md` still references superseded planning chat `/6acc3bfd...`; replace in active authoring docs when working on the live branch, keeping archive provenance intact.
