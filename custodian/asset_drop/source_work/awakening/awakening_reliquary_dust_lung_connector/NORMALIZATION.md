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

## Full composition source — 2026-09-26

The newly approved root master `connector_a.png` (1374×1145 RGB) is preserved
separately as `full_plate_source.png`; it is not treated as the old A state.
Its Dust Lung threshold, eastward hall, and Reliquary landing/run are cropped
and registered as one 832×384 plate by
`custodian/tools/assets/compose_awakening_connector_full_plate.py`. See
`README.md` for the exact source pixel-edge crop boxes and target rectangles.
Lanczos resizing uses one uniform scale per crop. The source has an opaque dark
field, so the normalizer retains dark architectural pixels inside each crop and
sets only canvas beyond the three locked plate regions to true alpha. Asset V2
publishes the `full_plate` state; historical A/B/C source and runtime files are
kept as provenance but are no longer scene presentation.
