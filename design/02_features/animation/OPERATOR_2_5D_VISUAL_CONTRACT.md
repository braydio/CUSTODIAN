# Operator 2.5D Visual Contract

## Status

Hard visual/registration authority for all future 2.5D Operator animation
authoring. Approved by the user on 2026-10-06 as a `user_approved_visual_lock`.
Measurements and tolerances are generated, not hand-typed:
`custodian/content/data/operator/authoring/operator_2_5d_design_reference.json`.

## Identity and direction order

The approved turnaround is `OPERATOR_DESIGN_REFERENCE_480.png`: 3840x480 RGBA,
eight 480x480 cells in exactly this order: **N, NE, E, SE, S, SW, W, NW**.
SHA-256 `37e080b8dda825dcfe048439e12f0ad4a66c70b33393d3296cd550761e1b0621`.
The preserved master and its manifest live in
`custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/`
(never recompress, threshold or edit it). The filename's `480` is the measured
cell size. The task packet's recorded 2048x256 attachment was a mistaken
reference; the user confirmed this file as the lock.

## Projection authority

The approved turnaround itself is the projection authority. No numeric camera
pitch is derived from flattened pixels and none may be asserted. The camera is
the existing elevated three-quarter language; exactly eight directions are
authored; no direction collapses into a side-on camera. `near`/`far` describe
screen projection, not anatomical side.

## Source versus 128 reference

- **Source** (480 cells): measurement evidence and the only art authority.
- **128 reference** (`custodian/content/sprites/operator/reference/operator_2_5d/`):
  derived authoring ghosts. They are not gameplay animation states and do not
  replace any runtime Operator art in this slice.
- Derivation: one shared 1/5 crisp area reduction for all eight directions
  (body about 75-77 px tall inside the 128 frame, close to the legacy ~70 px
  gameplay body), binary alpha, integer translation only. Never rotate, shear,
  or scale a direction independently to equalize apparent height.

## Frame and canvas strategy

- Canonical authoring frame: **128x128**, profile `operator_2_5d_128`.
- Legacy **96x96** stays valid as profile `legacy_96`; old Source Sessions and
  plans do not silently migrate (plans carry `profile_id` + effective hash).
- `operator_art_profile.v3` is a registry: `active_authoring_profile` drives new
  authoring; v1/v2 files remain readable as `legacy_96`.

## Root and floor semantics

- Center X = 64, from semantic `hip_center` (never alpha-bbox center).
- Support contact (sole of the lowest `toe_near/toe_far`) = row **111**; anchor
  `[64, 111]`; ground rail `y=112`. Alpha bottom is a fallback, never authority.
- Never recenter a frame around its alpha bbox, weapon, FX, cloak tip or
  extended fist. Weapons/FX may trigger clipping refusal; they may never shrink
  the body.

## Invariant geometry versus pose freedom

Hard invariants: frame/profile size, one animation-wide scale, no per-frame
rescale, projection/direction, body and costume topology, root/ground system,
profile and reference hash, no clipping, binary alpha.

Pose freedom: crouch, recoil, lean, anticipation, follow-through, airborne pose,
dodge extension and cloak swing may move joints. Joint position may change;
anatomy and scale may not silently change.

## Direction-relative measurement

Foreshortening is direction-specific: compare N to N, E to E. Never force
screen-space segment lengths equal across bearings. Segment tolerances come from
landmark noise (one crisp pixel at 128, times two); see the JSON. Rotational
continuity (N->NE->...->NW->N) is reported only; art is never warped.

## Material, palette and brightness hierarchy

```text
visor/core focal highlight
> selected gold/plate speculars
> gold trim
> graphite plate highlights
> cloth mids
> deep outline/shadow
```

The source is a rendered image, not a tiny palette. Classification uses OKLab
lightness/chroma/hue bands. Gross palette/material deviation is reported as
`ART_DIRECTION_WARN`; small lighting variation stays warning-level.

## Visor behavior

Faceless hood always (no skin/eyes/nose/mouth). Visor is strongest S, partial
SE/SW, narrow/profile E/W, minimal NE/NW, absent/near-absent N.

## Outline and alpha rules

True binary alpha, crisp output. Do not enforce a uniform sticker outline;
require continuous silhouette separation and coherent internal value edges.
Report detached 1-2 px islands, semitransparent fringe, off-family hue
contaminants and 2+ px outline thickening as evidence.

## Weapon and FX clipping rules

Weapons and FX are layered over the body; they trigger `CLIPPING` refusal at the
128 edge and are excluded from body-scale measurement.

## Mirroring policy

No automatic mirroring is part of this contract. E/W and NE/NW/SE/SW are
separately approved art; mirroring one into the other requires a human decision
because the approved cells are not mirror-symmetric (stance, cloak, lighting).

## QA severity classes

`HARD_FAIL` (wrong frame/profile, per-frame scale, clipping, non-binary alpha,
profile hash mismatch) · `STRUCTURAL_WARN` (support-root, hip-center, limb
ratio, apparent-height/area drift) · `ART_DIRECTION_WARN` (gold/visor
lightness/hue/chroma drift) · `INFO` (intentional pose motion). Services:
`ArtAgentService.canonical_reference`, `canonical_qa`; CLI `canonical-reference`,
`canonical-qa`; MCP `operator_art_canonical_reference`, `operator_art_canonical_qa`.

## Aseprite guides

`operator_anchor_guides.lua` renders locked, non-exporting layers
`__ART_GUIDE_OPERATOR_FLOOR`, `_CENTER`, `_BODY` and `_CANONICAL_REFERENCE`
(low-opacity direction ghost) for the 128 profile (`direction=<code>|grid`) and
the legacy single ruler for 96. All use the `__ART_GUIDE_` prefix, so clean
renders and publishing exclude them.

## Human-review triggers

Any change that alters appearance rather than integer placement or metadata;
numeric camera pitch; landmarks below confidence 0.6; palette/visor taste calls;
mirroring decisions; any request to change the approved source or its 5:1
reduction.

## Regeneration

`python3 custodian/tools/operator/art_agent/canonical_contract.py build --master <approved png>`
is deterministic; `verify` checks the preserved master. Landmark annotations are
agent visual annotations (`operator_2_5d_landmark_annotations.json`) and are the
one human-correctable input.
