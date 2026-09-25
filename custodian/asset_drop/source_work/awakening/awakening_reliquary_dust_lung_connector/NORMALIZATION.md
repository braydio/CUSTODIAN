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
