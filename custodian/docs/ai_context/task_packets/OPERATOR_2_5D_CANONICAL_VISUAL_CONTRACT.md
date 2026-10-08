# OPERATOR 2.5D CANONICAL VISUAL CONTRACT

- Packet schema: `custodian.task_packet.v2`
- Workstream: `operator-2-5d-canonical-visual-contract`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `operator-2-5d-animation-viability-audit`
- Claim gate: `claim automatically only after the viability audit closes and releases operator-art-agent; visual identity/directional design are already user-locked and must not be reopened; stop only for byte mismatch, unresolved semantic-root contradiction, or a real specialized-pipeline conflict`
- Locks: `operator-art-agent, operator-source-normalization, operator-aseprite-tooling`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, visual, asset-pipeline, workflow`
- Paired review workstream: `review-operator-2-5d-canonical-visual-contract`
- Reviewed main: `90e2ac01e3b91809bd5e1b52fe6ada13e388c808`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Goal: Harden the user's exact 8-direction Operator design lock as the single deterministic visual authority and harden the supplied 8-direction relaxed idle as the first canonical `operator_2_5d_128` production animation; preserve both source byte streams, reconcile their 256px design-to-128px production relationship into the accepted registration/profile authority, make Aseprite/Workbench/Art Agent consume the lock, and prevent future animation authoring from drifting in anatomy, projection, palette, scale, registration, or directional identity.
- Completion boundary: Consume the two exact Dropbox implementation inputs through the current specialized Operator authoring pipeline; preserve immutable source-work copies; register the 2048x256 design sheet as the accepted directional design lock; register the 1920x1024 relaxed idle as the first canonical 8-direction x 15-frame full-body animation family; emit reference/profile/measurement provenance with exact hashes; migrate the art-profile authority so legacy 96 and canonical 128 coexist; make Aseprite/Workbench consume the canonical lock; add deterministic anti-drift QA; update active art/design docs. Do not cut production runtime selectors over to the new generation in this slice.
- Current measured state:
  - The user has explicitly locked the supplied design sheet as the permanent visual source for future Operator animation authoring.
  - Dropbox design-lock input: `/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png`; 2048x256 RGBA; eight horizontal 256x256 cells; direction order `N, NE, E, SE, S, SW, W, NW`; true alpha; SHA-256 `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`.
  - Dropbox first-animation input: `/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png`; 1920x1024 RGBA; 15 frame columns x 8 direction rows; 128x128 cells; row order `N, NE, E, SE, S, SW, W, NW`; true alpha; SHA-256 `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`.
  - Semantic identity of that animation is `operator_2_5d_128 / unarmed / posture / idle_relaxed_01 / full_body`. It is the first and currently only fully authored production animation the user considers aligned with the locked volumetric realistic top-down 2.5D target.
  - Existing pre-migration live art is legacy/migration donor material unless separately proven against this lock; it must not become canonical merely because it is runtime-reachable.
  - Live `operator_art_profile.json` still preserves legacy 96 authoring. Active documentation and donor artifacts contain stale references to older design-reference geometry/hashes and must be reconciled to these exact inputs.
- Evidence: exact Dropbox inputs `/CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png` and `/CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png`; user decision in this authoring chat; `custodian/content/data/operator/authoring/operator_art_profile.json`; `operator_landmark_schema.json`; `custodian/tools/operator/art_agent/registration_profile.py`; `custodian/tools/aseprite/operator_anchor_guides.lua`; `custodian/tools/operator/README.md`; `design/02_features/animation/OPERATOR_ART_STYLE_BIBLE.md`; archived `OPERATOR_ART_REGISTRATION_PROFILE.md` and donor canonical-contract artifacts only as historical evidence.
- Task-specific authority: the exact two hashes/Dropbox inputs above plus the user's explicit lock decision; current Operator registration/profile tooling; current specialized Operator authoring pipeline. The design sheet is a specialized Operator reference authority and the idle sheet is a specialized Operator animation family. Do not create a parallel generic Asset V2 authority when the live specialized Operator pipeline owns the concept.
- Work surface: `custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/`; `custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/`; current specialized Operator inbox/source-session path resolved from live `operator_asset_schema.py`; Operator authoring profile/reference metadata; registration profile/QA/overlay services; Aseprite guide integration; style bible; focused validation; task index/roadmap.
- Preserve: existing canonical/runtime Operator PNGs and SpriteFrames; all current 96x96 production assets; animation timings; gameplay selectors; weapon sockets; old Source Sessions; existing normalization plans; the exact design-lock bytes `41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b`; the exact first-animation bytes `d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3`. Never resize, repaint, re-render, background-remove, or otherwise mutate either supplied source master in place.
- Non-goals: no new animation generation; no redesign of the supplied idle; no production runtime cutover; no automatic limb warping; no per-frame scale correction; no 16-direction production requirement; no fabricated camera angle; no melee/ranged behavior changes; no `operator.gd` decomposition; no Forum implementation.
- Acceptance: the two Dropbox inputs are copied into immutable Operator source-work with hashes unchanged; the 2048x256 sheet is recorded as the accepted 8-direction design lock; the 1920x1024 sheet is recorded as the first canonical `unarmed/posture/idle_relaxed_01/full_body` family with 8 directions x 15 frames x 128x128 cells; exact direction order is proven; timing is preserved from authoritative metadata if available and never invented from pixels; accepted profile/reference hashes are emitted; Aseprite/Workbench guides consume the lock; legacy 96 remains usable; drift fixtures are caught; active docs no longer cite donor geometry/hashes as current authority; no production runtime selector is changed.
- Validation: new focused canonical-visual-contract smoke + existing registration-profile focused coverage + Aseprite clean-render guide-leak check + `git diff --check`. No broad gameplay/Godot suites unless runtime files are unexpectedly touched.
- Task overrides: `none`
- Deferred: actual animation regeneration, production rollout packets, and Forum refresh.

## Identity

```text
workstream: operator-2-5d-canonical-visual-contract
branch: agent/operator-2-5d-canonical-visual-contract
closing summary: OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_CLAUDE_SUMMARY.md
```

## LOCKED INPUT AUTHORITY — 2026-10-07 REFRESH

These inputs supersede older donor/reference geometry or attachment hashes as **active** authority. Historical reports may retain old values as history, but active tooling/docs must not treat them as current truth.

### Design lock

```text
Dropbox: /CUSTODIAN/implementation_inputs/operator_2_5d_design_lock_v1_8dir_1f_256.png
Repository source-work target: custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/operator_2_5d_design_lock_v1_source.png
Specialized family / authority id: operator_2_5d_design_reference
Sheet: 2048x256 RGBA
Layout: 8x1
Cell: 256x256
Direction order: N, NE, E, SE, S, SW, W, NW
SHA-256: 41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b
Role: immutable design / anatomy / projection / material / directional source of truth
```

### First canonical animation

```text
Dropbox: /CUSTODIAN/implementation_inputs/operator_2_5d_unarmed_posture_idle_relaxed_01_full_body_v1_8dir_15f_128.png
Repository source-work target: custodian/asset_drop/source_work/operator/operator_2_5d_first_animation/unarmed_posture_idle_relaxed_01_full_body_v1_source.png
Specialized family id: operator_2_5d_unarmed_posture_idle_relaxed_01
Art generation: operator_2_5d_128
Semantic identity: unarmed/posture/idle_relaxed_01/full_body
Sheet: 1920x1024 RGBA
Layout: 15 columns x 8 direction rows
Cell: 128x128
Frames per direction: 15
Direction order: N, NE, E, SE, S, SW, W, NW
Loop: true
FPS/timing: resolve from authoritative authored metadata/session if present; do not infer from the PNG
SHA-256: d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3
Role: immutable first target-aligned production animation and registration/temporal proof
```

### Specialized Operator intake contract

Use the current live specialized Operator schema/tooling first. Raw supplied files remain immutable source masters. If live tooling expects inbox staging, use semantic filenames under the existing Operator 2.5D inbox namespace and let `operator_asset_schema.py` derive canonical authoring/runtime destinations. Do **not** hand-author a competing runtime filename or generic Asset V2 family. The design lock is reference authority; the relaxed idle is animation-family authority.
## PRE-LOCK CALIBRATION GATE

Do **not** freeze the canonical 128 registration merely from the 2048x256 design-reference cell bounds. Two distinct artifacts exist and have different jobs:

### High-resolution design authority

The user-approved final design sheet supplied in the authoring chat measures:

```text
2048 x 256 RGBA
8 x 256x256 cells
order: N, NE, E, SE, S, SW, W, NW
sha256: 41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b
```

This file owns anatomy, armor/cloak topology, projection, palette/material language and directional identity. It is **not** itself proof of runtime centering/floor registration.

### First canonical production-animation proof

The old single-frame 128 resize candidate is no longer the strongest production-scale evidence. The user has supplied a fully authored 8-direction, 15-frame relaxed-idle sheet and explicitly identified it as the actual target-aligned production animation.

```text
1920 x 1024 RGBA
15 columns x 8 direction rows
128 x 128 cells
semantic identity: unarmed/posture/idle_relaxed_01/full_body
order: N, NE, E, SE, S, SW, W, NW
sha256: d4a6a5f5ff5fe64c3ad0f44a3f31b5d1ca2c276afe7a4c52d00337e7aaf175f3
```

Use this animation to validate the accepted 128 profile's real body scale, center/root semantics, temporal registration, loop stability and directional continuity. Do not independently scale directions or frames. Do not derive FPS from image pixels. Any older 1024x128 single-frame resize may remain donor/calibration evidence only and cannot override this authored family.
### Candidate canonical root/floor

The accepted legacy profile uses `anchor_y=84`, `ground_y=85`; the viability audit found normal legacy sprite baselines at roughly y=84. Preserve that semantic relationship in the new profile.

Candidate new registration:

```text
frame: 128x128
center_x: 64
support/body baseline: y=106
root anchor: [64, 106]
ground_y: 107
bottom safety margin below ground: 20px
```

If bottommost opaque support contact is used as the initial normalization evidence, the candidate whole-sprite integer Y translations are:

```text
N   +0
NE  +1
E   -1
SE  +0
S   +2
SW  +1
W   +0
NW  +3
```

These translations are **calibration candidates, not permission to finalize blindly**.

Before final profile write:

1. landmark semantic `hip_center` and both visible/inferable toe/support contacts on all 8 directions;
2. verify that x=64 represents the projected body/root axis from semantic landmarks, not alpha-bbox centering;
3. verify y=106 against support-contact landmarks and the existing anchor-vs-ground semantics;
4. create one deterministic 8-direction calibration overlay showing cell bounds, x=64, candidate anchor y=106, ground y=107, support contacts, hip centers and applied integer translations;
5. publish that single overlay through the visual-review handoff and **pause for human/ChatGPT approval before the v3 profile/reference is declared accepted**;
6. if the user changes anchor/floor/body scale, update the profile measurements and this report from that decision. Do not reinterpret the visual design itself.

No direction may be independently rescaled to make its feet/bbox match. Whole-sprite integer translation is the only allowed pre-lock geometric adjustment after the one shared crisp body scale is established.

If the exact 1024x128 candidate is available locally, preserve it as additional source-work evidence under a name such as `OPERATOR_DESIGN_REFERENCE_128.png` and verify the SHA above. If it is not available, deterministically reproduce the 128 candidate from the approved source through the existing pixelart/normalization tooling and require the calibration overlay/human gate before accepting the result.

## AAA TECHNICAL-ART PRE-FREEZE ADDENDUM

This addendum supersedes any earlier implication that the lowest opaque pixel should be normalized to one common Y. The approved 2.5D art is now visually lockable; registration remains a semantic technical-art calibration.

### Audit disposition

Treat the current approved 8-direction character design as:

- **visual identity / anatomy / armor / cloak:** LOCK;
- **camera / projection:** LOCK;
- **runtime neutral body scale:** PASS;
- **frame center X:** LOCK at `64` for the 128 profile;
- **root/floor Y:** PROVISIONAL;
- **128x128 as a universal body-animation canvas:** PROVISIONAL until action-envelope proof;
- **mass animation production:** HOLD until the semantic-root and action-envelope gates below pass.

Measured neutral 128 reference evidence remains:

```text
cell: 128x128
apparent body height: 84-88 px
top alpha row: y=20 for all current neutral reference cells
bottom alpha row: y=103..107 depending on direction
binary alpha only
detached alpha islands: none
```

Do not enlarge the neutral body merely to fill the frame.

### Critical floor/root correction

**Do not normalize direction registration by alpha bottom.**

In a fixed elevated 2.5D projection, two feet can both contact the same physical ground plane while appearing at different screen-space Y coordinates. Therefore:

- lowest opaque Y is clipping/silhouette evidence only;
- equal alpha bottoms are not a registration invariant;
- equal head-top Y is not a registration invariant;
- the earlier candidate whole-sprite Y shifts derived from bottommost opaque pixels are diagnostic only and must not be applied merely to equalize bottoms.

Before accepting the canonical 128 registration, landmark for every direction:

```text
hip_center
left_foot_contact
right_foot_contact
projected_world_root
shadow_origin
```

Reuse existing near/far toe landmarks where they map cleanly, but add an explicit projected-root/shadow-origin concept if the current schema cannot represent the distinction without ambiguity.

The intended model is:

```text
world/root authority: fixed gameplay point
projected root: fixed screen-space registration point for the profile
foot contacts: direction-specific positions around that root
shadow origin: grounded presentation point
```

Candidate registration remains:

```text
frame: 128x128
center_x: 64
candidate root: [64, 106]
candidate ground_y: 107
```

but Y=106/107 is **not accepted merely because it is near the current lowest pixels**.

Prove or revise it from the semantic landmarks.

### Required human calibration proof

Before writing the new 128 profile as accepted, generate one deterministic eight-direction technical overlay showing, for every cell:

- 128x128 cell boundary;
- x=64 root axis;
- candidate/final projected root;
- ground reference;
- hip center;
- left/right foot contacts;
- shadow origin;
- alpha bbox;
- no geometric scaling difference between directions.

Publish that single overlay and pause at the existing human calibration gate.

The human decision is about root/floor/scale registration only. Do not reopen the approved character design/camera unless the overlay exposes an actual contradiction.

### 128 universal action-envelope proof

The neutral turnaround proves that the standing Operator fits comfortably inside 128x128. It does **not** by itself prove that 128x128 is a universal canvas for every future body animation.

Before declaring the 128 profile universal for new Operator body art, prove a bounded maximum-action envelope using representative worst extents from current/planned production semantics:

- deepest dodge/crouch;
- maximum fast-chain body extension;
- widest block-hit/reaction;
- raised/overhead melee pose;
- longest 1H attack body reach;
- ranged aim extension;
- large hit-reaction recoil;
- downed/death body extremity where relevant.

The proof may use existing art, canonicalized temporary poses, or measured legacy/reference envelopes. It does not require authoring a finished new animation family.

Acceptance:

- body anatomy fits the 128 body canvas with a deliberate safety margin;
- no body scale reduction is used to make an extreme pose fit;
- root remains stable under pose motion;
- intentional root-driving motion is represented explicitly rather than recentering the frame;
- if weapon/FX extents exceed the body canvas, solve that with the appropriate weapon/FX presentation envelope or layer contract, **never by shrinking the Operator body**.

If the body itself cannot fit a representative production pose safely at 128, stop and return that evidence for human/ChatGPT profile-size review before mass production.

### Runtime-pixel cleanup gate

The reviewed 128 candidate has correct binary alpha and connected silhouettes but contains a small number of embedded cool/green/blue palette contaminants.

Cleanup is allowed only on the normalized 128 authoring reference, not the immutable high-resolution design source.

Allowed cleanup:

- replace isolated non-warm contaminant pixels with locally appropriate graphite or warm-gold values;
- preserve perceptual brightness hierarchy;
- preserve exact alpha mask;
- preserve dimensions, silhouette, root, floor, scale, pose and topology.

Required proof:

- before/after hashes;
- exact changed-pixel list;
- alpha-mask equality;
- identical connected-component topology;
- 4x or greater diff/marked preview for human inspection.

Do not perform broad palette reduction or recolor.

The immutable high-resolution design-source hash remains the visual provenance authority even if the normalized 128 reference receives approved pixel cleanup and therefore has its own new reference hash.

### Final pre-freeze rule

The 128 profile may become accepted only after all three conditions are true:

1. semantic root/floor overlay is human-approved;
2. 128 body action-envelope proof passes or a revised frame size is human-approved;
3. normalized 128 pixel cleanup is reviewed and its final hash is recorded.

Until then, the implementation may build measurement/report/tooling support but must keep the new profile explicitly provisional.

## 1. Preserve the approved source exactly

Expected local source:

```text
~/Downloads/OPERATOR_DESIGN_REFERENCE_480.png
```

Verify before copying:

```text
dimensions: 2048x256
layout: 8x1
cell: 256x256
order: N, NE, E, SE, S, SW, W, NW
sha256: 41782240f4b595fc3dffead7709b8493746f9f2d502c25cab69e432fb50d725b
```

If absent, stop. If hash/dimensions differ, report actual values and stop for user confirmation. Do not fetch/regenerate/substitute.

Preserve exact bytes at:

```text
custodian/asset_drop/source_work/operator/operator_2_5d_design_reference/
    OPERATOR_DESIGN_REFERENCE_480.png
    operator_2_5d_design_reference_manifest.json
```

Manifest records filename, SHA-256, bytes, dimensions, cell geometry, order, approval date, authoring chat and provenance `user_approved_visual_lock`.

Do not recompress/threshold/edit the master.

## 2. Split immutable measurement cells

Exact-boundary split only:

```text
source_cells/
    n_source.png
    ne_source.png
    e_source.png
    se_source.png
    s_source.png
    sw_source.png
    w_source.png
    nw_source.png
```

Each remains 256x256 and must reconstruct the master pixel-for-pixel. Record every cell hash.

## 3. Introduce canonical 128 without breaking legacy 96

The future Operator frame/canvas is 128x128 with approximately the current gameplay body scale inside the larger canvas. Existing 96 art remains valid during migration.

Upgrade the profile authority to a backward-readable registry, recommended `custodian.operator_art_profile.v3`:

```json
{
  "schema": "custodian.operator_art_profile.v3",
  "active_authoring_profile": "operator_2_5d_128",
  "profiles": {
    "legacy_96": { "...existing v2 registration unchanged..." },
    "operator_2_5d_128": { "...new canonical contract..." }
  },
  "canonical_visual_reference": {
    "path": "...OPERATOR_DESIGN_REFERENCE_480.png",
    "sha256": "...",
    "measurements_path": "...operator_2_5d_design_reference.json"
  }
}
```

Exact private shape may follow live code, but invariants are mandatory:

- v1/v2 remain readable;
- legacy 96 remains selectable;
- old Source Sessions/plans do not silently migrate;
- new authoring defaults to `operator_2_5d_128`;
- profile identity/hash is carried through normalization/review receipts;
- consumers do not retype geometry constants.

Update `registration_profile.py` to select an explicit profile instead of hard-requiring one top-level 96 registration.

## 4. Derive 128 registration from the approved pixels

Create the canonical 128 directional reference with existing crisp Operator conversion/normalization, using one shared body scale across all directions. The design target is the approved body at roughly the former 96px gameplay scale inside a roomier 128px cell, not a body stretched to 128.

Rules:

- X authority = semantic `hip_center`, not alpha-bbox center.
- Y authority = semantic support contact from `toe_near/toe_far`; alpha bottom is fallback evidence only.
- One shared scale for all eight directions.
- Direction-specific adjustment is integer translation only.
- Never independently scale directions to equalize apparent height.
- Never rotate/shear.
- Preserve crisp output and true alpha.
- Frame center X is 64.
- Derive final 128 anchor Y / ground Y from approved support contacts; do not guess them in advance.

Recommended durable normalized references:

```text
custodian/content/sprites/operator/reference/operator_2_5d/
    operator_2_5d_rotation_lock_128.png
    directions/n.png
    directions/ne.png
    directions/e.png
    directions/se.png
    directions/s.png
    directions/sw.png
    directions/w.png
    directions/nw.png
```

These are authoring references/ghosts, not gameplay animation states.

## 5. Landmark every direction

Create:

```text
custodian/content/data/operator/authoring/operator_2_5d_design_reference.json
```

For each direction record source-256 and normalized-128 coordinates for every visible/inferable existing semantic landmark:

```text
hood_top
head_center
shoulder_near / shoulder_far
elbow_near / elbow_far
hand_near / hand_far
hip_center / hip_near / hip_far
knee_near / knee_far
ankle_near / ankle_far
toe_near / toe_far
cloak_tip_near / cloak_tip_far
```

Every point has confidence and provenance. Do not fabricate occluded points at high confidence.

## 6. Deterministic geometry/proportion measurements

Persist per direction:

### Registration and silhouette
- alpha bbox and centroid;
- silhouette area and occupancy ratio;
- top/bottom/left/right margins;
- support-contact y;
- hip-center x offset;
- apparent height/width;
- widths at standard vertical percentages (20/35/50/65/80%);
- reproducible perimeter/edge density if stable.

### Anatomy
Using landmarks:
- hood-top to head-center;
- head-center to hip-center;
- shoulder span;
- hip span;
- shoulder to elbow;
- elbow to hand;
- hip to knee;
- knee to ankle;
- ankle to toe;
- torso length;
- apparent leg length;
- cloak-tip displacement from hip/root.

Store raw px and ratios normalized to head-center-to-hip and/or apparent height.

Foreshortening is direction-specific. Future N compares to canonical N, E to E, etc. Never force screen-space segment lengths to be equal across bearings.

### Rotational continuity
Report N -> NE -> E -> SE -> S -> SW -> W -> NW -> N discontinuities in body height, head scale, shoulder span, hip placement, cloak mass and overall scale. Report only; do not warp art.

## 7. Deterministic color / brightness / material measurements

Do not pretend the rendered source is a tiny exact palette.

Record:
- source and normalized alpha histograms;
- dominant sRGB clusters;
- perceptual lightness statistics (OKLab or equivalent);
- luminance p05/p50/p95/p99;
- chroma/saturation distribution;
- darkest silhouette/outline band;
- graphite/cloth dark-mid-light bands;
- gold dark-mid-highlight bands;
- visor core/glow band where present;
- highlight occupancy percentages;
- gold-to-graphite contrast;
- visor-to-gold and visor-to-body contrast;
- per-direction lightness/chroma deltas.

Preserve this hierarchy:

```text
visor/core focal highlight
> selected gold/plate speculars
> gold trim
> graphite plate highlights
> cloth mids
> deep outline/shadow
```

Gross material/palette deviation can be structural QA; small action-lighting variation remains warning-level until separately hardened.

## 8. Outline / alpha / artifact measurements

For normalized directions report:

- alpha-perimeter pixels;
- dark-outline perimeter coverage;
- outline lightness distribution;
- outlier hue/color contaminants;
- detached 1-2 px alpha islands;
- semitransparent fringe pixels after crisp normalization;
- excessive 2+ px outline thickening as warning evidence.

Do not enforce a uniform sticker outline. Require continuous silhouette separation and coherent internal value edges.

## 9. Lock visual identity/topology

Create human-readable hard authority for:

- faceless hood: never expose skin/eyes/nose/mouth;
- hood crown readable under the fixed elevated camera;
- visor strongest S, partial SE/SW, narrow/profile E/W, minimal NE/NW, absent/near-absent N;
- lean athletic proportions;
- angular shoulder plates;
- graphite/black plate + cloth;
- restrained antique-gold/amber trim;
- layered split cloak/tabard;
- fixed belt-ring language;
- stable shoulder/forearm/knee/greave plate segmentation;
- one screen-space lighting language;
- exactly eight authored directions;
- no direction collapses into a side-on camera.

Do not invent a numeric pitch from flattened pixels. The approved turnaround is projection authority.

## 10. Create the design authority

Create:

```text
design/02_features/animation/OPERATOR_2_5D_VISUAL_CONTRACT.md
```

Document:
- identity and direction order;
- projection authority;
- source-vs-128 reference distinction;
- frame/canvas strategy;
- root/floor semantics;
- invariant geometry vs pose-authoring freedom;
- direction-relative measurement rules;
- material/palette/brightness hierarchy;
- visor behavior;
- outline/alpha rules;
- weapon/FX clipping rules;
- mirroring policy;
- human-review triggers.

Update `OPERATOR_ART_STYLE_BIBLE.md` to point here and remove stale claims that no approved canonical sample exists.

## 11. Animation anti-drift rules

Hard:
- profile/frame size;
- one animation-wide global scale;
- no per-frame rescale;
- canonical direction/projection;
- body/costume topology;
- root/ground coordinate system;
- canonical profile/reference hash;
- no clipping;
- alpha/layer contract.

Direction-relative structural checks for neutral/locomotion baseline frames:
- head scale;
- head-to-hip ratio;
- shoulder span;
- hip span;
- limb ratios;
- apparent body height;
- hip-center offset;
- support-foot registration.

Derive tolerances from the approved reference and reproducible existing noise; do not invent arbitrary percentages when measurements can supply them.

Intentional pose motion remains free: crouch, recoil, lean, anticipation, follow-through, airborne pose, dodge extension and cloak swing may move joints. Joint position may change; anatomy/scale cannot silently change.

## 12. Centering / floor / weapon rules

Canonical 128:
- center x = 64;
- hip/root centering for neutral references;
- support-foot contact for floor alignment;
- alpha bbox only for clipping/sanity.

Never recenter a frame around alpha bbox, weapon, FX, cloak tip or extended fist.

Weapons/FX may trigger clipping refusal; they may never shrink the body.

## 13. Aseprite canonical ghost guides

Extend the existing Operator guide script. A selected direction should expose locked non-exporting guides equivalent to:

```text
__ART_GUIDE_OPERATOR_FLOOR
__ART_GUIDE_OPERATOR_CENTER
__ART_GUIDE_OPERATOR_BODY
__ART_GUIDE_OPERATOR_CANONICAL_REFERENCE
```

The canonical-reference guide is the approved normalized direction ghost at low opacity.

Requirements:
- load through profile/reference authority;
- direction-correct;
- locked and toggleable;
- never included in clean render/publish;
- idempotent replacement;
- legacy-96 and canonical-128 modes;
- no permanent duplication of guide pixels when on-demand rendering is cleaner.

## 14. Workbench / Art Agent QA

Shared services should expose/report:
- effective canonical profile;
- canonical direction reference;
- landmark/registration overlay;
- geometry/proportion report;
- palette/brightness report;
- silhouette/outline report.

Classify findings:

```text
HARD_FAIL
STRUCTURAL_WARN
ART_DIRECTION_WARN
INFO
```

Examples:
- wrong frame/profile or per-frame scale -> HARD_FAIL;
- support-root or limb-ratio drift -> STRUCTURAL_WARN according to profile;
- gold/visor lightness/hue drift -> ART_DIRECTION_WARN;
- action pose head-y differs from neutral with stable anatomy -> INFO.

No automatic anatomy warping.

## 15. Durable evidence

Create:

```text
reports/operator_presentation/canonical_visual_contract/
    operator_2_5d_reference_turnaround.png
    operator_2_5d_landmark_overlay.png
    operator_2_5d_measurement_summary.json
    operator_2_5d_palette_summary.json
    OPERATOR_2_5D_CANONICAL_VISUAL_CONTRACT_REPORT.md
```

Turnaround shows all 8 normalized directions on the same floor/center guides. Landmark overlay makes anatomy/root placement inspectable.

Report exact source hash, profile hash, final 128 anchor/ground, ordering, hard/advisory tolerances, and any measurement that remains human-authority-only.

## 16. Documentation drift to resolve

Reconcile:
- style bible still says no canonical sample is approved;
- art profile still models a single 96 profile;
- registration parser hard-requires 96;
- 2.5D roadmap does not yet treat this approved body as the art authority.

Do not rewrite historical archived packets.

## 17. Focused validation

Add focused owner, recommended ID `operator_2_5d_canonical_visual_contract`.

Prove:
1. source hash/dimensions;
2. source-cell reconstruction;
3. v1/v2 profile readability;
4. legacy 96 still available;
5. canonical 128 is default for new art;
6. all 8 reference directions exist;
7. exact direction order;
8. landmark names valid;
9. measurement generation deterministic;
10. intentional scale/anchor drift caught;
11. intentional palette/brightness drift reported;
12. guide layers cannot leak through clean render/publish.

Run existing registration-profile focused smoke if present and `git diff --check`. No broad gameplay/Godot suite.

## 18. Completion / handoff

Publish turnaround, landmark overlay and concise report through the visual-review workflow.

If normalization changes appearance rather than integer placement/metadata, stop for human review rather than silently redefining the approved art.

After reviewed landing:
1. recompute the animation-art backlog against this contract;
2. author canonical unarmed locomotion/posture as the first production art tranche;
3. refresh the Forum 2.5D packet only after that art plan is accepted.

## Completion Truth

- Outcome: partial; implementation remains active and the 128px profile is provisional.
- Complete: exact source masters and manifests, byte-exact cell reconstruction, shared-scale crisp 128px reference, deterministic per-direction measurements/palette summary, v3 backward-readable profile registry with stable legacy hash, 128px default for new Workbench animation-creation plans, explicit Art Agent profile selection, Aseprite registration/reference guides, design authority, and focused anti-drift coverage.
- Not complete: semantic root/floor approval; universal body action-envelope proof; reviewed pixel cleanup; specialized canonical-family intake/timing registration; paired post-land review.
- Action-envelope evidence: the deterministic scan contains 446 category-assigned pre-migration full-body proxy frame observations (categories can overlap). Under the explicit +16,+22 legacy-root translation, 46/180 fast-chain frames and 16/47 long one-handed-reach frames exceed the 128px canvas; 71 and 24 frames respectively exceed the 8px safety margin. The largest fast-chain proxy is east `fast_02` frame 4, source alpha bbox `[35,11,136,85]`, translated bbox `[51,33,152,107]`. This legacy material is not canonical 2.5D evidence and does not alone reject 128px. It does keep universal fit unproven. Ranged aim modular union, wide block-hit, and all-direction locked-projection coverage are unmeasured. Human review must decide whether the fast02 frame is a valid maximum-body proxy and whether canvas/pose-root policy needs revision.
- Human review: `/CUSTODIAN/visual_review/operator-2-5d-canonical-visual-contract/20261008T183010Z/REVIEW_MANIFEST.json`, default retention `delete-after-review`.
- Validation: canonical visual-contract smoke, Workbench creation/migration smoke, registration-profile smoke, Art Agent MCP smoke, Aseprite clean-render guide-leak smoke, Python compilation, and `git diff --check` all passed with the proxy evidence update.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: initial registry migration made the legacy plan replay guard reject the new registry file hash; separately, the neutral idle did not prove the universal action envelope, so a source-proxy scan was added and it found fast-chain and long-reach overflow candidates late in implementation.
- Root cause / contributing factors: the converter compared a selected profile hash to the entire v3 registry hash; the packet's neutral-idle evidence did not represent extreme actions; Dropbox review runs are immutable by design.
- Prevention / pipeline improvement: compare explicit profile hashes from the v3 registry while retaining v1/v2 file-hash compatibility; scan representative action classes before treating a neutral animation as canvas proof; publish changed review evidence under a fresh run ID.
- Tooling / docs drift discovered: packet omits the required `Change` field; record retained here for packet-authoring repair before archive. The user-supplied animation PNG has no authoritative FPS/timing metadata.
- Follow-up: `operator-2-5d-canonical-visual-contract`
- What worked: source hashes, geometry, direction order, exact legacy profile hash, and proxy extents are deterministic checks.


## Handoff

- Next workstream: `review-operator-2-5d-canonical-visual-contract`
- Next packet state: `human-required`
- Refresh owner: `chatgpt-user`
- ChatGPT/user planning refresh required: `yes`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Summary backlink: include the exact Authoring chat URL in the closing summary and final Next Handoff
- Refresh reason: `human semantic root/floor decision, action-envelope proxy validity/canvas decision, and normalized-reference cleanup review are required before the canonical profile can be accepted`
- Next action: `review the latest Dropbox handoff in the authoring chat, record exact root/floor and action-envelope decisions, then resume this workstream before paired review`
- Blockers or open questions: `human review of registration, fast02 proxy/canvas implication, and palette cleanup; ranged aim/block-hit/all-direction envelope proof and animation FPS/timing metadata remain unavailable`
