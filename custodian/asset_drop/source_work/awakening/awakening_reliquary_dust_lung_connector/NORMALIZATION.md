# Reliquary to Dust Lung connector intake

Source masters are immutable copies of the three repository-root PNGs.

| State | Source dimensions | Source alpha | Runtime dimensions | Normalization |
|---|---:|---|---:|---|
| `connector_a` | 1122×1402 | RGB, opaque | 128×160 | Lanczos resize to target canvas |
| `connector_b` | 2172×724 | RGB, opaque | 704×128 | Lanczos resize to 704×235 at preserved aspect ratio, then centered vertical crop to 704×128 |
| `connector_c` | 1448×1086 | RGBA, transparency present | 128×96 | Lanczos resize to target canvas, preserving alpha |

The normalized outputs are in the matching Asset V2 inbox. The B source aspect
ratio differs from its locked placement rectangle, so the centered crop retains
the passage proportions while removing excess vertical canvas. All three
placements continue to use the unchanged Layout rectangles.

## Connector A replacement — 2026-09-25

The approved replacement source is preserved as
`connector_a_source_v2_20260925.png`; the original `connector_a_source.png`
remains unchanged. The source is 1254×1254 RGBA with transparency. It was
resized uniformly with Lanczos to 128×128, then centered vertically on a
transparent 128×160 RGBA canvas (16px transparent top and bottom). No crop,
stretch, or alpha flattening was applied. The final inbox image remains the
family's `connector_a` state and canonical runtime path.

## Rejected first full-plate composition — 2026-09-26

The newly approved root master `connector_a.png` (1374×1145 RGB) is preserved
separately as `full_plate_source.png`; it is not treated as the old A state.
Its earlier 832×384 composition was rejected during visual review because it
cleared architecture outside three traversal rectangles, leaving floating floor
strips. That version is retired from the runtime catalog and retained only in
its ingest archive.

## Corrected architectural underlay — 2026-09-26

The approved flattened RGB source master remains unchanged. The compositor now
uses the original floor crops only as registration anchors and extracts expanded
architectural surroundings with authored silhouette masks, uniform Lanczos
scales, and no luminance key. The output is a 1024×576 transparent RGBA
`full_plate_underlay`, centered at world `(352, -2464)`; locked traversal lands
at local `(96,96)`, `(160,192)`, and `(800,320)` without changing Layout.

The source has no alpha channel or independently authored layers: corridor
lighting, floor shadows, wall bases, and tall structures are flattened together.
Separating only true foreground occluders would require arbitrary pixel cuts and
would split baked shadows/lighting, so a foreground state is intentionally
unbound rather than fabricated. Direct runtime captures, not this note, govern
visual acceptance.
