# Operator 2.5D Canonical Visual Contract Report

Generated deterministically by `custodian/tools/operator/art_agent/canonical_contract.py`.

## Identity
- Approved source: `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/OPERATOR_DESIGN_REFERENCE_480.png`
- Source SHA-256: `37e080b8dda825dcfe048439e12f0ad4a66c70b33393d3296cd550761e1b0621`
- Source geometry: 3840x480 RGBA, eight 480x480 cells
- Direction order: N, NE, E, SE, S, SW, W, NW
- Packet deviation: the packet recorded a 2048x256 attachment (`2d5de16d...5323`); the user confirmed the 3840x480 repository-root file as the approved lock.
- Profile registry: `operator_art_profile.v3`, active `operator_2_5d_128` (**provisional**), legacy `legacy_96` (accepted) retained unchanged
- Effective profile hash (`operator_2_5d_128`): `4d1ceabce5f9e81e0a28aa3c88344e6d74a9e3e5b2c6b7d73c521a8e3351ef75`
- Provisional 128 frame: center x = 64, support-foot baseline row = 111, candidate ground rail = 112
- Provisional shared scale (candidate A): 1/5; candidate B (9/40) is in the A/B artifacts; translation is integer-only per direction

## Status
| Item | State |
|---|---|
| visual design | locked |
| camera projection | locked |
| profile 128 | provisional |
| root floor | pending human calibration |
| shared body scale | pending ab approval |
| universal 128 envelope | pending proof |
| final normalized hash | pending cleanup certification |

Root/floor: y=111 is the lowest support-toe baseline of this normalization, not a proven projected_world_root. Median foot-contact midpoint y = 107.45; this is evidence, not a definition of root_y. See `root_model` in the design reference JSON and `operator_2_5d_registration_overlay.png`.

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
- Tolerances are provisional until the profile is accepted.
- Hard: frame size, alpha contract (binary, no clipping), per-frame scale (> 3% ratio spread across baseline frames), profile identity.
- Structural (warn): apparent height +/-2.0px, support contact +/-2.0px, hip x +/-2.0px, silhouette area +/-8%, limb ratios per-segment (see design reference JSON).
- Art-direction (warn): palette tolerances {'mean_lightness': 0.02, 'mean_chroma': 0.01, 'gold_median_lightness': 0.032, 'gold_median_hue_deg': 4.0}.

## Rotational continuity
Largest apparent-height step: NE -> E (0.0267). Reported only; no art is warped.

## Human-authority-only
- numeric camera pitch (not derivable from flattened pixels; the turnaround is projection authority)
- subjective visor/gold highlight taste
- occluded-landmark placement below confidence 0.6
- projected_world_root / shadow_origin row (candidates only)
- canonical shared body scale (A/B)
- sign-off on the crisp reduction of the approved render

Low-confidence (< 0.6) segments used as evidence only: 49 segment records (see `anatomy.segments[*].reliable`).

## Evidence
- `operator_2_5d_reference_turnaround.png`, `operator_2_5d_landmark_overlay.png`
- `operator_2_5d_measurement_summary.json`, `operator_2_5d_palette_summary.json`
- Full data: `custodian/content/data/operator/authoring/operator_2_5d_design_reference.json`

## Calibration evidence (pending human decisions; nothing below is accepted)

### Root / floor
Foot-contact midpoint y per direction: N 108.4, NE 105.8, E 111.6, SE 106.6, S 108.3, SW 105.6, W 111.4, NW 106.0; median 107.45.
y=111 is the lowest support-toe baseline, not a proven projected_world_root; the median midpoint is evidence and does not by itself define root_y.
Each direction persists `hip_center`, `left_foot_contact`, `right_foot_contact`, `projected_world_root` (candidate), `shadow_origin` (candidate) separately (`root_model`).
See `operator_2_5d_registration_overlay.png` (rails 106/107/108 vs the current 111/112).

### Scale A/B (same 128 canvas, same provisional root model, one scale per candidate)
| Cand | Scale | Body height px | In previous runtime range 84-88 | Min margin | Directions hash |
|---|---|---|---|---|---|
| A | 1/5 (0.2000) | 75-77 (median 76.0) | False | 16 | `2fda7abceacaf4e6` |
| B | 9/40 (0.2250) | 83-87 (median 85.0) | True | 16 | `0b66bc4fb67a1881` |

See `operator_2_5d_scale_ab_comparison.png` and `operator_2_5d_scale_ab_summary.json`. The human chooses the canonical body scale.

### 128 action body-envelope (projection from current runtime art; not a proof)
Legacy neutral body height 71.0 px; factors A 1.070, B 1.197.
| Class | Sheets measured | Projected body verdict (root 111) | Weapon/FX/cape sides overflowing 128 |
|---|---|---|---|
| deepest_dodge_crouch | 20 | A: body_fits_projected / B: body_fits_projected | A: fits / B: left, right |
| fast_chain_body_extension | 40 | A: body_fits_projected / B: body_fits_projected | A: fits / B: left, right |
| block_hit_reaction | 10 | A: body_fits_projected / B: body_fits_projected | A: fits / B: fits |
| raised_overhead_melee | 6 | A: body_fits_projected / B: body_fits_projected | A: fits / B: fits |
| longest_1h_body_reach | 12 | A: body_fits_projected / B: body_fits_projected | A: left, right / B: left, right |
| ranged_aim | 11 | A: body_fits_projected / B: body_fits_projected | A: fits / B: fits |
| large_hit_react | 5 | A: body_fits_projected / B: body_fits_projected | A: fits / B: fits |
| downed_death_extent | 3 | A: body_fits_projected / B: body_fits_projected | A: fits / B: fits |
Body layers use the split lower/upper modules when present (full_body can have the held weapon baked in). 'Up' includes airborne frames. Weapon/FX/cape overflow is reported separately in `operator_2_5d_action_envelope.json` (`presentation_worst`) and must use its own presentation envelope; the body is never shrunk to fit.

### Pixel cleanup certification
Status: **zero_change** (applied: False). Pixels flagged by the earlier narrower 30-100 deg gold band (6 px across ne,e,sw,w,nw at hue 101-104 deg, bright yellow specular highlights) were inspected: they are in-family gold speculars, so the family band is now 25-110 deg. No colour was edited.
Final normalized hash: pending: certified per candidate above; the final hash is set only after the human chooses the scale and root.
