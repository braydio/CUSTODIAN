# Operator 2.5D Canonical Visual Contract Report

Generated deterministically by `custodian/tools/operator/art_agent/canonical_contract.py`.

## Identity
- Approved source: `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/OPERATOR_DESIGN_REFERENCE_480.png`
- Source SHA-256: `37e080b8dda825dcfe048439e12f0ad4a66c70b33393d3296cd550761e1b0621`
- Source geometry: 3840x480 RGBA, eight 480x480 cells
- Direction order: N, NE, E, SE, S, SW, W, NW
- Packet deviation: the packet recorded a 2048x256 attachment (`2d5de16d...5323`); the user confirmed the 3840x480 repository-root file as the approved lock.
- Profile registry: `operator_art_profile.v3`, active `operator_2_5d_128`, legacy `legacy_96` retained unchanged
- Effective profile hash (`operator_2_5d_128`): `4aaf2bf51ce2c14261c03cf47e5720a5a0954999ac47a2c7d579a2c22de728b5`
- Canonical 128 frame: center x = 64, anchor = [64, 111], ground_y = 112
- Shared scale: 1/5 (one scale for all eight directions); translation is integer-only per direction

## Per-direction summary (normalized 128)
| Dir | Height | Width | Support y | Hip x offset | Head-hip px | Mean OKLab L | Visor | Fringe px |
|---|---|---|---|---|---|---|---|---|
| N | 77 | 43 | 111 | 0.4 | 28.0 | 0.286 | False | 0 |
| NE | 75 | 36 | 111 | 0.4 | 29.04 | 0.286 | True | 0 |
| E | 77 | 28 | 111 | 0.0 | 31.06 | 0.289 | True | 0 |
| SE | 77 | 37 | 111 | 0.0 | 28.0 | 0.296 | True | 0 |
| S | 75 | 42 | 111 | 0.4 | 25.4 | 0.299 | True | 0 |
| SW | 76 | 34 | 111 | 0.0 | 27.45 | 0.295 | True | 0 |
| W | 76 | 27 | 111 | 0.0 | 30.02 | 0.282 | True | 0 |
| NW | 75 | 37 | 111 | 0.0 | 29.02 | 0.283 | True | 0 |

## Tolerances (derived, not invented)
- Basis: landmark/silhouette noise = 1.0px at 128 (one crisp pixel); structural tolerance = 2.0 x noise; palette tolerance = observed cross-direction spread of the approved reference with a floor
- Hard: frame size, alpha contract (binary, no clipping), per-frame scale (> 3% ratio spread across baseline frames), profile identity.
- Structural (warn): apparent height +/-2.0px, support contact +/-2.0px, hip x +/-2.0px, silhouette area +/-8%, limb ratios per-segment (see design reference JSON).
- Art-direction (warn): palette tolerances {'mean_lightness': 0.02, 'mean_chroma': 0.01, 'gold_median_lightness': 0.042, 'gold_median_hue_deg': 4.0}.

## Rotational continuity
Largest apparent-height step: NE -> E (0.0267). Reported only; no art is warped.

## Human-authority-only
- numeric camera pitch (not derivable from flattened pixels; the turnaround is projection authority)
- subjective visor/gold highlight taste
- occluded-landmark placement below confidence 0.6
- sign-off on the 5:1 crisp reduction of the approved render

Low-confidence (< 0.6) segments used as evidence only: 49 segment records (see `anatomy.segments[*].reliable`).

## Evidence
- `operator_2_5d_reference_turnaround.png`, `operator_2_5d_landmark_overlay.png`
- `operator_2_5d_measurement_summary.json`, `operator_2_5d_palette_summary.json`
- Full data: `custodian/content/data/operator/authoring/operator_2_5d_design_reference.json`
