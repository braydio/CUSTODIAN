# Carrow Yard perimeter: camera-registered 3D walkway modules

Planning chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad5eb5a-598c-83ea-b982-531d4ff5418f
Workstream: `carrow-yard-volumetric-perimeter` · proposed branch `agent/carrow-yard-volumetric-perimeter`

## Scope

Inspect current live `main`, repository AGENTS, `design/01_systems/ISOMETRIC_2_5D_PRESENTATION_CONTRACT.md`, `design/03_world/locations/CARROW_YARD.md`, applicable Carrow V2 docs, and current Asset Pipeline V2 tooling before acting. Treat this full package as immutable donor/art reference; do not infer runtime authority from PNG alpha or GLB geometry.

Implement the smallest coherent render/asset slice with one geometry/camera owner. Art identifiers: `carrow_yard_perimeter_walls_v1` states `wall_walkway_ew`, `wall_walkway_ns`, `wall_walkway_corner`. Source candidates are at:

```
custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/wall_walkway_ew_source.png
custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/wall_walkway_ns_source.png
custodian/asset_drop/source_work/carrow_yard/carrow_yard_perimeter_walls_v1/wall_walkway_corner_source.png
```

Before runtime intake, use the meshes in `reference/geometry_proof/*.glb` as shared projection reference, with camera 60° elevation/18° yaw, 16x6-tile straight footprints, a four-cell (128px) *clear* rooftop traversal area, flush open ends (no terminating pier), identical wall/parapet elevation/thickness, and real 90° L turn. Do **not** copy these preliminary numbers over any already-authoritative live runtime geometry without checking collisions and user visual approval. The rendered geometry proof uses 1024×768 (EW), 768×1024 (NS), 1024×1024 (corner) canvases, one frame each, RGBA, no ground, no detached shadows, no background. These are geometry renders and cannot substitute for finished reference-quality textures.

## Focused tasks and acceptance

1. Confirm original seven Carrow perimeter sources and any prior family manifest, preserve them without reinjection or duplicate family creation. Reconcile or keep deferred the prior six-piece plan.
2. Validate one shared orthographic camera and world-anchor transform in the actual `Camera2D` environment, comparing the Operator at native 32px game scale. The blockout `18°/60°` angle is a proposed visual bake, not a physical Camera2D rotation requirement.
3. Reproject/finish the detailed source appearance onto the fixed geometry, preserve exact end cross-section and walkable top, and export independent RGBA E-W, N-S and corner sprites. No background, detached ground shadow, or inpainted matte; verify RGB halos at alpha transitions.
4. Define exact (x,y) 32px grid footprint, overlap/pivot, 4-tile rooftop corridor mask, outer wall collision, and corner joining masks. Test all orientations and E-W→corner→N-S seams at native scale with screenshots; no doubling piers or parapets at joins.
5. After visual approval, register the new/updated live `custodian/content/metadata/assets/families/carrow_yard_perimeter_walls_v1.asset.json` `world_prop` contract and populate `custodian/asset_drop/inbox/carrow_yard_perimeter_walls_v1/` as pipeline-normalized source. Use live CLI `custodian/tools/assets/asset.py --help` for command spellings, then plan/status/doctor and focused relevant smokes.
6. Treat *functional* elevated traversal as a separate explicit implementation packet, if approved. Don't invent 3D runtime collision, free Z movement or a second navigation authority in this art-intake task.
7. Replace the superseded planning URL in active Carrow authoring materials when touching them, leaving immutable archived evidence alone, and reconcile any stale statement that the previous six missing states are the only acceptable art plan.

## Non-goals

No conversion from `Camera2D` to `Camera3D`, no implicit collision from pixels, no large procgen rewrite, no asset-drop runtime references, no automatic art approval, no changes to current Carrow ingress/egress routing.

Report only files changed, exact selected geometry/anchors, rendered seam evidence, artifact hashes, pipeline/test status, and any deferred elevated-traversal work.
