# Baby Opossum Production Wiring (2026-09-06)

Publishes the approved Baby Opossum source art through Asset Pipeline V2 and wires
every published action into the existing deterministic state machine. No parallel
authority was introduced: behavior stays in `STATE_TABLE`, spawning stays in
`AmbientCritterManager`, rejection stays in `AttackRejection`, publication stays in
`asset.py`.

Design authority: `design/02_features/ambient/BABY_OPOSSUM_RUNTIME.md`.

## Contract reconciliation

- `idle_south` declared `expected_frames: 6`. The contract loader reads the key
  `frames`, so the value was inert, and the approved strip is 4 frames. Changed to
  `"frames": 4`. No frames were duplicated to reach 6.
- `hide_hold` and `play_dead_hold` are single held poses. Changed to
  `"animation": false, "frames": 1`; this also cleared the two blocking plan
  errors ("state requires animation").
- Added body states `groom` and `scratch` (ambient, 8fps, 6 frames).

## Staging audit

The pre-existing inbox staging was part-malformed: 9 of 26 strips had been sliced
on the wrong frame grid, leaving a fragment of the neighbouring pose in each cell
and marching the pose sideways across the strip. Detection thresholds (secondary
blob >= 6% of the main pose, or pose drift >= 22px) sit in a clean gap between the
approved strips (max 4% / 19.5px) and the malformed ones (min 7.5% / 22px) and are
shared by the staging tool and the asset-contract smoke.

Malformed strips were moved to `asset_drop/unresolved/ambient_baby_opossum/` rather
than published or deleted. `source_work/` was not modified.

`groom` and `scratch` were staged from source-work using the scale/offset measured
from `approach_wary__s.png`, which shares their source canvas and camera, so they
land at the same character scale and baseline as their approved siblings.

## Published

22 runtime strips, body layer only, 96x96 RGBA. See the completion report and
`design/02_features/ambient/BABY_OPOSSUM_RUNTIME.md`.

## Deliberately not done

- The `barrel_prop` hide layer. The four source canvases (880x136, 768x162,
  2172x724 x2) render the barrel at 74x61, 90x34, and 88x66 — publishing them would
  visibly resize the barrel between hide states. Deriving the prop from the approved
  body transform was prototyped and registers pixel-exactly, but inherits that scale
  inconsistency, so the pair fails the C2 synchronisation invariant.
- Re-slicing the 9 malformed strips. Their sources have irregular pose spacing with
  tails crossing pose boundaries; correct extraction is per-pose art cleanup, not a
  mechanical regrid, and guessing at it would bake wrong art into runtime authority.

Both are tracked in `REQUIRED_ASSETS.md` with the exact re-export needed.
