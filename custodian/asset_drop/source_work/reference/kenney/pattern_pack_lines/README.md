# Kenney Pattern Pack Lines Reference Library

This folder preserves third-party source/reference material. It is not runtime
authority and must never be referenced directly by scenes, scripts, or imported
runtime resources.

All 120 PNGs are retained across the four source variants to avoid destructive
preselection. The original PNG bytes are unchanged. Downloaded four-digit names
such as `pattern_0000.png` are mapped by numeric value to canonical three-digit
library names such as `pattern_000.png`; no image conversion or index offset is
applied. `manifest.json` records each original Downloads-relative path and
basename, canonical destination and pattern ID, dimensions, SHA-256, license,
variant, and usage tags. `LICENSE.txt` preserves Kenney's bundled license text.

Only the immediate and future candidate shortlists below have current CUSTODIAN
design classification. Every other pattern remains reference-only.

## Immediate candidates

| Pattern | Preferred source variant | Intended roles |
| --- | --- | --- |
| `pattern_006` | `thin_512` | anti-slip herringbone, service tread, broken catwalk fill |
| `pattern_007` | `thin_512` | machinery grille, louver/register face, technical panel |
| `pattern_008` | `thin_512` | woven service grate, industrial tread, dense maintenance fill |
| `pattern_013` | `thin_512` | truss mesh, gantry lattice, braced screen |
| `pattern_014` | `thin_512` | maintenance plate seams, service-panel subdivision |
| `pattern_017` | `thin_512` | square service grid, hatch matrix, modular floor panel |
| `pattern_022` | `double_thick_512` | structural X-brace, large frame reinforcement |
| `pattern_023` | `thin_512` | diamond guard mesh, catwalk/vent lattice |
| `pattern_027` | `thin_512` | dense guard lattice, grille field, industrial mesh |
| `pattern_028` | `double_thick_512` | broad directional chevron, threshold/service direction band |
| `pattern_029` | `double_thick_512` | repeated directional chevrons, airflow/route band |

## Future candidates

These are retained for later inspection and are not production approvals:

- `pattern_000` — civic slab / four-quadrant registration geometry.
- `pattern_002`, `pattern_003` — elongated cell / structural framework; use cautiously because they can read generic sci-fi.
- `pattern_004` — simple diagonal lattice.
- `pattern_009` — registered square/diamond civic grid; keep separate from brass Authority Inlays.
- `pattern_016` — large quadrant/grid seam.
- `pattern_018`, `pattern_019` — diamond framing / repeated diamond cells.
- `pattern_024` — octagonal structural frame.
- `pattern_026` — sparse diagonal lattice.

Rounded/circular motifs, ornate interlocks, and all other unlisted IDs remain
`reference_only`; preservation alone does not approve them as Awakening
vocabulary.

## Production use

To use a selected motif, copy or derive it into the real owning
`source_work/<area>/<family>/` and `asset_drop/inbox/<family>/` locations,
register the owning family, and use Asset Pipeline V2 normally. Do not create a
family for this entire reference pack. Direct scene/runtime references into
this reference folder are forbidden.
