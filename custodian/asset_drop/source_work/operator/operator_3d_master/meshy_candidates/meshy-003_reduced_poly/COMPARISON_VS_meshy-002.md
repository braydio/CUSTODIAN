# meshy-003_reduced_poly vs frozen meshy-002_textured (not approved, no selection)

Same pipeline, same contract (45 deg, 50 px/m, 8 unmirrored dirs, S-fit 85 px, scale 1.10542 for both).

| Metric | meshy-002 | meshy-003 | Change |
|---|---|---|---|
| Triangles | 1,251,670 | 10,367 | -99.17% (120.7x fewer) |
| Vertices (imported) | 660,202 | 16,241 | -97.54% |
| Normalised dims m (X,Y,Z) | 0.9157, 0.5224, 2.1032 | 0.9122, 0.5210, 2.1019 | -0.4%, -0.3%, -0.06% |
| UV layers | UVMap | UVMap | same |
| Textures | base 4096, 2048(MR), normal 4096 (as imported) | base 4096, MR 4096, normal 4096 | all present; 003 MR is 4096 |
| Boundary / non-manifold / degenerate | 0 / 27 / 12 | 16 / 11 / 0 | 003 has 16 open edges |
| Mean S-fit IoU vs canon (triage only) | 0.668 | 0.666 | -0.002 |
| Height range px | 85-91 | 85-91 | same |

Per-direction render difference, 002 vs 003 (alpha>127):
- Silhouette IoU: 128px 0.985-0.994; 512px 0.989-0.992.
- Mean RGB difference where both opaque: 128px 4.4-5.1 /255; 512px 2.2-2.7 /255.

Visual notes (judgment is the user's): hood, shoulders, armor plates, gold trim, tabard and boots are all present in 003. At 512px / closeups 003 shows slightly more angular silhouettes (hood rim, pauldron edges) and faint faceting in wireframe-visible low-poly planes; no obvious texture seams or lost features in the 8-direction sheets. Material wiring (base/MR/normal) is intact.

Caveat: the first 003 run exposed a stale caption in the geometry proof ("1.25M-tri" hardcoded); fixed to use the actual triangle count and 003 was re-run. Render config unchanged.
